const { createClient } = require('@supabase/supabase-js');

let supabase = null;

function getSupabaseClient() {
  if (supabase) return supabase;

  const supabaseUrl = process.env.SUPABASE_URL;

  // support BOTH env names (important for compatibility)
  const supabaseKey =
    process.env.SUPABASE_SERVICE_KEY ||
    process.env.SUPABASE_SERVICE_ROLE_KEY;

  console.log("🔍 Checking Supabase config:");
  console.log("- SUPABASE_URL:", supabaseUrl ? "✅ Found" : "❌ Missing");
  console.log("- SUPABASE_KEY:", supabaseKey ? "✅ Found" : "❌ Missing");

  if (!supabaseUrl || !supabaseKey) {
    console.warn("⚠️ Supabase not configured. Using MOCK storage!");

    // return mock instead of real client
    return {
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
  }

  console.log("✅ Supabase configured successfully");

  supabase = createClient(supabaseUrl, supabaseKey);
  return supabase;
}

module.exports = {
  getSupabaseClient,
};