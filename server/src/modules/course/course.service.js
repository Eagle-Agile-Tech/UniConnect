const prisma = require("../../lib/prisma");

// CREATE COURSE
const createCourse = async ({ title, description, videoId, price }, userId) => {
  return prisma.course.create({
    data: {
      title,
      description,
      videoId,
      price,
      expertId: userId,
    },
  });
};

// GET COURSES BY EXPERT (FIXED)
const getCoursesByExpert = async (userId) => {
  return prisma.course.findMany({
    where: { expertId: userId },
    orderBy: { createdAt: "desc" },
    include: {
      expert: {
        select: {
          id: true,
          firstName: true,
          lastName: true,
        },
      },
      _count: {
        select: {
          purchases: {
            where: {
              paid: true, // ✅ ONLY count paid purchases
            },
          },
        },
      },
    },
  });
};

// GET BY ID
const getCourseById = async (courseId) => {
  return prisma.course.findUnique({
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
};

// UPDATE
const updateCourse = async (courseId, data, userId) => {
  const course = await prisma.course.findUnique({
    where: { id: courseId },
  });

  if (!course || course.expertId !== userId) return null;

  return prisma.course.update({
    where: { id: courseId },
    data: {
      title: data.title,
      description: data.description,
      videoId: data.videoId,
      price: Number(data.price),
    },
  });
};

module.exports = {
  createCourse,
  getCoursesByExpert,
  getCourseById,
  updateCourse,
};
