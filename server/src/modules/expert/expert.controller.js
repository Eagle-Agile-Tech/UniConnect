const expertService = require('./expert.service');

class ExpertController {
  async login(req, res, next) {
    try {
      const deviceInfo = {
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        device: req.headers['sec-ch-ua-platform'] || 'Unknown',
      };

      const result = await expertService.login(req.body, deviceInfo);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async acceptInvitation(req, res, next) {
    try {
      const result = await expertService.acceptInvitation(req.body);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async joinInstitution(req, res, next) {
    try {
      const result = await expertService.joinInstitution(req.body);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async getProfile(req, res, next) {
    try {
      const expertId = req.user?.sub || req.user?.id;
      const result = await expertService.getProfile(expertId);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async updateProfile(req, res, next) {
    try {
      const expertId = req.user?.sub || req.user?.id;
      const result = await expertService.updateProfile(expertId, req.body);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async deleteProfile(req, res, next) {
    try {
      const expertId = req.user?.sub || req.user?.id;
      const result = await expertService.deleteProfile(expertId);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new ExpertController();
