const recommendationService = require("./recommendation.service");

function parseCsv(value) {
  if (!value) return [];
  return String(value)
    .split(",")
    .map((item) => item.trim().toUpperCase())
    .filter(Boolean);
}

class RecommendationController {
  resolveRequestedUserId(req) {
    const actorId = req.user?.id || req.user?.sub;
    const requestedUserId = req.params?.userId;

    if (!requestedUserId || requestedUserId === actorId) {
      return actorId;
    }

    if (req.user?.role === "ADMIN") {
      return requestedUserId;
    }

    return null;
  }

  getForCurrentUser = async (req, res) => {
    const userId = this.resolveRequestedUserId(req);

    if (!userId) {
      return res.status(req.params?.userId ? 403 : 401).json({
        success: false,
        message: req.params?.userId ? "Forbidden" : "Unauthorized",
      });
    }

    const data = await recommendationService.getRecommendationsForUser(userId, {
      limit: req.query.limit,
      targetTypes: parseCsv(req.query.targetTypes),
      excludeSeen: req.query.excludeSeen !== "false",
    });

    return res.status(200).json({
      success: true,
      data,
    });
  };

  getStatus = async (_req, res) => {
    const data = await recommendationService.getSystemStatus();

    return res.status(200).json({
      success: true,
      data,
    });
  };

  // "Product moment" vector-ranking endpoint:
  // fetch user embedding -> cosine search in pgvector -> return ranked items.
  getVectorRankForCurrentUser = async (req, res) => {
    const actorId = req.user?.id || req.user?.sub;
    if (!actorId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    const data = await recommendationService.getVectorRankedRecommendations(
      actorId,
      {
        limit: req.query.limit,
        targetTypes: parseCsv(req.query.targetTypes),
        excludeSeen: req.query.excludeSeen !== "false",
      },
    );

    return res.status(200).json({ success: true, data });
  };

  getVectorRankForUser = async (req, res) => {
    const userId = this.resolveRequestedUserId(req);

    if (!userId) {
      return res.status(403).json({
        success: false,
        message: "Forbidden",
      });
    }

    const data = await recommendationService.getVectorRankedRecommendations(
      userId,
      {
        limit: req.query.limit,
        targetTypes: parseCsv(req.query.targetTypes),
        excludeSeen: req.query.excludeSeen !== "false",
      },
    );

    return res.status(200).json({ success: true, data });
  };
}

module.exports = new RecommendationController();
