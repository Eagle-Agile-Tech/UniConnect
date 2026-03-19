const zod = require('zod');

const createInstitutionSchema = zod.object({
    name: zod.string().min(2, 'name is required').max(150),
    type: zod.enum([
        'UNIVERSITY',
        'COMPANY',
        'NGO',
        'RESEARCH_CENTER',
        'TRAINING_CENTER',
        'GOVERNMENT',
        'OTHER',
    ]),
    description: zod.string().max(1000).optional(),
    website: zod.string().url().optional(),
    logoUri: zod.string().url().optional(),
}).strict();

const updateInstitutionSchema = zod.object({
    name: zod.string().min(2).max(150).optional(),
    type: zod.enum([
        'UNIVERSITY',
        'COMPANY',
        'NGO',
        'RESEARCH_CENTER',
        'TRAINING_CENTER',
        'GOVERNMENT',
        'OTHER',
    ]).optional(),
    description: zod.string().max(1000).optional(),
    website: zod.string().url().optional(),
    logoUri: zod.string().url().optional(),
}).strict().superRefine((data, ctx) => {
    const hasAny =
        data.name ||
        data.type ||
        data.description ||
        data.website ||
        data.logoUri;
    if (!hasAny) {
        ctx.addIssue({
            code: zod.ZodIssueCode.custom,
            message: 'At least one field must be provided',
            path: ['name'],
        });
    }
});

const institutionIdParamSchema = zod.object({
    institutionId: zod.string().uuid('Valid institutionId is required'),
}).strict();

const loginInstitutionSchema = zod.object({
    email: zod.string().email('Invalid email address').trim().toLowerCase(),
    password: zod.string().min(8).max(100),
}).strict();

const submitInstitutionVerificationSchema = zod.object({
    documentUrl: zod.string().url().optional(),
    verificationDocument: zod.string().url().optional(),
}).strict().superRefine((data, ctx) => {
    if (!data.documentUrl && !data.verificationDocument) {
        ctx.addIssue({
            code: zod.ZodIssueCode.custom,
            message: 'documentUrl is required',
            path: ['documentUrl'],
        });
    }
});

const verifyInstitutionSchema = zod.object({
    status: zod.enum(['APPROVED', 'REJECTED']),
    rejectionReason: zod.string().max(300).optional(),
}).strict().superRefine((data, ctx) => {
    if (data.status === 'REJECTED' && !data.rejectionReason?.trim()) {
        ctx.addIssue({
            code: zod.ZodIssueCode.custom,
            message: 'rejectionReason is required when status is REJECTED',
            path: ['rejectionReason'],
        });
    }
});

const regenerateSecretCodeSchema = zod.object({}).strict().default({});

const inviteExpertSchema = zod.object({
    institutionId: zod.string().uuid('Valid institutionId is required'),
    email: zod.string().email('Invalid email address').trim().toLowerCase(),
}).strict();

const acceptExpertInvitationSchema = zod.object({
    token: zod.string().min(1, 'token is required'),
    firstName: zod.string().min(1).max(100).optional(),
    lastName: zod.string().min(1).max(100).optional(),
    password: zod.string().min(8).max(100).optional(),
}).strict();

const joinInstitutionSchema = zod.object({
    institutionName: zod.string().min(2, 'institutionName is required').max(150),
    secretCode: zod.string().min(4, 'secretCode is required').max(32),
}).strict();

const listInstitutionsSchema = zod.object({
    page: zod.string().regex(/^\d+$/).optional(),
    limit: zod.string().regex(/^\d+$/).optional(),
    search: zod.string().max(100).optional(),
    verified: zod.coerce.boolean().optional(),
    type: zod.enum([
        'UNIVERSITY',
        'COMPANY',
        'NGO',
        'RESEARCH_CENTER',
        'TRAINING_CENTER',
        'GOVERNMENT',
        'OTHER',
    ]).optional(),
}).strict();

module.exports = {
    createInstitutionSchema,
    updateInstitutionSchema,
    institutionIdParamSchema,
    loginInstitutionSchema,
    submitInstitutionVerificationSchema,
    verifyInstitutionSchema,
    regenerateSecretCodeSchema,
    inviteExpertSchema,
    acceptExpertInvitationSchema,
    joinInstitutionSchema,
    listInstitutionsSchema,
};
