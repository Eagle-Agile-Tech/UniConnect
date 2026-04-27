const express = require("express");
const authMiddleware = require("../../middlewares/authMiddleware");
const {
  saveCourse,
  getSavedCourses,
  removeSavedCourse,
} = require("./savedCourse.controller");

const router = express.Router();

// Save course
router.post("/:courseId", authMiddleware, saveCourse);

// Get saved courses
router.get("/", authMiddleware, getSavedCourses);

// Remove saved course
router.delete("/:courseId", authMiddleware, removeSavedCourse);

module.exports = router;
