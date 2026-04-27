const fs = require("fs");
const path = require("path");
const { Prisma } = require("@prisma/client");

const prisma = require("../../lib/prisma");

const DEFAULT_TYPES = ["POST", "EVENT", "COURSE"];
const VECTOR_TABLES = {
  userProfiles: '"UserProfileML"',
  contentEmbeddings: '"ContentEmbedding"',
};
const PERSONALIZATION_DISABLED_VALUES = new Set(["1", "true", "yes"]);
const EMBEDDING_SOURCES = {
  LEGACY: "legacy-semantic",
  ID_TWO_TOWER: "id-two-tower",
};
const RECOMMENDATION_SOURCE_VALUES = new Set(Object.values(EMBEDDING_SOURCES));
const CHECKPOINT_DIR_BY_SOURCE = {
  [EMBEDDING_SOURCES.LEGACY]: "two_tower_run",
  [EMBEDDING_SOURCES.ID_TWO_TOWER]: "id_two_tower_run",
};
const RERANK_WEIGHTS = {
  personalized: {
    base: 0.7,
    freshness: 0.15,
    popularity: 0.15,
  },
  fallback: {
    base: 0,
    freshness: 0.45,
    popularity: 0.55,
  },
};

function getCheckpointRootCandidates() {
  const envRoot = String(process.env.RECOMMENDATION_CHECKPOINT_ROOT || "").trim();
  const candidates = [
    envRoot,
    path.resolve(__dirname, "../../../ml/two_tower/checkpoints"),
    "/app/ml/two_tower/checkpoints",
    "/app/two_tower/checkpoints",
    "/app/checkpoints",
  ].filter(Boolean);

  return [...new Set(candidates)];
}

function resolveCheckpointMeta(source) {
  const envKey =
    source === EMBEDDING_SOURCES.ID_TWO_TOWER
      ? "RECOMMENDATION_ID_TWO_TOWER_META_PATH"
      : "RECOMMENDATION_LEGACY_META_PATH";
  const envMetaPath = String(process.env[envKey] || "").trim();
  const candidatePaths = [
    envMetaPath,
    ...getCheckpointRootCandidates().map((root) =>
      path.join(root, CHECKPOINT_DIR_BY_SOURCE[source], "meta.json")
    ),
  ].filter(Boolean);

  const uniquePaths = [...new Set(candidatePaths)];
  const resolvedPath =
    uniquePaths.find((candidatePath) => fs.existsSync(candidatePath)) ||
    uniquePaths[0] ||
    null;

  return {
    available: Boolean(resolvedPath && fs.existsSync(resolvedPath)),
    metaPath: resolvedPath,
    checkedPaths: uniquePaths,
  };
}

function clampLimit(limit, fallback = 12, max = 50) {
  const parsed = Number(limit);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return Math.min(parsed, max);
}

function parseVectorText(value) {
  if (!value || typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed.startsWith("[") || !trimmed.endsWith("]")) return null;
  const items = trimmed
    .slice(1, -1)
    .split(",")
    .map((item) => Number(item.trim()))
    .filter((item) => Number.isFinite(item));
  return items.length ? items : null;
}

function averageVectors(vectors) {
  if (!Array.isArray(vectors) || vectors.length === 0) return null;
  const dim = vectors[0]?.length || 0;
  if (!dim) return null;
  const sum = new Array(dim).fill(0);
  let count = 0;
  for (const vec of vectors) {
    if (!Array.isArray(vec) || vec.length !== dim) continue;
    for (let i = 0; i < dim; i += 1) {
      const v = Number(vec[i]);
      sum[i] += Number.isFinite(v) ? v : 0;
    }
    count += 1;
  }
  if (!count) return null;
  return sum.map((v) => v / count);
}

function normalizeVector(vec) {
  if (!Array.isArray(vec) || vec.length === 0) return null;
  let norm = 0;
  for (const v of vec) {
    const n = Number(v);
    if (Number.isFinite(n)) norm += n * n;
  }
  norm = Math.sqrt(norm) || 0;
  if (!norm) return vec;
  return vec.map((v) => Number(v) / norm);
}

function normalizeEmbeddingSource(value) {
  const raw = String(value || "")
    .trim()
    .toLowerCase();
  return RECOMMENDATION_SOURCE_VALUES.has(raw)
    ? raw
    : EMBEDDING_SOURCES.ID_TWO_TOWER;
}

function clamp01(value) {
  if (!Number.isFinite(value)) return 0;
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value;
}

function daysBetween(now, value) {
  if (!value) return null;
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return (now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24);
}

function computeFreshnessSignal(item, now = new Date()) {
  if (!item) return 0;

  if (item.targetType === "EVENT") {
    const eventDate = item.item?.eventDay || item.item?.starts;
    if (!eventDate) return 0;
    const daysUntil = -daysBetween(now, eventDate);
    if (!Number.isFinite(daysUntil)) return 0;
    if (daysUntil < -7) return 0;
    if (daysUntil <= 0) return clamp01(1 - Math.abs(daysUntil) / 7);
    return clamp01(1 - daysUntil / 30);
  }

  const ageDays = daysBetween(
    now,
    item.item?.createdAt || item.item?.updatedAt || item.item?.publishedAt,
  );
  if (!Number.isFinite(ageDays)) return 0;
  if (ageDays <= 0) return 1;
  return clamp01(1 - ageDays / 30);
}

function computePopularitySignal(item) {
  if (!item?.item) return 0;

  if (item.targetType === "POST") {
    const reactionCount = Number(item.item?._count?.postReactions || 0);
    const commentCount = Number(item.item?._count?.comments || 0);
    const favoriteCount = Number(item.item?._count?.favorites || 0);
    const shareCount = Number(item.item?.shareCount || 0);
    return Math.log1p(reactionCount + commentCount + favoriteCount + shareCount * 2);
  }

  if (item.targetType === "EVENT") {
    const registrations = Number(item.item?.registrations || 0);
    const views = Number(item.item?.views || 0);
    return Math.log1p(registrations * 3 + views);
  }

  if (item.targetType === "COURSE") {
    const hasVideo = item.item?.videoId ? 1 : 0;
    const price = Number(item.item?.price || 0);
    return Math.log1p(hasVideo + Math.max(price, 0));
  }

  return 0;
}

function normalizeSignals(values = []) {
  const finite = values.filter((value) => Number.isFinite(value));
  if (!finite.length) return values.map(() => 0);

  const min = Math.min(...finite);
  const max = Math.max(...finite);
  if (min === max) {
    return values.map((value) => (Number.isFinite(value) && value > 0 ? 1 : 0));
  }

  return values.map((value) =>
    Number.isFinite(value) ? clamp01((value - min) / (max - min)) : 0
  );
}

class RecommendationService {
  async getRecommendationsForUser(userId, options = {}) {
    const embeddingSource = this.resolveEmbeddingSourceStatus();
    const activeSource = embeddingSource.active;

    if (this.shouldForceFallback()) {
      return this.buildFallbackResponse(userId, {
        ...options,
        embeddingSource,
      });
    }

    const limit = clampLimit(options.limit);
    const requestedTypes = Array.isArray(options.targetTypes)
      ? options.targetTypes.filter((type) => DEFAULT_TYPES.includes(type))
      : [];
    const targetTypes = requestedTypes.length ? requestedTypes : DEFAULT_TYPES;
    const excludeSeen = options.excludeSeen !== false;

    try {
      const userVector = await this.fetchUserVector(userId, activeSource);

      if (!userVector) {
        return this.buildFallbackResponse(userId, {
          limit,
          targetTypes,
          embeddingSource,
        });
      }

      const scored = await this.fetchScoredContent({
        userId,
        userVector,
        embeddingSource: activeSource,
        targetTypes,
        limit,
        excludeSeen,
      });

      if (!scored.length) {
        return this.buildFallbackResponse(userId, {
          limit,
          targetTypes,
          embeddingSource,
        });
      }

      const hydrated = await this.hydrateRecommendations(scored, userId);

      if (!hydrated.length) {
        return this.buildFallbackResponse(userId, {
          limit,
          targetTypes,
          embeddingSource,
        });
      }

      const reranked = this.rerankRecommendations(hydrated, {
        personalized: true,
      });

      return {
        source: "personalized-reranked",
        embeddingSource: embeddingSource.active,
        userId,
        limit,
        items: reranked.slice(0, limit),
      };
    } catch (error) {
      console.warn(
        "Recommendation pipeline failed. Falling back to non-personalized results:",
        error?.message || error,
      );
      return this.buildFallbackResponse(userId, {
        limit,
        targetTypes,
        embeddingSource,
      });
    }
  }

  // Vector-only ranking (no fallback mixing): user vector -> pgvector cosine search -> hydrate.
  async getVectorRankedRecommendations(userId, options = {}) {
    const embeddingSource = this.resolveEmbeddingSourceStatus();
    const activeSource = embeddingSource.active;

    const limit = clampLimit(options.limit);
    const requestedTypes = Array.isArray(options.targetTypes)
      ? options.targetTypes.filter((type) => DEFAULT_TYPES.includes(type))
      : [];
    const targetTypes = requestedTypes.length ? requestedTypes : DEFAULT_TYPES;
    const excludeSeen = options.excludeSeen !== false;

    const userVector = await this.fetchUserVector(userId, activeSource);
    if (!userVector) {
      return {
        source: "missing-user-embedding",
        embeddingSource: embeddingSource.active,
        userId,
        limit,
        items: [],
      };
    }

    const scored = await this.fetchScoredContent({
      userId,
      userVector,
      embeddingSource: activeSource,
      targetTypes,
      limit,
      excludeSeen,
    });

    const hydrated = await this.hydrateRecommendations(scored, userId);

    return {
      source: "vector-search",
      embeddingSource: embeddingSource.active,
      userId,
      limit,
      items: hydrated.slice(0, limit),
    };
  }

  shouldForceFallback() {
    const raw = String(process.env.DISABLE_PERSONALIZED_RECOMMENDATIONS || "")
      .trim()
      .toLowerCase();
    return PERSONALIZATION_DISABLED_VALUES.has(raw);
  }

  async buildFallbackResponse(userId, options = {}) {
    const limit = clampLimit(options.limit);
    const embeddingSource =
      options.embeddingSource || this.resolveEmbeddingSourceStatus();
    const requestedTypes = Array.isArray(options.targetTypes)
      ? options.targetTypes.filter((type) => DEFAULT_TYPES.includes(type))
      : [];
    const targetTypes = requestedTypes.length ? requestedTypes : DEFAULT_TYPES;
    const fallbackItems = await this.getFallbackRecommendations({
      limit,
      targetTypes,
      viewerId: userId,
    });
    const reranked = this.rerankRecommendations(fallbackItems, {
      personalized: false,
    });

    return {
      source: this.shouldForceFallback() ? "fallback-disabled" : "fallback",
      embeddingSource: embeddingSource.active,
      userId,
      limit,
      items: reranked,
    };
  }

  async getSystemStatus() {
    const embeddingSource = this.resolveEmbeddingSourceStatus();
    const [
      interactionCount,
      userCount,
      usersWithInteractionsRows,
      contentByType,
      userEmbeddingsBySource,
      contentEmbeddingsBySource,
    ] = await Promise.all([
      prisma.userInteraction.count(),
      prisma.user.count({ where: { isDeleted: false } }),
      prisma.userInteraction.groupBy({
        by: ["userId"],
        _count: { _all: true },
      }),
      prisma.contentEmbedding.groupBy({
        by: ["contentType"],
        _count: true,
      }),
      this.countEmbeddingsBySource(VECTOR_TABLES.userProfiles),
      this.countEmbeddingsBySource(VECTOR_TABLES.contentEmbeddings),
    ]);

    const usersWithInteractions = Array.isArray(usersWithInteractionsRows)
      ? usersWithInteractionsRows.length
      : 0;

    const usersWithProfiles = Object.values(userEmbeddingsBySource).reduce(
      (sum, count) => sum + Number(count || 0),
      0,
    );
    const contentEmbeddingCount = contentByType.reduce(
      (sum, row) => sum + Number(row._count || 0),
      0,
    );
    const activeUserEmbeddings = Number(
      userEmbeddingsBySource[embeddingSource.active] || 0,
    );
    const activeContentEmbeddings = Number(
      contentEmbeddingsBySource[embeddingSource.active] || 0,
    );

    const warnings = [];
    if (userCount > 0 && userCount < 100) {
      warnings.push(
        `User count is still small (${userCount} users). Expect sparse personalization; prefer the optimized ranking model (vector search) until more interaction volume arrives.`,
      );
    }

    return {
      generatedAt: new Date().toISOString(),
      embeddingSource,
      dataScale: {
        usersTotal: userCount,
        usersWithInteractions,
      },
      warnings,
      interactions: {
        total: interactionCount,
      },
      embeddings: {
        users: usersWithProfiles,
        usersBySource: userEmbeddingsBySource,
        activeUsers: activeUserEmbeddings,
        content: {
          total: contentEmbeddingCount,
          bySource: contentEmbeddingsBySource,
          activeTotal: activeContentEmbeddings,
          byType: contentByType.reduce((acc, row) => {
            acc[row.contentType] = Number(row._count || 0);
            return acc;
          }, {}),
        },
      },
      recommendationReadiness: {
        personalized:
          activeUserEmbeddings > 0 && activeContentEmbeddings > 0,
        fallback: true,
      },
    };
  }

  resolveEmbeddingSourceStatus() {
    const configured = this.getConfiguredEmbeddingSource();
    const checkpoints = Object.values(EMBEDDING_SOURCES).reduce((acc, source) => {
      acc[source] = resolveCheckpointMeta(source);
      return acc;
    }, {});

    const checkpointAvailable = checkpoints[configured]?.available === true;
    // Serving should not depend on local checkpoint artifacts.
    // In production we often deploy only the embeddings (in DB), not the training outputs.
    const active = configured;

    return {
      configured,
      active,
      fallback: EMBEDDING_SOURCES.LEGACY,
      checkpointAvailable,
      checkpoints,
    };
  }

  getConfiguredEmbeddingSource() {
    const raw = String(process.env.RECOMMENDATION_EMBEDDING_SOURCE || "")
      .trim()
      .toLowerCase();
    return RECOMMENDATION_SOURCE_VALUES.has(raw)
      ? raw
      : EMBEDDING_SOURCES.ID_TWO_TOWER;
  }

  async countEmbeddingsBySource(tableName) {
    try {
      const rows = await prisma.$queryRawUnsafe(
        `SELECT COALESCE("embeddingSource", 'unknown') AS source, COUNT(*)::int AS count
         FROM ${tableName}
         WHERE "embedding" IS NOT NULL
         GROUP BY COALESCE("embeddingSource", 'unknown')`
      );

      return rows.reduce((acc, row) => {
        acc[row.source] = Number(row.count || 0);
        return acc;
      }, {});
    } catch (error) {
      console.warn(
        `Failed to count embeddings by source for ${tableName}:`,
        error?.message || error,
      );
      return {};
    }
  }

  async fetchUserVector(userId, embeddingSource) {
    try {
      const rows = await prisma.$queryRaw`
        SELECT "embedding"::text AS embedding
        FROM "UserProfileML"
        WHERE "userId" = ${userId}
          AND COALESCE("embeddingSource", ${EMBEDDING_SOURCES.LEGACY}) = ${embeddingSource}
        LIMIT 1
      `;

      const existing = parseVectorText(rows?.[0]?.embedding);
      if (existing) return existing;

      const coldStartEnabled =
        String(process.env.RECOMMENDATION_COLD_START || "true")
          .trim()
          .toLowerCase() !== "false";

      if (!coldStartEnabled) return null;

      const generated = await this.buildColdStartUserVector(userId, embeddingSource);
      if (!generated) return null;

      // Persist so future requests don't need to recompute.
      // We use SQL because Prisma schema may lag behind migrations for embeddingSource.
      try {
        await prisma.$executeRaw`
          INSERT INTO "UserProfileML" ("userId", "interests", "skills", "preferredCategories", "embedding", "embeddingSource", "updatedAt")
          VALUES (
            ${userId},
            ARRAY[]::text[],
            ARRAY[]::text[],
            ARRAY[]::text[],
            CAST(${`[${generated.join(",")}]`} AS vector),
            ${embeddingSource},
            NOW()
          )
          ON CONFLICT ("userId") DO UPDATE SET
            "embedding" = EXCLUDED."embedding",
            "embeddingSource" = EXCLUDED."embeddingSource",
            "updatedAt" = NOW()
        `;
      } catch (error) {
        console.warn(
          "Failed to persist cold-start user embedding (continuing with in-memory vector):",
          error?.message || error,
        );
      }

      return generated;
    } catch (error) {
      console.warn(
        "Failed to fetch user recommendation vector. Falling back to non-personalized results:",
        error?.message || error,
      );
      return null;
    }
  }

  async buildColdStartUserVector(userId, embeddingSource) {
    // Cold start strategy without calling external embedding APIs:
    // 1) Use the user's profile interests as a tag filter.
    // 2) Average matching content embeddings (same embeddingSource).
    try {
      const profile = await prisma.userProfile.findUnique({
        where: { userId },
        select: { interests: true },
      });

      const interests = Array.isArray(profile?.interests)
        ? profile.interests.map((v) => String(v || "").trim()).filter(Boolean)
        : [];

      const source = embeddingSource;

      // Prefer content that matches interests (by Post.tags overlap), else fall back to recent posts with embeddings.
      const rows = interests.length
        ? await prisma.$queryRaw`
            SELECT ce."embedding"::text AS embedding
            FROM "ContentEmbedding" ce
            JOIN "Post" p ON p."id" = ce."contentId"
            WHERE ce."contentType" = 'POST'
              AND ce."embedding" IS NOT NULL
              AND COALESCE(ce."embeddingSource", ${EMBEDDING_SOURCES.LEGACY}) = ${source}
              AND p."isDeleted" = false
              AND p."moderationStatus" = 'APPROVED'
              AND p."tags" && ${interests}
            ORDER BY p."createdAt" DESC
            LIMIT 120
          `
        : [];

      const fallbackRows = rows?.length
        ? rows
        : await prisma.$queryRaw`
            SELECT ce."embedding"::text AS embedding
            FROM "ContentEmbedding" ce
            JOIN "Post" p ON p."id" = ce."contentId"
            WHERE ce."contentType" = 'POST'
              AND ce."embedding" IS NOT NULL
              AND COALESCE(ce."embeddingSource", ${EMBEDDING_SOURCES.LEGACY}) = ${source}
              AND p."isDeleted" = false
              AND p."moderationStatus" = 'APPROVED'
            ORDER BY p."createdAt" DESC
            LIMIT 80
          `;

      const vectors = (fallbackRows || [])
        .map((row) => parseVectorText(row?.embedding))
        .filter(Boolean);

      const avg = averageVectors(vectors);
      const normalized = normalizeVector(avg);
      return normalized;
    } catch (error) {
      console.warn(
        "Cold-start embedding generation failed:",
        error?.message || error,
      );
      return null;
    }
  }

  async fetchScoredContent({
    userId,
    userVector,
    embeddingSource,
    targetTypes,
    limit,
    excludeSeen,
  }) {
    const vectorLiteral = `[${userVector.join(",")}]`;
    const typeFilter = targetTypes.length
      ? Prisma.sql`AND ce."contentType" IN (${Prisma.join(targetTypes)})`
      : Prisma.empty;
    const sourceFilter = Prisma.sql`
      AND COALESCE(ce."embeddingSource", ${EMBEDDING_SOURCES.LEGACY}) = ${embeddingSource}
    `;
    const seenFilter = excludeSeen
      ? Prisma.sql`
          AND NOT EXISTS (
            SELECT 1
            FROM "UserInteraction" ui
            WHERE ui."userId" = ${userId}
              AND ui."targetType" = ce."contentType"
              AND ui."targetId" = ce."contentId"
          )
        `
      : Prisma.empty;

    try {
      const rows = await prisma.$queryRaw`
        SELECT
          ce."contentType" AS "targetType",
          ce."contentId" AS "targetId",
          1 - (ce."embedding" <=> CAST(${vectorLiteral} AS vector)) AS score
        FROM "ContentEmbedding" ce
        WHERE ce."embedding" IS NOT NULL
        ${sourceFilter}
        ${typeFilter}
        ${seenFilter}
        ORDER BY ce."embedding" <=> CAST(${vectorLiteral} AS vector)
        LIMIT ${Math.max(limit * 3, limit)}
      `;

      return this.dedupeScoredRows(rows);
    } catch (error) {
      console.warn(
        "Failed to score personalized recommendation content. Falling back to non-personalized results:",
        error?.message || error,
      );
      return [];
    }
  }

  dedupeScoredRows(rows = []) {
    const seen = new Set();
    return rows.filter((row) => {
      const targetType = row?.targetType;
      const targetId = row?.targetId;
      if (!targetType || !targetId) return false;
      const key = `${targetType}::${targetId}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }

  rerankRecommendations(items = [], options = {}) {
    if (!Array.isArray(items) || items.length === 0) return [];

    const weights = options.personalized
      ? RERANK_WEIGHTS.personalized
      : RERANK_WEIGHTS.fallback;
    const baseScores = normalizeSignals(items.map((item) => Number(item?.score)));
    const freshnessScores = normalizeSignals(
      items.map((item) => computeFreshnessSignal(item))
    );
    const popularityScores = normalizeSignals(
      items.map((item) => computePopularitySignal(item))
    );

    return items
      .map((item, index) => {
        const baseScore = baseScores[index] || 0;
        const freshnessScore = freshnessScores[index] || 0;
        const popularityScore = popularityScores[index] || 0;
        const rankScore =
          baseScore * weights.base +
          freshnessScore * weights.freshness +
          popularityScore * weights.popularity;

        return {
          ...item,
          rankScore: Number(rankScore.toFixed(6)),
          ranking: {
            baseScore: Number(baseScore.toFixed(6)),
            freshnessScore: Number(freshnessScore.toFixed(6)),
            popularityScore: Number(popularityScore.toFixed(6)),
          },
        };
      })
      .sort((a, b) => b.rankScore - a.rankScore);
  }

  postSelect(viewerId) {
    return {
      id: true,
      authorId: true,
      content: true,
      tags: true,
      category: true,
      shareCount: true,
      createdAt: true,
      author: {
        select: {
          id: true,
          firstName: true,
          lastName: true,
          email: true,
          profile: {
            select: {
              fullName: true,
              profileImage: true,
            },
          },
        },
      },
      media: {
        select: {
          fileUrl: true,
        },
      },
      postReactions: viewerId
        ? {
            where: { userId: viewerId },
            select: { userId: true },
          }
        : false,
      favorites: viewerId
        ? {
            where: { userId: viewerId },
            select: { userId: true },
          }
        : false,
      _count: {
        select: {
          comments: true,
          favorites: true,
          postReactions: true,
        },
      },
    };
  }

  async hydrateRecommendations(scoredRows, viewerId = null) {
    const idsByType = scoredRows.reduce((acc, row) => {
      if (!acc[row.targetType]) acc[row.targetType] = [];
      acc[row.targetType].push(row.targetId);
      return acc;
    }, {});

    const [posts, events, courses] = await Promise.all([
      this.safeFindMany(
        "POST",
        idsByType.POST?.length
          ? prisma.post.findMany({
              where: {
                id: { in: idsByType.POST },
                isDeleted: false,
                moderationStatus: "APPROVED",
              },
              select: this.postSelect(viewerId),
            })
          : []
      ),
      this.safeFindMany(
        "EVENT",
        idsByType.EVENT?.length
          ? prisma.event.findMany({
              where: { id: { in: idsByType.EVENT } },
              select: {
                id: true,
                title: true,
                description: true,
                university: true,
                location: true,
                views: true,
                registrations: true,
                eventDay: true,
                starts: true,
                ends: true,
              },
            })
          : []
      ),
      this.safeFindMany(
        "COURSE",
        idsByType.COURSE?.length
          ? prisma.course.findMany({
              where: { id: { in: idsByType.COURSE } },
              select: {
                id: true,
                title: true,
                description: true,
                price: true,
                videoId: true,
                expertId: true,
                createdAt: true,
              },
            })
          : []
      ),
    ]);

    const byType = {
      POST: new Map(posts.map((item) => [item.id, item])),
      EVENT: new Map(events.map((item) => [item.id, item])),
      COURSE: new Map(courses.map((item) => [item.id, item])),
    };

    return scoredRows
      .map((row) => {
        const item = byType[row.targetType]?.get(row.targetId);
        if (!item) return null;
        return {
          targetType: row.targetType,
          targetId: row.targetId,
          score: Number(Number(row.score || 0).toFixed(6)),
          item,
        };
      })
      .filter(Boolean);
  }

  async getFallbackRecommendations({ limit, targetTypes, viewerId = null }) {
    const perTypeLimit = Math.max(1, Math.ceil(limit / Math.max(targetTypes.length, 1)));
    const tasks = [];

    if (targetTypes.includes("POST")) {
      tasks.push(
        this.safeFindMany(
          "POST",
          prisma.post.findMany({
            where: {
              isDeleted: false,
              moderationStatus: "APPROVED",
            },
            take: perTypeLimit,
            orderBy: { createdAt: "desc" },
            select: this.postSelect(viewerId),
          })
        ).then((items) =>
          items.map((item) => ({
            targetType: "POST",
            targetId: item.id,
            score: null,
            item,
          }))
        )
      );
    }

    if (targetTypes.includes("EVENT")) {
      tasks.push(
        this.safeFindMany(
          "EVENT",
          prisma.event.findMany({
            take: perTypeLimit,
            orderBy: [{ registrations: "desc" }, { views: "desc" }, { eventDay: "asc" }],
            select: {
              id: true,
              title: true,
              description: true,
              university: true,
              location: true,
              views: true,
              registrations: true,
              eventDay: true,
              starts: true,
              ends: true,
            },
          })
        ).then((items) =>
          items.map((item) => ({
            targetType: "EVENT",
            targetId: item.id,
            score: null,
            item,
          }))
        )
      );
    }

    if (targetTypes.includes("COURSE")) {
      tasks.push(
        this.safeFindMany(
          "COURSE",
          prisma.course.findMany({
            take: perTypeLimit,
            orderBy: { createdAt: "desc" },
            select: {
              id: true,
              title: true,
              description: true,
              price: true,
              videoId: true,
              expertId: true,
              createdAt: true,
            },
          })
        ).then((items) =>
          items.map((item) => ({
            targetType: "COURSE",
            targetId: item.id,
            score: null,
            item,
          }))
        )
      );
    }

    const settled = await Promise.all(tasks);
    return settled.flat().slice(0, limit);
  }

  async safeFindMany(label, operation) {
    try {
      return await operation;
    } catch (error) {
      console.warn(
        `Failed to load ${label} recommendation records:`,
        error?.message || error,
      );
      return [];
    }
  }
}

module.exports = new RecommendationService();
