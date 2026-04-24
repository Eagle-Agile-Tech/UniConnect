const { getSupabaseClient } = require("../../config/supabase");

class SupabaseStorageService {
  async uploadFile(file, userId, folder = "posts") {
    const supabase = getSupabaseClient();

    const filePath = `${folder}/${userId}/${Date.now()}-${file.originalname}`;

    const { error } = await supabase.storage
      .from("media") // your bucket name
      .upload(filePath, file.buffer, {
        contentType: file.mimetype,
        upsert: false,
      });

    if (error) {
      console.error("Supabase upload error:", error.message);
      throw new Error("File upload failed");
    }

    const { data } = supabase.storage.from("media").getPublicUrl(filePath);

    return {
      url: data.publicUrl,
      path: filePath,
    };
  }
}

module.exports = new SupabaseStorageService();
