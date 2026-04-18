const zod = require('zod');


const zDate = zod.coerce.date();

const paginationSchema = {
  page: zod.coerce.number().int().positive().default(1),
  limit: zod.coerce.number().int().positive().default(10),
};


const createEventSchema = zod.object({
  title: zod.string().min(2).max(100),
  description: zod.string().max(255),

  starts: zDate,
  ends: zDate,
  eventDay: zDate,

  authorId: zod.string().min(1).optional(), // injected from authenticated user in controller
  university: zod.string().min(2).max(150),
  location: zod.string().max(255),

  views: zod.number().int().nonnegative().default(0),
  registrations: zod.number().int().nonnegative().default(0),

}).strict().superRefine((data, ctx) => {
  if (data.starts >= data.ends) {
    ctx.addIssue({
      code: zod.ZodIssueCode.custom,
      message: 'Start date must be before end date',
    });
  }
});

const updateEventSchema = zod.object({
  title: zod.string().min(2).max(100).optional(),
  description: zod.string().max(255).optional(),

  starts: zDate.optional(),
  ends: zDate.optional(),
  eventDay: zDate.optional(),

  university: zod.string().min(2).max(150).optional(),
  location: zod.string().max(255).optional(),

}).strict().superRefine((data, ctx) => {
  if (data.starts && data.ends && data.starts >= data.ends) {
    ctx.addIssue({
      code: zod.ZodIssueCode.custom,
      message: 'Start date must be before end date',
    });
  }

  if ((data.starts && !data.ends) || (!data.starts && data.ends)) {
    ctx.addIssue({
      code: zod.ZodIssueCode.custom,
      message: 'Both starts and ends must be provided together',
    });
  }
});

const getEventsQuerySchema = zod.object({
  search: zod.string().trim().min(1).max(100).optional(),
  university: zod.string().optional(),
  eventDay: zDate.optional(),
  authorId: zod.string().optional(),
  ...paginationSchema,
});

const trendingEventsQuerySchema = zod.object({
  university: zod.string().optional(),
  from: zDate.optional(),
  to: zDate.optional(),
  ...paginationSchema,
});

const getEventsByUserIdQuerySchema = zod.object({
  userId: zod.string().min(1),
  ...paginationSchema,
});

module.exports = {
  createEventSchema,
  updateEventSchema,
  getEventsQuerySchema,
  trendingEventsQuerySchema,
  getEventsByUserIdQuerySchema,
};
