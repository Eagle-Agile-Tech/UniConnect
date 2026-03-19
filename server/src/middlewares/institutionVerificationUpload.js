const path = require('path');
const crypto = require('crypto');
const multer = require('multer');
const { AppError } = require('../errors');
const { getSupabaseClient } = require('../config/supabase');

const fileFilter = (_req, file, cb) => {
  const allowedMimeTypes = new Set([
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ]);

  if (file.mimetype?.startsWith('image/')) return cb(null, true);
  if (allowedMimeTypes.has(file.mimetype)) return cb(null, true);
  return cb(new Error('Only image, PDF, or Word files are allowed'));
};

const uploadInstitutionVerificationDocument = multer({
  storage: multer.memoryStorage(),
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
    files: 1,
  },
}).fields([
  { name: 'documentImage', maxCount: 1 },
  { name: 'verificationDocument', maxCount: 1 },
  { name: 'document', maxCount: 1 },
]);

async function attachUploadedInstitutionDocument(req, _res, next) {
  try {
    const files = req.files || {};
    const file =
      files.documentImage?.[0] ||
      files.verificationDocument?.[0] ||
      files.document?.[0];

    if (!file) return next();

    const supabase = getSupabaseClient();
    if (!supabase) {
      throw new AppError(
        'Supabase storage is not configured',
        503,
        true,
        'STORAGE_NOT_CONFIGURED'
      );
    }

    const bucket = process.env.SUPABASE_INSTITUTION_VERIFICATION_BUCKET || 'id-verifications';
    const ext = path.extname(file.originalname || '').toLowerCase() || '.jpg';
    const institutionId = req.params?.institutionId || 'unknown';
    const objectPath = `institutions/${institutionId}/${Date.now()}-${crypto.randomUUID()}${ext}`;

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
    req.body.documentUrl = data?.publicUrl || `${bucket}/${objectPath}`;

    return next();
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  uploadInstitutionVerificationDocument,
  attachUploadedInstitutionDocument,
};
