const userService = require('./user.service');

class UserController {
  async checkUsernameAvailability(req, res, next) {
    try {
      const { username } = req.query;
      const result = await userService.checkUsernameAvailability(username);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async createUserProfile(req, res, next) {
    try {
      const userId = req.user?.id;
      const profile = await userService.createUser(userId, req.body);
      res.status(201).json(profile);
    } catch (err) {
      next(err);
    }
  }

  async getUserProfile(req, res, next) {
    try {
      const userId = req.user?.id;
      const profile = await userService.getUserProfile(userId);
      res.status(200).json(profile);
    } catch (err) {
      next(err);
    }
  }

  async searchUsernames(req, res, next) {
    try {
      const { username } = req.params;
      const userId = req.user?.id;
      const profiles = await userService.searchUsernames(username, userId);
      res.status(200).json(profiles);
    } catch (err) {
      next(err);
    }
  }

  async updateUserProfile(req, res, next) {
    try {
      const userId = req.user?.id;
      const profile = await userService.updateUserProfile(userId, req.body);
      res.status(200).json(profile);
    } catch (err) {
      next(err);
    }
  }

  async updateProfileImage(req, res, next) {
    try {
      const userId = req.user?.id;
      const profile = await userService.updateProfileImage(userId, req.body.profileImage);
      res.status(200).json(profile);
    } catch (err) {
      next(err);
    }
  }

  async deleteUserProfile(req, res, next) {
    try {
      const userId = req.user?.id;
      const result = await userService.deleteUserProfile(userId);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async listUserProfiles(req, res, next) {
    try {
      const userId = req.user?.id;
      const result = await userService.listUserProfiles({
        ...req.query,
        currentUserId: userId,
      });
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new UserController();
