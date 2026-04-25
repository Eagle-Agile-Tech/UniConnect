const asyncHandler = require("../../middlewares/asyncHandler");
const prisma = require("../../lib/prisma");

const {
  UnauthorizedError,
  ForbiddenError,
  BadRequestError,
} = require("../../errors");

const {
  createCourse,
  getCoursesByExpert,
  getCourseById: getCourseByIdService,
  updateCourse: updateCourseService,
  getTopEnrolledCourses,
} = require("./course.service");

// ✅ GET COURSE BY ID (FIXED)
const getCourseById = asyncHandler(async (req, res) => {
  const user = req.user;

  if (!user) {
    return res.status(401).json({ success: false, message: "Unauthorized" });
  }

  const courseId = req.params.id;

  if (!courseId) {
    return res
      .status(400)
      .json({ success: false, message: "Invalid course ID" });
  }

  const course = await prisma.course.findUnique({
    where: { id: courseId },
    include: {
      expert: {
        select: {
          id: true,
          firstName: true,
          lastName: true,
        },
      },
    },
  });

  if (!course) {
    return res
      .status(404)
      .json({ success: false, message: "Course not found" });
  }

  if (course.expertId !== user.id) {
    return res.status(403).json({ success: false, message: "Access denied" });
  }

  return res.status(200).json({
    success: true,
    data: course,
  });
});
// ✅ UPDATE COURSE (FIXED)
const updateCourse = asyncHandler(async (req, res) => {
  const user = req.user;

  if (!user) {
    return res.status(401).json({ success: false, message: "Unauthorized" });
  }

  if (user.role !== "EXPERT") {
    return res
      .status(403)
      .json({ success: false, message: "Only experts can update courses" });
  }

const courseId = req.params.id;

 if (!courseId) {
   return res
     .status(400)
     .json({ success: false, message: "Invalid course ID" });
 }

  const { title, description, videoId, price } = req.body;

  if (!title || !description || !videoId || price === undefined) {
    return res
      .status(400)
      .json({ success: false, message: "All fields are required" });
  }

  const course = await updateCourseService(
    courseId,
    {
      title,
      description,
      videoId,
      price: Number(price),
    },
    user.id,
  );

  if (!course) {
    return res.status(404).json({
      success: false,
      message: "Course not found or access denied",
    });
  }

  return res.status(200).json({
    success: true,
    message: "Course updated successfully",
    data: course,
  });
});

// ✅ Upload Course
const uploadCourse = asyncHandler(async (req, res) => {
  const user = req.user;

  if (!user) {
    throw new UnauthorizedError("Unauthorized");
  }

  if (user.role !== "EXPERT") {
    throw new ForbiddenError("Only experts can upload courses");
  }

  const { title, description, videoId, price } = req.body;

  if (!title || !description || !videoId || price === undefined) {
    throw new BadRequestError("All fields are required");
  }

  const course = await createCourse(
    {
      title,
      description,
      videoId,
      price: Number(price),
    },
    user.id,
  );

  res.status(201).json({
    success: true,
    message: "Course uploaded successfully",
    data: course,
  });
});

// ✅ Get My Courses (for expert dashboard)
const getMyCourses = asyncHandler(async (req, res) => {
  const user = req.user;

  if (!user) {
    throw new UnauthorizedError("Unauthorized");
  }

  const courses = await getCoursesByExpert(user.id);

  res.status(200).json({
    success: true,
    data: courses,
  });
});
const getCoursesByExpertId = asyncHandler(async (req, res) => {
  const expertId = req.params.expertId;

  if (!expertId) {
    return res.status(400).json({
      success: false,
      message: "Expert ID is required",
    });
  }

  const courses = await getCoursesByExpert(expertId);

  // ✅ FORMAT FOR FRONTEND
  const formattedCourses = courses.map((course) => ({
    id: course.id,
    title: course.title,
    description: course.description,
    enrolled: course._count?.purchases || 0,
    price: Math.round(course.price),
  }));

  return res.status(200).json({
    success: true,
    data: formattedCourses,
  });
});
// (UNCHANGED - KEEP YOUR EXISTING CODE)
const getAllCourses = asyncHandler(async (req, res) => {
  const courses = await prisma.course.findMany({
    orderBy: { createdAt: "desc" },
    include: {
      expert: {
        select: {
          id: true,
          firstName: true,
          lastName: true,
        },
      },
    },
  });

  res.status(200).json({ success: true, data: courses });
});
const getTopCourses = asyncHandler(async (req, res) => {
  const courses = await getTopEnrolledCourses();

  return res.status(200).json({
    success: true,
    data: courses,
  });
});

module.exports = {
  uploadCourse,
  getMyCourses,
  getCourseById,
  updateCourse,
  getAllCourses,
  getCoursesByExpertId,
  getTopCourses,
};
