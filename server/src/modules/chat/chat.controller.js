const chatService = require('./chat.service');

class ChatController {
  async createChat(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const chat = await chatService.createChat(userId, req.body);
      res.status(201).json(chat);
    } catch (err) {
      next(err);
    }
  }

  async listChats(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const chats = await chatService.listChats(userId, req.query);
      res.status(200).json(chats);
    } catch (err) {
      next(err);
    }
  }

  async getChatIdFromUserIds(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const otherUserId =
        req.params?.otherUserId ||
        req.params?.chatId ||
        req.query?.otherUserId;
      const chat = await chatService.getChatIdFromUserIds(userId, otherUserId);
      res.status(200).json(chat);
    } catch (err) {
      next(err);
    }
  }

  async updateGroupChat(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const chat = await chatService.updateGroupChat(userId, req.body);
      res.status(200).json(chat);
    } catch (err) {
      next(err);
    }
  }

  async addParticipant(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const chat = await chatService.addParticipant(userId, req.body);
      res.status(200).json(chat);
    } catch (err) {
      next(err);
    }
  }

  async removeParticipant(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const result = await chatService.removeParticipant(userId, req.body);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async listMessages(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const result = await chatService.listMessages(userId, req.query);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async sendMessage(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const message = await chatService.sendMessage(userId, req.body);
      res.status(201).json(message);
    } catch (err) {
      next(err);
    }
  }

  async updateMessage(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const message = await chatService.updateMessage(userId, req.body);
      res.status(200).json(message);
    } catch (err) {
      next(err);
    }
  }

  async deleteMessage(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const result = await chatService.deleteMessage(userId, req.body);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async markAsRead(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const result = await chatService.markAsRead(userId, req.body);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async markAsDelivered(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const result = await chatService.markAsDelivered(userId, req.body);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async reactToMessage(req, res, next) {
    try {
      const userId = req.user?.sub || req.user?.id;
      const reaction = await chatService.reactToMessage(userId, req.body);
      res.status(200).json(reaction);
    } catch (err) {
      next(err);
    }
  }

  async typing(req, res, next) {
    try {
      res.status(200).json({ message: 'Typing status received' });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new ChatController();
