const path = require('path');
const crypto = require('crypto');
const multer = require('multer');
const { AppError } = require('../errors');
const { getSupabaseClient } = require('../config/supabase');

const fileFilter = (_req, file, cb) => {
  if (file.mimetype?.startsWith('image/')) return cb(null, true);
  return cb(new Error('Only image files are allowed'));
};

const uploadIdVerificationDocument = multer({
  storage: multer.memoryStorage(),
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
    files: 2,
  },
}).fields([
  { name: 'documentFrontImage', maxCount: 1 },
  { name: 'documentBackImage', maxCount: 1 },
]);

async function attachUploadedDocumentImage(req, _res, next) {
  try {
    const files = req.files || {};
    const frontFile = files.documentFrontImage?.[0];
    const backFile = files.documentBackImage?.[0];
    if (!frontFile && !backFile) return next();

    const supabase = getSupabaseClient();
    if (!supabase) {
      throw new AppError(
        'Supabase storage is not configured',
        503,
        true,
        'STORAGE_NOT_CONFIGURED'
      );
    }

    const bucket = process.env.SUPABASE_ID_VERIFICATION_BUCKET || 'id-verifications';

    const uploadImage = async (file) => {
      if (!file) return undefined;
      const ext = path.extname(file.originalname || '').toLowerCase() || '.jpg';
      const objectPath = `${Date.now()}-${crypto.randomUUID()}${ext}`;
      const { error } = await supabase.storage
        .from(bucket)
        .upload(objectPath, file.buffer, {
          contentType: file.mimetype,
          upsert: false,
        });
      if (error) {
        throw new AppError(
          'Failed to upload verification document',
          503,
          true,
          'STORAGE_UPLOAD_FAILED'
        );
      }
      const { data } = supabase.storage.from(bucket).getPublicUrl(objectPath);
      return data?.publicUrl || `${bucket}/${objectPath}`;
    };

    const [frontUrl, backUrl] = await Promise.all([
      uploadImage(frontFile),
      uploadImage(backFile),
    ]);

    if (frontUrl) req.body.documentFrontImage = frontUrl;
    if (backUrl) req.body.documentBackImage = backUrl;

    return next();
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  uploadIdVerificationDocument,
  attachUploadedDocumentImage,
};
