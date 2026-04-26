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
      userId = req.user?.sub || req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const community = await communityService.createCommunity(req.body, userId);

      res.status(201).json(community);
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
      userId = req.user?.sub || req.user?.id;
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
      userId = req.user?.sub || req.user?.id;
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
      userId = req.user?.sub || req.user?.id;
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
      userId = req.user?.sub || req.user?.id;
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
      userId = req.user?.sub || req.user?.id;
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

  async joinCommunity(req, res, next) {
    let userId;
    try {
      userId = req.user?.sub || req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const result = await communityService.joinCommunity(
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
          operation: "joinCommunity",
          userId,
          communityId: req.body?.communityId,
        }),
      );
    }
  }

  async getCommunity(req, res, next) {
    let userId;
    try {
      userId = req.user?.sub || req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const community = await communityService.getCommunityById(
        req.params.communityId,
        userId,
      );

      res.status(200).json(community);
    } catch (error) {
      next(
        attachCommunityErrorContext(error, {
          operation: "getCommunity",
          userId,
          communityId: req.params?.communityId,
        }),
      );
    }
  }

  async getTopCommunities(req, res, next) {
    let userId;
    try {
      userId = req.user?.sub || req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const communities = await communityService.getTopCommunities(
        userId,
        req.query?.limit,
      );

      res.status(200).json(communities);
    } catch (error) {
      next(
        attachCommunityErrorContext(error, {
          operation: "getTopCommunities",
          userId,
        }),
      );
    }
  }

  async getCommunityMembers(req, res, next) {
    let userId;
    try {
      userId = req.user?.sub || req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const members = await communityService.getCommunityMembers(
        req.params.communityId,
      );

      res.status(200).json(members);
    } catch (error) {
      next(
        attachCommunityErrorContext(error, {
          operation: "getCommunityMembers",
          userId,
          communityId: req.params?.communityId,
        }),
      );
    }
  }

  async getCommunityPosts(req, res, next) {
    let userId;
    try {
      userId = req.user?.sub || req.user?.id;
      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const posts = await communityService.getCommunityPosts(
        req.params.communityId,
        userId,
        req.query?.page,
        req.query?.limit,
      );

      res.status(200).json(posts);
    } catch (error) {
      next(
        attachCommunityErrorContext(error, {
          operation: "getCommunityPosts",
          userId,
          communityId: req.params?.communityId,
        }),
      );
    }
  }
}

module.exports = new CommunityController();
