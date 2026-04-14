const router = require("express").Router();
const communityController = require("./community.controller");
const authMiddleware = require("../../middlewares/auth");
const validateRequest = require("../../middlewares/validateRequest");
const communitySchema = require("./community.schema");
const {
  uploadProfileImage,
  attachUploadedCommunityImage,
} = require("../../middlewares/profileImageUpload");

router.use(authMiddleware.authenticate);

router.post(
  "/",
  uploadProfileImage,
  attachUploadedCommunityImage,
  validateRequest(communitySchema.createCommunitySchema),
  communityController.createCommunity,
);

router.patch(
  "/:communityId",
  uploadProfileImage,
  attachUploadedCommunityImage,
  validateRequest(communitySchema.communityIdParamSchema, "params"),
  validateRequest(communitySchema.updateCommunitySchema),
  communityController.updateCommunity,
);

router.delete(
  "/:communityId",
  validateRequest(communitySchema.communityIdParamSchema, "params"),
  communityController.deleteCommunity,
);

router.post(
  "/posts",
  validateRequest(communitySchema.postToCommunitySchema),
  communityController.postToCommunity,
);

router.post(
  "/members",
  validateRequest(communitySchema.addCommunityMemberSchema),
  communityController.addCommunityMember,
);

router.post(
  "/leave",
  validateRequest(communitySchema.leaveCommunitySchema),
  communityController.leaveCommunity,
);

module.exports = router;
