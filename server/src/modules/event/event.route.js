const express = require('express');

const eventController = require('./event.controller');
const validateRequest = require('../../middlewares/validateRequest');
const authenticate = require('../../middlewares/authMiddleware');
const {
  createEventSchema,
  updateEventSchema,
  getEventsQuerySchema,
  trendingEventsQuerySchema,
} = require('./event.schema');

const router = express.Router();

// PUBLIC ROUTES


// Get all events
router.get(
  '/',
  validateRequest(getEventsQuerySchema, 'query'),
  eventController.getAllEvents
);

// Trending events
router.get(
  '/trending',
  validateRequest(trendingEventsQuerySchema, 'query'),
  eventController.getTrendingEvents
);

// Public user events
router.get('/user/:userId', eventController.getPublicUserEvents);

// Stats
router.get('/stats', eventController.getEventStats);

// My events
router.get(
  '/me',
  authenticate,
  validateRequest(getEventsQuerySchema, 'query'),
  eventController.getEventsByUserId
);

// Get single event
router.get('/:id', eventController.getEventById);

//  AUTHENTICATED ROUTES

router.use(authenticate);

// View event (NEW)
router.post('/:id/view', eventController.viewEvent);

// Register for event (NEW)
router.post('/:id/register', eventController.registerForEvent);

// Cancel registration
router.post('/:id/cancel-registration', eventController.cancelRegistration);

// Create event
router.post(
  '/',
  validateRequest(createEventSchema),
  eventController.createEvent
);

// Update event
router.patch(
  '/:id',
  validateRequest(updateEventSchema),
  eventController.updateEvent
);

// Delete event
router.delete('/:id', eventController.deleteEvent);

module.exports = router;
