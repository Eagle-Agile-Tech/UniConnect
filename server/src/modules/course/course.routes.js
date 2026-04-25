const express = require("express");
const authMiddleware = require("../../middlewares/authMiddleware");

const {
  uploadCourse,
  getMyCourses,
  getCourseById,
  updateCourse,
  getAllCourses,
  getCoursesByExpertId,
  getTopCourses,
} = require("./course.controller");

const router = express.Router();

// ✅ IMPORTANT: static routes first
router.get("/", authMiddleware, getAllCourses);
router.get("/my", authMiddleware, getMyCourses);
router.get("/", authMiddleware, getAllCourses);
router.get("/my", authMiddleware, getMyCourses);
router.get("/expert/:expertId", authMiddleware, getCoursesByExpertId);
router.get("/top/enrolled", authMiddleware, getTopCourses);

// ❗ keep this last
router.get("/:id", authMiddleware, getCourseById);

// ✅ dynamic routes last
router.get("/:id", authMiddleware, getCourseById);
router.put("/:id", authMiddleware, updateCourse);

router.post("/", authMiddleware, uploadCourse);

module.exports = router;
