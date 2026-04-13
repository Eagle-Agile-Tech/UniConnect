const prisma = require('../../lib/prisma');
const { ForbiddenError } = require('../../errors');
const { createEventSchema, updateEventSchema } = require('./event.schema');

class EventService {
  //  Utility

  async getEventOrThrow(id) {
    const event = await prisma.event.findUnique({ where: { id } });

    if (!event) {
      throw new Error('Event not found');
    }

    return event;
  }

  async getEventOwnedOrThrow(id, userId) {
    const event = await this.getEventOrThrow(id);

    if (event.authorId !== userId) {
      throw new ForbiddenError('Only the event creator can perform this action');
    }

    return event;
  }

  //  Create Event

  async createEvent(data) {
    const parsedData = createEventSchema.parse(data);

    return prisma.event.create({
      data: parsedData,
    });
  }

  // Get Event by ID (NO side effects)

  async getEventById(id) {
    return this.getEventOrThrow(id);
  }

  //  Track View (NEW - clean way)

  async viewEvent(eventId, userId = null) {
    await this.getEventOrThrow(eventId);

    // If user provided → prevent duplicate views
    if (userId) {
      const existing = await prisma.eventView.findUnique({
        where: {
          eventId_userId: {
            eventId,
            userId,
          },
        },
      });

      if (!existing) {
        await prisma.$transaction([
          prisma.event.update({
            where: { id: eventId },
            data: {
              views: { increment: 1 },
            },
          }),
          prisma.eventView.create({
            data: { eventId, userId },
          }),
        ]);
      }
    } else {
      // anonymous view
      await prisma.event.update({
        where: { id: eventId },
        data: {
          views: { increment: 1 },
        },
      });
    }

    return this.getEventOrThrow(eventId);
  }

  //  Get Events by Owner (Private)
 
  async getEventsByUserId(userId, page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    const [events, total] = await Promise.all([
      prisma.event.findMany({
        where: { authorId: userId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.event.count({
        where: { authorId: userId },
      }),
    ]);

    return {
      data: events,
      meta: {
        total,
        page,
        lastPage: Math.ceil(total / limit),
      },
    };
  }

  // Public Events by User

  async getPublicEventsByUser(userId, page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    const [events, total] = await Promise.all([
      prisma.event.findMany({
        where: {
          authorId: userId,
          // visibility: 'PUBLIC'
        },
        skip,
        take: limit,
        orderBy: { eventDay: 'asc' },
      }),
      prisma.event.count({
        where: { authorId: userId },
      }),
    ]);

    return {
      data: events,
      meta: {
        total,
        page,
        lastPage: Math.ceil(total / limit),
      },
    };
  }

  //  Get All Events
  
  async getAllEvents(page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    const [events, total] = await Promise.all([
      prisma.event.findMany({
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.event.count(),
    ]);

    return {
      data: events,
      meta: {
        total,
        page,
        lastPage: Math.ceil(total / limit),
      },
    };
  }

  //  Smart Trending Events
 
  async getTrendingEvents(page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    const events = await prisma.event.findMany({
      take: limit * 5,
    });

    const now = new Date();

    const scored = events.map(event => {
      const ageInDays =
        (now - new Date(event.eventDay)) / (1000 * 60 * 60 * 24);

      const recencyScore = Math.exp(-ageInDays / 7);

      const engagementScore =
        event.views * 0.2 +
        event.registrations * 0.8;

      const score = engagementScore * recencyScore;

      return { ...event, score };
    });

    scored.sort((a, b) => b.score - a.score);

    return {
      data: scored.slice(skip, skip + limit),
      meta: {
        page,
        limit,
      },
    };
  }

  //  Update Event
 
  async updateEvent(id, data, userId) {
    await this.getEventOwnedOrThrow(id, userId);

    const parsedData = updateEventSchema.parse(data);

    return prisma.event.update({
      where: { id },
      data: parsedData,
    });
  }

  //  Delete Event

  async deleteEvent(id, userId, role) {
    const event = await this.getEventOrThrow(id);

    if (event.authorId !== userId && role !== 'ADMIN') {
      throw new ForbiddenError('Only the event creator or an admin can delete this event');
    }

    return prisma.event.delete({
      where: { id },
    });
  }

  // Event Stats
 
  async getEventStats() {
    const now = new Date();

    const [total, aggregate, upcoming, past] = await Promise.all([
      prisma.event.count(),
      prisma.event.aggregate({
        _sum: {
          views: true,
          registrations: true,
        },
      }),
      prisma.event.count({
        where: { eventDay: { gte: now } },
      }),
      prisma.event.count({
        where: { eventDay: { lt: now } },
      }),
    ]);

    return {
      totalEvents: total,
      totalViews: aggregate._sum.views || 0,
      totalRegistrations: aggregate._sum.registrations || 0,
      upcomingEvents: upcoming,
      pastEvents: past,
    };
  }

  // Register for Event (Atomic + Safe)
 
  async registerForEvent(eventId, userId) {
    await this.getEventOrThrow(eventId);

    const existing = await prisma.eventRegistration.findUnique({
      where: {
        eventId_userId: {
          eventId,
          userId,
        },
      },
    });

    if (existing) {
      throw new Error('User already registered for this event');
    }

    // 🧠 transaction = no partial updates
    const [registration] = await prisma.$transaction([
      prisma.eventRegistration.create({
        data: { eventId, userId },
      }),
      prisma.event.update({
        where: { id: eventId },
        data: {
          registrations: {
            increment: 1,
          },
        },
      }),
    ]);

    return registration;
  }

  // Cancel Registration

  async cancelRegistration(eventId, userId) {
    await this.getEventOrThrow(eventId);

    const existing = await prisma.eventRegistration.findUnique({
      where: {
        eventId_userId: {
          eventId,
          userId,
        },
      },
    });

    if (!existing) {
      throw new Error('User is not registered for this event');
    }

    const [registration] = await prisma.$transaction([
      prisma.eventRegistration.delete({
        where: {
          eventId_userId: {
            eventId,
            userId,
          },
        },
      }),
      prisma.event.update({
        where: { id: eventId },
        data: {
          registrations: {
            decrement: 1,
          },
        },
      }),
    ]);

    return registration;
  }
}

module.exports = new EventService();
