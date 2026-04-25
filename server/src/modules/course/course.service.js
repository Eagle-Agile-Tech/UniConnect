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
// GET TOP 10 MOST ENROLLED COURSES
const getTopEnrolledCourses = async () => {
  const courses = await prisma.course.findMany({
    include: {
      expert: {
        select: {
          id: true,
          firstName: true,
          lastName: true,
          expertProfile: {
            select: {
              bio: true,
              profileImage: true,
            },
          },
          profile: {
            select: {
              username: true,
              profileImage: true,
            },
          },
        },
      },
      purchases: {
        where: { paid: true },
        select: { id: true },
      },
    },
  });

  // compute + sort
  const ranked = courses
    .map((course) => ({
      id: course.id,
      title: course.title,
      link: `https://www.youtube.com/watch?v=${course.videoId}`,
      description: course.description,
      enrolled: course.purchases.length,
      price: Math.round(course.price),

      expert: {
        id: course.expert.id,
        firstName: course.expert.firstName,
        lastName: course.expert.lastName,
        userName: course.expert.profile?.username || null,
        profileImage:
          course.expert.profile?.profileImage ||
          course.expert.expertProfile?.profileImage ||
          null,
      },
    }))
    .sort((a, b) => b.enrolled - a.enrolled)
    .slice(0, 10);

  return ranked;
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
  getTopEnrolledCourses,
};
