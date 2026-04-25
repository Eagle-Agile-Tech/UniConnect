// server/src/modules/media/services/supabase-storage.service.js
const { getSupabaseClient } = require("../../../config/supabase");
const crypto = require("crypto");

class SupabaseStorageService {
  constructor() {
    this.bucketName =
      process.env.SUPABASE_MEDIA_BUCKET || process.env.SUPABASE_BUCKET || "media";
  }

  /**
   * Check if Supabase is configured
   */
  isConfigured() {
    if (process.env.SKIP_SUPABASE) return false;
    return Boolean(
      process.env.SUPABASE_URL &&
        (process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY),
    );
  }

  /**
   * Upload file to Supabase Storage
   */
  async uploadFile(file, userId) {
    console.log(`📤 Starting upload for: ${file.originalname}`);

    // Mock storage for development
    if (!this.isConfigured() || process.env.MOCK_STORAGE === "true") {
      console.log("📁 Using mock storage");
      return {
        path: `mock/${userId}/${file.originalname}`,
        url: `https://mock-storage.com/${userId}/${Date.now()}-${file.originalname}`,
        size: file.size,
        mimetype: file.mimetype,
      };
    }

    try {
      const supabase = getSupabaseClient();

      // Generate unique filename
      const fileExt = file.originalname.split(".").pop();
      const fileName = `${userId}/${Date.now()}-${crypto.randomUUID()}.${fileExt}`;
      const filePath = `posts/${fileName}`;

      // Upload to Supabase
      const { data, error } = await supabase.storage
        .from(this.bucketName)
        .upload(filePath, file.buffer, {
          contentType: file.mimetype,
          cacheControl: "3600",
          upsert: false,
        });

      if (error) {
        console.error("Supabase upload error:", error);
        if (error.message === "Bucket not found") {
          throw new Error(
            `Failed to upload file: Bucket '${this.bucketName}' not found. Set SUPABASE_MEDIA_BUCKET to an existing bucket or create it in Supabase Storage.`,
          );
        }
        throw new Error(`Failed to upload file: ${error.message}`);
      }

      // Get public URL
      const {
        data: { publicUrl },
      } = supabase.storage.from(this.bucketName).getPublicUrl(filePath);

      return {
        path: filePath,
        url: publicUrl,
        size: file.size,
        mimetype: file.mimetype,
      };
    } catch (error) {
      console.error("Upload error:", error);
      throw error;
    }
  }

  /**
   * Upload multiple files
   */
  async uploadMultipleFiles(files, userId) {
    console.log(`📤 uploadMultipleFiles called with ${files.length} files`);

    const uploadPromises = files.map(async (file) => {
      console.log(
        `Uploading file: ${file.originalname}, size: ${file.size}, type: ${file.mimetype}`,
      );

      try {
        const result = await this.uploadFile(file, userId);
        console.log(`✅ File uploaded successfully: ${result.url}`);
        return result;
      } catch (error) {
        console.error(`❌ Failed to upload ${file.originalname}:`, error);
        throw error;
      }
    });

    return await Promise.all(uploadPromises);
  }

  /**
   * Delete file from Supabase
   */
  async deleteFile(filePath) {
    if (!this.isConfigured()) {
      console.log("📁 Mock delete:", filePath);
      return true;
    }

    try {
      const supabase = getSupabaseClient();

      const { error } = await supabase.storage
        .from(this.bucketName)
        .remove([filePath]);

      if (error) {
        console.error("Supabase delete error:", error);
        throw error;
      }

      return true;
    } catch (error) {
      console.error("Delete error:", error);
      throw error;
    }
  }

  /**
   * Extract file path from URL
   */
  extractFilePathFromUrl(url) {
    try {
      const urlObj = new URL(url);
      const pathParts = urlObj.pathname.split("/");
      const bucketIndex = pathParts.indexOf(this.bucketName);

      if (bucketIndex !== -1) {
        return pathParts.slice(bucketIndex + 1).join("/");
      }

      return null;
    } catch (error) {
      console.error("Error extracting file path:", error);
      return null;
    }
  }
}

module.exports = new SupabaseStorageService();
