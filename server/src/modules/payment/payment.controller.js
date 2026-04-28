const asyncHandler = require("../../middlewares/asyncHandler");
const prisma = require("../../lib/prisma");
const { initializePayment, verifyPayment } = require("./payment.service");
const { getMyPurchasedCourses } = require("./payment.service");
const notificationService = require("../notification/notification.service");

const getMyCoursesController = asyncHandler(async (req, res) => {
  const user = req.user;

  const purchases = await getMyPurchasedCourses(user.id);

  res.status(200).json({
    success: true,
    data: purchases,
  });
});


// START PAYMENT
const startPayment = asyncHandler(async (req, res) => {
  const user = req.user;
  const { courseId } = req.body;

  if (!courseId) {
    return res.status(400).json({ message: "courseId is required" });
  }

  const course = await prisma.course.findUnique({
    where: { id: courseId },
  });

  if (!course) {
    return res.status(404).json({ message: "Course not found" });
  }

  const result = await initializePayment({
    amount: course.price,
    email: user.email,
    firstName: user.firstName,
    lastName: user.lastName,
    courseId: course.id,
    userId: user.id,
  });

  return res.status(200).json({
    success: true,
    checkout_url: result.checkout_url,
    tx_ref: result.tx_ref,
  });
});
// VERIFY PAYMENT (IMPORTANT STEP)
const verifyPaymentController = asyncHandler(async (req, res) => {
  const { tx_ref, courseId } = req.query;
  const user = req.user;

  const verification = await verifyPayment(tx_ref);

  const status = verification?.data?.status;

  if (status === "success") {
    await prisma.purchase.updateMany({
      where: {
        userId: user.id,
        courseId,
      },
      data: {
        paid: true,
      },
    });

    // Notify expert (best effort). We don't have COURSE in NotificationReferenceType,
    // so include courseId in the data payload.
    try {
      const course = await prisma.course.findUnique({
        where: { id: courseId },
        select: { id: true, title: true, expertId: true },
      });
      if (course?.expertId && course.expertId !== user.id) {
        await notificationService.createAndSendNotification({
          recipientId: course.expertId,
          actorId: user.id,
          type: "SYSTEM",
          title: "New course purchase",
          body: `Someone purchased "${course.title}"`,
          data: {
            courseId: course.id,
            buyerId: user.id,
          },
        });
      }
    } catch (_err) {
      // best-effort
    }

    return res.status(200).json({
      success: true,
      message: "Payment verified successfully",
    });
  }

  return res.status(400).json({
    success: false,
    message: "Payment not completed",
  });
});

module.exports = {
  startPayment,
  verifyPaymentController,
  getMyCoursesController,
};
