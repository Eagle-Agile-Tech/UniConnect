const prisma = require("../../lib/prisma");

const TARGET_TYPES = {
  POST: "POST",
  EVENT: "EVENT",
  USER: "USER",
  COURSE: "COURSE",
};

const INTERACTION_TYPES = {
  VIEW: "VIEW",
  LIKE: "LIKE",
  COMMENT: "COMMENT",
  SHARE: "SHARE",
  CLICK: "CLICK",
  SAVE: "SAVE",
};

// Keep this in sync with training dataset generation weights so that:
// - interaction metadata endpoint can report weights
// - ML dataset export and runtime interpretation align
const INTERACTION_WEIGHTS = {
  VIEW: 1,
  CLICK: 2,
  LIKE: 3,
  SAVE: 4,
  COMMENT: 4,
  SHARE: 5,
};

class InteractionService {
  async logInteraction({
    userId,
    targetType,
    targetId,
    interactionType,
    value = 1,
    metadata,
    tx,
  }) {
    if (!userId || !targetType || !targetId || !interactionType) {
      return null;
    }

    const db = tx || prisma;

    return db.userInteraction.create({
      data: {
        userId,
        targetType,
        targetId,
        interactionType,
        value,
        metadata,
      },
    });
  }

  async logInteractionSafe(payload) {
    try {
      return await this.logInteraction(payload);
    } catch (error) {
      console.error(
        "Interaction logging failed:",
        error?.message || error,
        payload,
      );
      return null;
    }
  }

  async logPostView(userId, postId, metadata = {}) {
    return this.logInteractionSafe({
      userId,
      targetType: TARGET_TYPES.POST,
      targetId: postId,
      interactionType: INTERACTION_TYPES.VIEW,
      metadata,
    });
  }

  async logPostLike(userId, postId, metadata = {}, tx) {
    return this.logInteractionSafe({
      userId,
      targetType: TARGET_TYPES.POST,
      targetId: postId,
      interactionType: INTERACTION_TYPES.LIKE,
      metadata,
      tx,
    });
  }

  async logPostComment(userId, postId, metadata = {}, tx) {
    return this.logInteractionSafe({
      userId,
      targetType: TARGET_TYPES.POST,
      targetId: postId,
      interactionType: INTERACTION_TYPES.COMMENT,
      metadata,
      tx,
    });
  }

  async logPostSave(userId, postId, metadata = {}, tx) {
    return this.logInteractionSafe({
      userId,
      targetType: TARGET_TYPES.POST,
      targetId: postId,
      interactionType: INTERACTION_TYPES.SAVE,
      metadata,
      tx,
    });
  }

  async logEventView(userId, eventId, metadata = {}) {
    return this.logInteractionSafe({
      userId,
      targetType: TARGET_TYPES.EVENT,
      targetId: eventId,
      interactionType: INTERACTION_TYPES.VIEW,
      metadata,
    });
  }

  async logEventRegistration(userId, eventId, metadata = {}) {
    return this.logInteractionSafe({
      userId,
      targetType: TARGET_TYPES.EVENT,
      targetId: eventId,
      interactionType: INTERACTION_TYPES.CLICK,
      value: 2,
      metadata,
    });
  }
}

module.exports = {
  interactionService: new InteractionService(),
  TARGET_TYPES,
  INTERACTION_TYPES,
  INTERACTION_WEIGHTS,
};
