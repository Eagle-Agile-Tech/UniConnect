const path = require('path');
const crypto = require('crypto');
const multer = require('multer');
const { AppError, UnauthorizedError } = require('../errors');
const { getSupabaseClient } = require('../config/supabase');

const fileFilter = (_req, file, cb) => {
  if (file.mimetype?.startsWith('image/')) return cb(null, true);
  return cb(new Error('Only image files are allowed'));
};

const uploadProfileImage = multer({
  storage: multer.memoryStorage(),
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
    files: 1,
  },
}).single('profileImage');

async function attachUploadedProfileImage(req, _res, next) {
  try {
    if (!req.file) return next();

    const userId = req.user?.id;
    if (!userId) {
      throw new UnauthorizedError('Authentication required');
    }

    const supabase = getSupabaseClient();
    if (!supabase) {
      throw new AppError(
        'Supabase storage is not configured',
        503,
        true,
        'STORAGE_NOT_CONFIGURED'
      );
    }

    const bucket = process.env.SUPABASE_PROFILE_BUCKET || 'profile-images';
    const ext = path.extname(req.file.originalname || '').toLowerCase() || '.jpg';
    const objectPath = `profiles/${userId}/${Date.now()}-${crypto.randomUUID()}${ext}`;

    const { error } = await supabase.storage
      .from(bucket)
      .upload(objectPath, req.file.buffer, {
        contentType: req.file.mimetype,
        upsert: false,
      });

    if (error) {
      throw new AppError(
        'Failed to upload profile image',
        503,
        true,
        'STORAGE_UPLOAD_FAILED'
      );
    }

    const { data } = supabase.storage.from(bucket).getPublicUrl(objectPath);
    req.body.profileImage = data?.publicUrl || `${bucket}/${objectPath}`;

    return next();
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  uploadProfileImage,
  attachUploadedProfileImage,
};
