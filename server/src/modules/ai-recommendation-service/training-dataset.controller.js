const trainingDatasetService = require("./training-dataset.service");

function parseBoolean(value, fallback) {
  if (value === undefined) return fallback;
  if (typeof value === "boolean") return value;
  return String(value).toLowerCase() !== "false";
}

function parseCsv(value) {
  if (!value) return [];
  return String(value)
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

class TrainingDatasetController {
  async generate(req, res) {
    const format = (req.query.format || "json").toLowerCase();
    const aggregate = parseBoolean(req.query.aggregate, true);

    const dataset = await trainingDatasetService.generateDataset({
      format,
      aggregate,
      limit: req.query.limit,
      days: req.query.days,
      targetTypes: parseCsv(req.query.targetTypes),
      userIds: parseCsv(req.query.userIds),
    });

    if (format === "jsonl") {
      const filename = `training-dataset-${new Date().toISOString().replace(/[:.]/g, "-")}.jsonl`;
      res.setHeader("Content-Type", "application/x-ndjson; charset=utf-8");
      res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
      return res.status(200).send(trainingDatasetService.toJsonl(dataset.rows));
    }

    return res.status(200).json(dataset);
  }
}

module.exports = new TrainingDatasetController();
