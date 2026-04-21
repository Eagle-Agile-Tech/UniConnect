const router = require("express").Router();
const communityController = require("./community.controller");
const authenticate = require("../../middlewares/authMiddleware");
const validateRequest = require("../../middlewares/validateRequest");
const communitySchema = require("./community.schema");
const upload = require("../../config/multer");
const {
  uploadProfileImage,
  attachUploadedCommunityImage,
} = require("../../middlewares/profileImageUpload");

function normalizeCommunityPostPayload(req, _res, next) {
  const { body } = req;

  if (typeof body.tags === "string") {
    try {
      body.tags = JSON.parse(body.tags);
    } catch (_err) {
      body.tags = body.tags
        .split(",")
        .map((tag) => tag.trim())
        .filter(Boolean);
    }
  }

  if (typeof body.mediaIds === "string") {
    try {
      body.mediaIds = JSON.parse(body.mediaIds);
    } catch (_err) {
      body.mediaIds = body.mediaIds
        .split(",")
        .map((id) => id.trim())
        .filter(Boolean);
    }
  }

  if (body.category === "") {
    body.category = null;
  }

  next();
}

router.use(authenticate);

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
  upload.array("media", 10),
  normalizeCommunityPostPayload,
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
