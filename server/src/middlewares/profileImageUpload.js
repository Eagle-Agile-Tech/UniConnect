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

async function uploadProfileImageForUser({ userId, file }) {
  if (!userId) {
    throw new UnauthorizedError('Authentication required');
  }
  if (!file) {
    throw new AppError('Profile image file is required', 400, true, 'PROFILE_IMAGE_REQUIRED');
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
  const ext = path.extname(file.originalname || '').toLowerCase() || '.jpg';
  const objectPath = `profiles/${userId}/${Date.now()}-${crypto.randomUUID()}${ext}`;

  const { error } = await supabase.storage
    .from(bucket)
    .upload(objectPath, file.buffer, {
      contentType: file.mimetype,
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
  return data?.publicUrl || `${bucket}/${objectPath}`;
}

async function attachUploadedProfileImage(req, _res, next) {
  try {
    if (!req.file) return next();

    const userId = req.user?.id || req.user?.sub;
    const publicUrl = await uploadProfileImageForUser({ userId, file: req.file });
    req.body.profileImage = publicUrl;

    return next();
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  uploadProfileImage,
  uploadProfileImageForUser,
  attachUploadedProfileImage,
};
