const {
  interactionService,
  INTERACTION_TYPES,
  INTERACTION_WEIGHTS,
  TARGET_TYPES,
} = require("./interaction.service");

function normalizeEnum(value) {
  return String(value || "")
    .trim()
    .toUpperCase();
}

class InteractionController {
  async create(req, res) {
    const actorId = req.user?.id || req.user?.sub;
    const requestedUserId = req.body?.userId;
    const userId =
      req.user?.role === "ADMIN" && requestedUserId ? requestedUserId : actorId;

    const targetType = normalizeEnum(req.body?.targetType);
    const interactionType = normalizeEnum(req.body?.interactionType);
    const targetId = req.body?.targetId;
    const metadata = req.body?.metadata;
    const value = req.body?.value;

    if (!userId || !targetId || !targetType || !interactionType) {
      return res.status(400).json({
        success: false,
        message:
          "userId, targetType, targetId, and interactionType are required.",
      });
    }

    if (!Object.values(TARGET_TYPES).includes(targetType)) {
      return res.status(400).json({
        success: false,
        message: `Unsupported targetType "${targetType}".`,
      });
    }

    if (!Object.values(INTERACTION_TYPES).includes(interactionType)) {
      return res.status(400).json({
        success: false,
        message: `Unsupported interactionType "${interactionType}".`,
      });
    }

    const interaction = await interactionService.logInteraction({
      userId,
      targetType,
      targetId,
      interactionType,
      value,
      metadata,
    });

    return res.status(201).json({
      success: true,
      data: interaction,
    });
  }

  async getMetadata(_req, res) {
    return res.status(200).json({
      success: true,
      data: {
        targetTypes: Object.values(TARGET_TYPES),
        interactionTypes: Object.values(INTERACTION_TYPES),
        weights: INTERACTION_WEIGHTS,
      },
    });
  }
}

module.exports = new InteractionController();
