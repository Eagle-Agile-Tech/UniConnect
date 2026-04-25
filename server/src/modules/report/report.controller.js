const service = require("./report.service");

/**
 * Create report
 */
const createReport = async (req, res) => {
  const reporterId = req.user.sub;

  const result = await service.createReport({
    ...req.body,
    reporterId,
  });

  res.json(result);
};

/**
 * Cancel report
 */
const cancelReport = async (req, res) => {
  const reporterId = req.user.sub;

  const { targetType, targetId } = req.body;

  const result = await service.cancelReport({
    reporterId,
    targetType,
    targetId,
  });

  res.json(result);
};
/**
 * Get flagged reports (admin)
 */
const getFlaggedReports = async (req, res) => {
  const result = await service.getFlaggedReports();
  res.json(result);
};

/**
 * Get reports by target
 */
const getReportsByTarget = async (req, res) => {
  const { targetType, targetId } = req.params;

  const result = await service.getReportsByTarget(targetType, targetId);
  res.json(result);
};

module.exports = {
  createReport,
  cancelReport,
  getFlaggedReports,
  getReportsByTarget,
};
