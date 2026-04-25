const prisma = require("../../lib/prisma");

const REPORT_THRESHOLD = 2;

/**
 * Create report
 */
const createReport = async (data) => {
  const { reporterId, targetType, targetId, reason, message } = data;

  if (!reporterId) throw new Error("Missing reporterId");

  const existing = await prisma.report.findFirst({
    where: { reporterId, targetId, targetType },
  });

  if (existing) return { message: "Already reported" };

  const report = await prisma.report.create({
    data: {
      reporterId,
      targetType,
      targetId,
      reason,
      message,
    },
  });

  const count = await prisma.report.count({
    where: { targetType, targetId },
  });

  if (count >= 2) {
    await prisma.report.updateMany({
      where: { targetType, targetId },
      data: { isFlagged: true },
    });
  }

  return report;
};
/**
 * Cancel report (only owner)
 */
const cancelReport = async ({ reporterId, targetType, targetId }) => {
  const report = await prisma.report.findFirst({
    where: {
      reporterId,
      targetType,
      targetId,
    },
  });

  if (!report) {
    return { message: "Report not found" };
  }

  await prisma.report.delete({
    where: { id: report.id },
  });

  return { message: "Report cancelled" };
};

/**
 * Get flagged reports (admin)
 */
const getFlaggedReports = async () => {
  return await prisma.report.findMany({
    where: { isFlagged: true },
    orderBy: { createdAt: "desc" },
  });
};

/**
 * Get reports for specific target
 */
const getReportsByTarget = async (targetType, targetId) => {
  return await prisma.report.findMany({
    where: {
      targetType,
      targetId,
    },
    orderBy: {
      createdAt: "desc",
    },
  });
};

module.exports = {
  createReport,
  cancelReport,
  getFlaggedReports,
  getReportsByTarget,
};
