// server/src/modules/ai/ai-moderation.service.js
const axios = require("axios");

class AiModerationService {
  constructor() {
    this.isEnabled = process.env.MODERATION_ENABLED !== "false";
    this.lastRequestTime = 0;
    this.minDelay = Number(process.env.MODERATION_MIN_DELAY_MS) || 2000; // 2 seconds minimum between calls
    this.maxRetries = Number(process.env.MODERATION_MAX_RETRIES) || 3;
    this.baseBackoffMs = Number(process.env.MODERATION_BACKOFF_MS) || 1000;
    this.requestTimeoutMs = Number(process.env.MODERATION_TIMEOUT_MS) || 15000;
    this.maxTokens = Number(process.env.MODERATION_MAX_TOKENS) || 256;
    this.baseUrl =
      process.env.GROQ_BASE_URL || "https://api.groq.com/openai/v1";
    this.apiKey = process.env.GROQ_API_KEY || "";
    this.moderationModel =
      process.env.MODERATION_MODEL || "llama-3.1-8b-instant";
    this._chain = Promise.resolve(); // serialize calls to avoid rate limits

    console.log(
      `[moderation] enabled=${this.isEnabled} baseUrl=${this.baseUrl} model=${this.moderationModel} apiKeyPresent=${!!this.apiKey}`,
    );
  }

  preparePostForModeration(content = "", tags = []) {
    let text = (content || "").trim();
    if (tags && tags.length > 0) {
      text += `\n\nTags: ${tags.join(", ")}`;
    }
    return text;
  }

  async moderatePost({ content = "", tags = [] }) {
    const moderation = await this.moderateContent(content, tags);

    if (moderation.moderationStatus === "PENDING") {
      return {
        flagged: true,
        moderationStatus: "PENDING",
        details: moderation.details || { error: "Moderation pending" },
      };
    }

    const isRejected = moderation.moderationStatus === "REJECTED";
    return {
      flagged: isRejected,
      moderationStatus: moderation.moderationStatus,
      details: {
        reason: moderation.reason,
        confidence: moderation.confidence,
      },
    };
  }

  async moderateContent(text = "", tags = null) {
    if (!this.isEnabled) {
      console.log("Moderation disabled -> Auto APPROVED");
      return {
        moderationStatus: "APPROVED",
        reason: "safe",
        confidence: 1,
        details: { note: "Moderation disabled" },
      };
    }

    const inputText =
      tags && Array.isArray(tags)
        ? this.preparePostForModeration(text, tags)
        : (text || "").trim();
    if (!inputText || inputText.length < 3) {
      return {
        moderationStatus: "APPROVED",
        reason: "safe",
        confidence: 1,
      };
    }

    if (!this.apiKey) {
      console.error("[moderation] GROQ_API_KEY is missing");
      return {
        moderationStatus: "PENDING",
        reason: "error",
        confidence: 0,
        details: { error: "GROQ_API_KEY is missing" },
      };
    }

    return await this.enqueueRateLimited(async () => {
      try {
        return await this.retryModeration({ text: inputText, attempt: 1 });
      } catch (error) {
        console.error("Groq moderation error:", error?.message || error);
        return {
          moderationStatus: "PENDING",
          reason: "error",
          confidence: 0,
          details: { error: error?.message || "Groq error" },
        };
      }
    });
  }

  async enqueueRateLimited(task) {
    const run = async () => {
      // Enforce delay to avoid 429
      const now = Date.now();
      const waitTime = this.minDelay - (now - this.lastRequestTime);
      if (waitTime > 0) {
        console.log(`Waiting ${waitTime}ms before calling Ollama...`);
        await new Promise((resolve) => setTimeout(resolve, waitTime));
      }
      this.lastRequestTime = Date.now();
      return task();
    };

    const chained = this._chain.then(run, run);
    // Keep the chain alive even if a task fails
    this._chain = chained.catch(() => {});
    return chained;
  }

  async retryModeration({ text, attempt }) {
    if (attempt > this.maxRetries) {
      return {
        moderationStatus: "PENDING",
        reason: "error",
        confidence: 0,
        details: { error: "Retries exhausted" },
      };
    }

    if (attempt > 1) {
      const backoffMs = this.baseBackoffMs * Math.pow(2, attempt - 1);
      const jitter = Math.floor(Math.random() * 250);
      const waitMs = backoffMs + jitter;
      console.warn(
        `Backoff retry ${attempt}/${this.maxRetries}: waiting ${waitMs}ms`,
      );
      await new Promise((resolve) => setTimeout(resolve, waitMs));
    }

    try {
      return await this.callGroqAndParse(text);
    } catch (error) {
      if (error?.response?.status === 429 || error?.status === 429) {
        this.logRateLimitHeaders(error);
        return this.retryModeration({ text, attempt: attempt + 1 });
      }
      return {
        moderationStatus: "PENDING",
        reason: "error",
        confidence: 0,
        details: { error: error.message },
      };
    }
  }

  getRetryAfterMs(error) {
    const headers = error?.headers || error?.response?.headers || {};
    const retryAfter = headers["retry-after"] || headers["Retry-After"];
    if (!retryAfter) return null;
    const seconds = Number(retryAfter);
    if (Number.isFinite(seconds)) return Math.max(0, seconds * 1000);
    const dateMs = Date.parse(retryAfter);
    if (!Number.isNaN(dateMs)) return Math.max(0, dateMs - Date.now());
    return null;
  }

  logRateLimitHeaders(error) {
    const headers = error?.headers || error?.response?.headers || {};
    const keys = Object.keys(headers);
    const rateLimitHeaders = keys.filter((k) =>
      k.toLowerCase().startsWith("x-ratelimit-"),
    );

    if (headers["retry-after"] || headers["Retry-After"]) {
      console.warn("retry-after:", headers["retry-after"] || headers["Retry-After"]);
    }
    if (rateLimitHeaders.length > 0) {
      console.warn("rate-limit headers:");
      rateLimitHeaders.forEach((k) => {
        console.warn(`  ${k}: ${headers[k]}`);
      });
    }
  }

  buildModerationPrompt(text) {
    return [
      "You are a strict content moderation classifier.",
      "Decide if the content should be APPROVED or REJECTED.",
      "Return ONLY valid JSON with keys: moderationStatus, reason, confidence.",
      "moderationStatus must be APPROVED or REJECTED.",
      "reason must be a short category like: hate, violence, spam, harassment, sexual, self-harm, safe, other.",
      "confidence must be a number between 0 and 1.",
      "",
      "Content:",
      text,
    ].join("\n");
  }

  parseModerationJson(rawText) {
    if (!rawText || typeof rawText !== "string") return null;
    const trimmed = rawText.trim();
    if (!trimmed) return null;
    try {
      return JSON.parse(trimmed);
    } catch {
      const match = trimmed.match(/\{[\s\S]*\}/);
      if (!match) return null;
      try {
        return JSON.parse(match[0]);
      } catch {
        return null;
      }
    }
  }

  normalizeModerationResult(parsed) {
    if (!parsed || typeof parsed !== "object") return null;
    const statusRaw = String(parsed.moderationStatus || parsed.status || "")
      .trim()
      .toUpperCase();
    if (statusRaw !== "APPROVED" && statusRaw !== "REJECTED") return null;

    const reasonRaw =
      typeof parsed.reason === "string" && parsed.reason.trim()
        ? parsed.reason.trim()
        : statusRaw === "APPROVED"
          ? "safe"
          : "other";

    let confidence = Number(parsed.confidence);
    if (!Number.isFinite(confidence)) confidence = 0.5;
    confidence = Math.max(0, Math.min(1, confidence));

    return {
      moderationStatus: statusRaw,
      reason: reasonRaw,
      confidence,
    };
  }

  async callGroqAndParse(text) {
    const prompt = this.buildModerationPrompt(text);
    const url = `${this.baseUrl}/chat/completions`;
    let response;
    try {
      response = await axios.post(
        url,
        {
          model: this.moderationModel,
          messages: [
            {
              role: "system",
              content:
                "You are a strict content moderation classifier. Reply with ONLY valid JSON.",
            },
            { role: "user", content: prompt },
          ],
          temperature: 0,
          max_tokens: this.maxTokens,
          stream: false,
        },
        {
          timeout: this.requestTimeoutMs,
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            "Content-Type": "application/json",
          },
        },
      );
    } catch (error) {
      const status = error?.response?.status || error?.status;
      const data = error?.response?.data;
      console.error(
        "[moderation] Groq request failed",
        status,
        data ? JSON.stringify(data) : error?.message || error,
      );
      throw error;
    }

    const raw = response?.data?.choices?.[0]?.message?.content;
    const parsed = this.parseModerationJson(raw);
    const normalized = this.normalizeModerationResult(parsed);

    if (!normalized) {
      return {
        moderationStatus: "PENDING",
        reason: "unparseable",
        confidence: 0,
        details: { error: "Invalid moderation response", raw },
      };
    }

    return normalized;
  }

  async enqueuePostModeration({ postId, content, tags }) {
    const moderationResult = await this.moderatePost({ content, tags });

    const prisma = require("../../lib/prisma");
    await prisma.post.update({
      where: { id: postId },
      data: { moderationStatus: moderationResult.moderationStatus },
    });

    return moderationResult;
  }
}

module.exports = new AiModerationService();
