// server/src/config/supabase.js
const { createClient } = require("@supabase/supabase-js");

// Try to load from parent directory if not found in current
require("dotenv").config({
  path: require("path").join(__dirname, "../../.env"),
});

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

console.log("🔍 Checking Supabase config:");
console.log("- SUPABASE_URL:", supabaseUrl ? "✅ Found" : "❌ Missing");
console.log(
  "- SUPABASE_SERVICE_KEY:",
  supabaseServiceKey ? "✅ Found" : "❌ Missing",
);

if (!supabaseUrl || !supabaseServiceKey) {
  console.warn(
    "⚠️  Supabase URL and Service Key are missing. Using MOCK storage!",
  );
  console.warn(
    "Expected .env file at:",
    require("path").join(__dirname, "../../.env"),
  );

  // Export mock client
  module.exports = {
    storage: {
      from: () => ({
        upload: async (path, file, options) => {
          console.log("📁 MOCK upload:", path);
          return { data: { path }, error: null };
        },
        getPublicUrl: (path) => ({
          data: {
            publicUrl: `https://mock-storage.uniconnect.local/${path}`,
          },
        }),
        remove: async (paths) => {
          console.log("📁 MOCK delete:", paths);
          return { data: {}, error: null };
        },
      }),
    },
  };
} else {
  console.log("✅ Supabase configured successfully");
  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  module.exports = supabase;
}
