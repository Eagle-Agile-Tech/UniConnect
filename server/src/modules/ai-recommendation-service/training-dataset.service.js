const prisma = require("../../lib/prisma");

const INTERACTION_WEIGHTS = {
  VIEW: 1,
  CLICK: 2,
  LIKE: 3,
  SAVE: 4,
  COMMENT: 4,
  SHARE: 5,
};

function clampLimit(limit, fallback = 5000, max = 20000) {
  const parsed = Number(limit);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return Math.min(parsed, max);
}

function buildSinceDate(days) {
  const parsed = Number(days);
  if (!Number.isFinite(parsed) || parsed <= 0) return null;
  const date = new Date();
  date.setDate(date.getDate() - parsed);
  return date;
}

function toArray(value) {
  return Array.isArray(value) ? value : [];
}

function safeJson(value) {
  if (!value || typeof value !== "object") return value ?? null;
  try {
    return JSON.parse(JSON.stringify(value));
  } catch (_error) {
    return null;
  }
}

class TrainingDatasetService {
  async generateDataset(options = {}) {
    const aggregate = options.aggregate !== false;
    const limit = clampLimit(options.limit);
    const since = buildSinceDate(options.days);
    const targetTypes = toArray(options.targetTypes).filter(Boolean);
    const userIds = toArray(options.userIds).filter(Boolean);

    const interactions = await prisma.userInteraction.findMany({
      where: {
        ...(since ? { createdAt: { gte: since } } : {}),
        ...(targetTypes.length > 0 ? { targetType: { in: targetTypes } } : {}),
        ...(userIds.length > 0 ? { userId: { in: userIds } } : {}),
      },
      orderBy: { createdAt: "desc" },
      take: limit,
    });

    const context = await this.loadContext(interactions);
    const rows = aggregate
      ? this.buildAggregatedRows(interactions, context)
      : this.buildRawRows(interactions, context);

    return {
      summary: {
        generatedAt: new Date().toISOString(),
        totalInteractions: interactions.length,
        totalRows: rows.length,
        aggregated: aggregate,
        since: since ? since.toISOString() : null,
        limit,
        targetTypes,
      },
      rows,
    };
  }

  async loadContext(interactions) {
    const actorIds = [...new Set(interactions.map((item) => item.userId).filter(Boolean))];
    const idsByType = interactions.reduce((acc, item) => {
      if (!acc[item.targetType]) acc[item.targetType] = new Set();
      acc[item.targetType].add(item.targetId);
      return acc;
    }, {});

    const [users, posts, events, courses, targetUsers] = await Promise.all([
      actorIds.length
        ? prisma.user.findMany({
            where: { id: { in: actorIds } },
            include: {
              profile: {
                include: {
                  university: { select: { id: true, name: true } },
                },
              },
              expertProfile: true,
              institutionProfile: true,
              userProfileMLs: true,
            },
          })
        : [],
      idsByType.POST?.size
        ? prisma.post.findMany({
            where: { id: { in: [...idsByType.POST] } },
            include: {
              author: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                  profile: { select: { username: true } },
                },
              },
              community: { select: { id: true, name: true } },
            },
          })
        : [],
      idsByType.EVENT?.size
        ? prisma.event.findMany({
            where: { id: { in: [...idsByType.EVENT] } },
          })
        : [],
      idsByType.COURSE?.size
        ? prisma.course.findMany({
            where: { id: { in: [...idsByType.COURSE] } },
            include: {
              expert: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                  profile: { select: { username: true } },
                },
              },
            },
          })
        : [],
      idsByType.USER?.size
        ? prisma.user.findMany({
            where: { id: { in: [...idsByType.USER] } },
            include: {
              profile: {
                include: {
                  university: { select: { id: true, name: true } },
                },
              },
              expertProfile: true,
              institutionProfile: true,
              userProfileMLs: true,
            },
          })
        : [],
    ]);

    return {
      users: new Map(users.map((user) => [user.id, this.formatUserFeatures(user)])),
      targets: {
        POST: new Map(posts.map((post) => [post.id, this.formatPostTarget(post)])),
        EVENT: new Map(events.map((event) => [event.id, this.formatEventTarget(event)])),
        COURSE: new Map(courses.map((course) => [course.id, this.formatCourseTarget(course)])),
        USER: new Map(targetUsers.map((user) => [user.id, this.formatUserTarget(user)])),
      },
    };
  }

  buildRawRows(interactions, context) {
    return interactions.map((interaction) => {
      const weight = INTERACTION_WEIGHTS[interaction.interactionType] || 1;
      return {
        interactionId: interaction.id,
        userId: interaction.userId,
        targetType: interaction.targetType,
        targetId: interaction.targetId,
        interactionType: interaction.interactionType,
        value: interaction.value,
        weight,
        score: interaction.value * weight,
        createdAt: interaction.createdAt.toISOString(),
        metadata: safeJson(interaction.metadata),
        userFeatures: context.users.get(interaction.userId) || null,
        targetFeatures:
          context.targets[interaction.targetType]?.get(interaction.targetId) || null,
      };
    });
  }

  buildAggregatedRows(interactions, context) {
    const grouped = new Map();

    for (const interaction of interactions) {
      const key = `${interaction.userId}::${interaction.targetType}::${interaction.targetId}`;
      const weight = INTERACTION_WEIGHTS[interaction.interactionType] || 1;
      const weightedScore = interaction.value * weight;

      if (!grouped.has(key)) {
        grouped.set(key, {
          userId: interaction.userId,
          targetType: interaction.targetType,
          targetId: interaction.targetId,
          interactionCount: 0,
          totalValue: 0,
          totalScore: 0,
          firstInteractionAt: interaction.createdAt,
          lastInteractionAt: interaction.createdAt,
          interactionBreakdown: {},
          metadataExamples: [],
        });
      }

      const item = grouped.get(key);
      item.interactionCount += 1;
      item.totalValue += interaction.value;
      item.totalScore += weightedScore;
      if (interaction.createdAt < item.firstInteractionAt) {
        item.firstInteractionAt = interaction.createdAt;
      }
      if (interaction.createdAt > item.lastInteractionAt) {
        item.lastInteractionAt = interaction.createdAt;
      }
      item.interactionBreakdown[interaction.interactionType] =
        (item.interactionBreakdown[interaction.interactionType] || 0) + 1;
      if (interaction.metadata && item.metadataExamples.length < 5) {
        item.metadataExamples.push(safeJson(interaction.metadata));
      }
    }

    return [...grouped.values()]
      .map((row) => ({
        ...row,
        firstInteractionAt: row.firstInteractionAt.toISOString(),
        lastInteractionAt: row.lastInteractionAt.toISOString(),
        label: row.totalScore,
        userFeatures: context.users.get(row.userId) || null,
        targetFeatures: context.targets[row.targetType]?.get(row.targetId) || null,
      }))
      .sort((a, b) => b.totalScore - a.totalScore);
  }

  formatUserFeatures(user) {
    return {
      id: user.id,
      role: user.role,
      verificationStatus: user.verificationStatus,
      profile: user.profile
        ? {
            username: user.profile.username,
            bio: user.profile.bio,
            interests: user.profile.interests || [],
            department: user.profile.department,
            level: user.profile.level,
            yearOfStudy: user.profile.yearOfStudy,
            graduationYear: user.profile.graduationYear,
            university: user.profile.university?.name || null,
          }
        : null,
      expertProfile: user.expertProfile
        ? {
            expertise: user.expertProfile.expertise,
            bio: user.expertProfile.bio,
          }
        : null,
      institutionProfile: user.institutionProfile
        ? {
            name: user.institutionProfile.name,
            type: user.institutionProfile.type,
            description: user.institutionProfile.description,
          }
        : null,
      mlProfile: Array.isArray(user.userProfileMLs) && user.userProfileMLs[0]
        ? {
            interests: user.userProfileMLs[0].interests,
            skills: user.userProfileMLs[0].skills,
            preferredCategories: user.userProfileMLs[0].preferredCategories,
          }
        : null,
    };
  }

  formatUserTarget(user) {
    return {
      id: user.id,
      type: "USER",
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
      username: user.profile?.username || null,
      interests: user.profile?.interests || [],
      bio: user.profile?.bio || user.expertProfile?.bio || null,
      expertise: user.expertProfile?.expertise || null,
      university: user.profile?.university?.name || null,
    };
  }

  formatPostTarget(post) {
    return {
      id: post.id,
      type: "POST",
      authorId: post.authorId,
      authorUsername: post.author?.profile?.username || null,
      content: post.content,
      category: post.category,
      tags: post.tags || [],
      visibility: post.visibility,
      moderationStatus: post.moderationStatus,
      community: post.community?.name || null,
      createdAt: post.createdAt.toISOString(),
    };
  }

  formatEventTarget(event) {
    return {
      id: event.id,
      type: "EVENT",
      authorId: event.authorId,
      title: event.title,
      description: event.description,
      university: event.university,
      location: event.location,
      starts: event.starts.toISOString(),
      ends: event.ends.toISOString(),
      eventDay: event.eventDay.toISOString(),
    };
  }

  formatCourseTarget(course) {
    return {
      id: course.id,
      type: "COURSE",
      expertId: course.expertId,
      expertUsername: course.expert?.profile?.username || null,
      title: course.title,
      description: course.description,
      videoId: course.videoId,
      price: course.price,
      createdAt: course.createdAt.toISOString(),
    };
  }

  toJsonl(rows) {
    return rows.map((row) => JSON.stringify(row)).join("\n");
  }
}

module.exports = new TrainingDatasetService();
