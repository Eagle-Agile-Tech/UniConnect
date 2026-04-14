const eventService = require("./event.service");

class EventController {
  //  Create Event
 
  async createEvent(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;

      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const eventPayload = { ...req.body, authorId: userId };

      const event = await eventService.createEvent(eventPayload);

      res.status(201).json({
        status: "success",
        data: event,
      });
    } catch (error) {
      next(error);
    }
  }

  //  Get Event by ID

  async getEventById(req, res, next) {
    try {
      const event = await eventService.getEventById(req.params.id);

      res.status(200).json({
        status: "success",
        data: event,
      });
    } catch (error) {
      next(error);
    }
  }

  //  View Event (NEW)
 
  async viewEvent(req, res, next) {
    try {
      const userId = req.user?.id || req.user?.sub;

      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const event = await eventService.viewEvent(
        req.params.id,
        userId
      );

      res.status(200).json({
        status: "success",
        data: event,
      });
    } catch (error) {
      next(error);
    }
  }

  //  Register for Event (NEW)
 
  async registerForEvent(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;

      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const result = await eventService.registerForEvent(
        req.params.id,
        userId
      );

      res.status(201).json({
        status: "success",
        message: "Successfully registered",
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  //  Cancel Registration

  async cancelRegistration(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;

      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const result = await eventService.cancelRegistration(
        req.params.id,
        userId
      );

      res.status(200).json({
        status: "success",
        message: "Registration cancelled",
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  //  My Events
 
  async getEventsByUserId(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;

      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;

      const events = await eventService.getEventsByUserId(
        userId,
        page,
        limit
      );

      res.status(200).json({
        status: "success",
        ...events,
      });
    } catch (error) {
      next(error);
    }
  }

  //  Public User Events
 
  async getPublicUserEvents(req, res, next) {
    try {
      const { userId } = req.params;

      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;

      const events = await eventService.getPublicEventsByUser(
        userId,
        page,
        limit
      );

      res.status(200).json({
        status: "success",
        ...events,
      });
    } catch (error) {
      next(error);
    }
  }

  //  Get All Events
 
  async getAllEvents(req, res, next) {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;

      const events = await eventService.getAllEvents(page, limit);

      res.status(200).json({
        status: "success",
        ...events,
      });
    } catch (error) {
      next(error);
    }
  }

  //  Trending
 
  async getTrendingEvents(req, res, next) {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;

      const events = await eventService.getTrendingEvents(page, limit);

      res.status(200).json({
        status: "success",
        ...events,
      });
    } catch (error) {
      next(error);
    }
  }

  //  Stats

  async getEventStats(req, res, next) {
    try {
      const stats = await eventService.getEventStats();

      res.status(200).json({
        status: "success",
        data: stats,
      });
    } catch (error) {
      next(error);
    }
  }

  //  Update Event
  
  async updateEvent(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;

      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const updated = await eventService.updateEvent(
        req.params.id,
        req.body,
        userId
      );

      res.status(200).json({
        status: "success",
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  //  Delete Event
  
  async deleteEvent(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const role = req.user?.role;

      if (!userId) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      await eventService.deleteEvent(req.params.id, userId, role);

      res.status(200).json({
        status: "success",
        message: "Event deleted successfully",
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new EventController();
