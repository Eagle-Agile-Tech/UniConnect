const express = require("express");
const authMiddleware = require("../../middlewares/authMiddleware");

const {
  uploadCourse,
  getMyCourses,
  getCourseById,
  updateCourse,
  getAllCourses,
} = require("./course.controller");

const router = express.Router();

// ✅ IMPORTANT: static routes first
router.get("/", authMiddleware, getAllCourses);
router.get("/my", authMiddleware, getMyCourses);

// ✅ dynamic routes last
router.get("/:id", authMiddleware, getCourseById);
router.put("/:id", authMiddleware, updateCourse);

router.post("/", authMiddleware, uploadCourse);

module.exports = router;
