const communityService = require("./community.service");

function attachCommunityErrorContext(error, context) {
  if (!error || typeof error !== "object") return error;
  const details = error.details && typeof error.details === "object" ? error.details : {};
  error.details = { ...details, ...context, module: "community" };
  return error;
}

class CommunityController {
  async createCommunity(req, res, next) {
    let userId;
    try {
      userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const community = await communityService.createCommunity(req.body, userId);

      res.status(201).json({
        status: "success",
        data: community,
      });
    } catch (error) {
      next(
        attachCommunityErrorContext(error, {
          operation: "createCommunity",
          userId,
          name: req.body?.name,
        }),
      );
    }
  }

  async postToCommunity(req, res, next) {
    let userId;
    try {
      userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const result = await communityService.postToCommunity(
        req.body,
        userId,
        req.files || [],
      );

      res.status(201).json({
        status: "success",
        data: result,
      });
    } catch (error) {
      next(
        attachCommunityErrorContext(error, {
          operation: "postToCommunity",
          userId,
          communityId: req.body?.communityId,
        }),
      );
    }
  }

  async addCommunityMember(req, res, next) {
    let userId;
    try {
      userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const member = await communityService.addCommunityMember(req.body, userId);

      res.status(201).json({
        status: "success",
        data: member,
      });
    } catch (error) {
      next(
        attachCommunityErrorContext(error, {
          operation: "addCommunityMember",
          userId,
          communityId: req.body?.communityId,
          targetUserId: req.body?.userId,
        }),
      );
    }
  }

  async updateCommunity(req, res, next) {
    let userId;
    try {
      userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const updated = await communityService.updateCommunity(
        req.params.communityId,
        req.body,
        userId,
      );

      res.status(200).json({
        status: "success",
        data: updated,
      });
    } catch (error) {
      next(
        attachCommunityErrorContext(error, {
          operation: "updateCommunity",
          userId,
          communityId: req.params?.communityId,
        }),
      );
    }
  }

  async deleteCommunity(req, res, next) {
    let userId;
    try {
      userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const deleted = await communityService.deleteCommunity(
        req.params.communityId,
        userId,
      );

      res.status(200).json({
        status: "success",
        data: deleted,
      });
    } catch (error) {
      next(
        attachCommunityErrorContext(error, {
          operation: "deleteCommunity",
          userId,
          communityId: req.params?.communityId,
        }),
      );
    }
  }

  async leaveCommunity(req, res, next) {
    let userId;
    try {
      userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const result = await communityService.leaveCommunity(
        req.body.communityId,
        userId,
      );

      res.status(200).json({
        status: "success",
        data: result,
      });
    } catch (error) {
      next(
        attachCommunityErrorContext(error, {
          operation: "leaveCommunity",
          userId,
          communityId: req.body?.communityId,
        }),
      );
    }
  }
}

module.exports = new CommunityController();
