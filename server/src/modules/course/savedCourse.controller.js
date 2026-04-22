const prisma = require("../../lib/prisma");

// SAVE COURSE
const saveCourse = async (req, res) => {
  try {
    const userId = req.user.id;
    const { courseId } = req.params;

    const existing = await prisma.savedCourse.findUnique({
      where: {
        userId_courseId: {
          userId,
          courseId,
        },
      },
    });

    if (existing) {
      return res.status(400).json({
        success: false,
        message: "Course already saved",
      });
    }

    const saved = await prisma.savedCourse.create({
      data: {
        userId,
        courseId,
      },
    });

    res.json({ success: true, data: saved });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET SAVED COURSES
const getSavedCourses = async (req, res) => {
  try {
    const userId = req.user.id;

    const data = await prisma.savedCourse.findMany({
      where: { userId },
      include: { course: true },
    });

    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// REMOVE SAVED COURSE
const removeSavedCourse = async (req, res) => {
  try {
    const userId = req.user.id;
    const { courseId } = req.params;

    await prisma.savedCourse.delete({
      where: {
        userId_courseId: {
          userId,
          courseId,
        },
      },
    });

    res.json({ success: true, message: "Removed successfully" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = {
  saveCourse,
  getSavedCourses,
  removeSavedCourse,
};
