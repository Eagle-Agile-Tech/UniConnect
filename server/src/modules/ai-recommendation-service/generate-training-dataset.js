const fs = require("fs");
const path = require("path");

const trainingDatasetService = require("./training-dataset.service");

// ----------------------
// CLI Helpers
// ----------------------
function getArg(flag, defaultValue = undefined) {
  const index = process.argv.indexOf(flag);
  if (index === -1 || index === process.argv.length - 1) return defaultValue;
  return process.argv[index + 1];
}

function hasFlag(flag) {
  return process.argv.includes(flag);
}

function parseList(value) {
  if (!value) return [];
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function parseNumber(value, fallback) {
  const num = Number(value);
  return Number.isFinite(num) && num > 0 ? num : fallback;
}

function parseNonNegativeInt(value, fallback) {
  const num = Number.parseInt(String(value ?? ""), 10);
  return Number.isFinite(num) && num >= 0 ? num : fallback;
}

// ----------------------
// Main Runner
// ----------------------
async function main() {
  try {
    // 🎛️ Parse CLI options
    const format = (getArg("--format", "json") || "json").toLowerCase();
    const output = getArg("--output", null);
    const aggregate = !hasFlag("--raw");
    const negativesPerPositive = parseNonNegativeInt(getArg("--negatives-per-positive"), 1);

    const days = parseNumber(getArg("--days"), undefined);
    const limit = parseNumber(getArg("--limit"), 5000);
    const targetTypes = parseList(getArg("--target-types"));

    // 🧪 Validate format
    if (!["json", "jsonl"].includes(format)) {
      throw new Error(`Invalid format "${format}". Use "json" or "jsonl".`);
    }

    console.log("⚙️ Generating training dataset...");
    console.log(
      JSON.stringify(
        {
          format,
          aggregate,
          days: days ?? "all",
          limit,
          targetTypes,
          negativesPerPositive: aggregate ? negativesPerPositive : 0,
        },
        null,
        2
      )
    );

    // 🚀 Generate dataset
    const dataset = await trainingDatasetService.generateDataset({
      aggregate,
      days,
      limit,
      targetTypes,
      negativesPerPositive,
    });

    // 📦 Format output
    const body =
      format === "jsonl"
        ? trainingDatasetService.toJsonl(dataset.rows)
        : JSON.stringify(dataset, null, 2);

    // 💾 Save or print
    if (output) {
      const resolvedPath = path.resolve(output);
      fs.writeFileSync(resolvedPath, body, "utf8");

      console.log(`\n✅ Dataset written to: ${resolvedPath}`);
      console.log(
        `📊 Rows: ${dataset.rows.length} | Interactions: ${dataset.summary.totalInteractions}`
      );
    } else {
      process.stdout.write(body);
    }

    // 🧠 Helpful hint
    if (dataset.rows.length <= 1 && aggregate) {
      console.warn(
        "\n⚠️ Warning: Very few rows generated in aggregated mode.\n" +
          "This usually means low data diversity (same user/target).\n" +
          "Try --raw or improve seed data."
      );
    }
  } catch (error) {
    console.error("\n❌ Failed to generate training dataset:");
    console.error(error.message || error);
    process.exit(1);
  }
}

// ----------------------
// Execute
// ----------------------
main();
