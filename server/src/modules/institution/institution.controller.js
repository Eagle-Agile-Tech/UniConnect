const institutionService = require('./institution.service');

class InstitutionController {
  async registerInstitution(req, res, next) {
    try {
      const deviceInfo = {
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        device: req.headers['sec-ch-ua-platform'] || 'Unknown',
      };
      const result = await institutionService.registerInstitution(req.body, deviceInfo);
      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  }

  async verifyInstitutionOtp(req, res, next) {
    try {
      const result = await institutionService.verifyInstitutionOtp(req.body);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async resendInstitutionOtp(req, res, next) {
    try {
      const result = await institutionService.resendInstitutionOtp(req.body);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async listInstitutions(req, res, next) {
    try {
      const result = await institutionService.listInstitutions(req.query);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async getInstitution(req, res, next) {
    try {
      const { institutionId } = req.params;
      const result = await institutionService.getInstitution(institutionId);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async updateInstitution(req, res, next) {
    try {
      const { institutionId } = req.params;
      const actorId = req.user?.sub || req.user?.id;
      const isAdmin = req.user?.role === 'ADMIN';
      const result = await institutionService.updateInstitution(
        institutionId,
        req.body,
        actorId,
        isAdmin
      );
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async loginInstitution(req, res, next) {
    try {
      const deviceInfo = {
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        device: req.headers['sec-ch-ua-platform'] || 'Unknown',
      };
      const result = await institutionService.loginInstitution(req.body, deviceInfo);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async submitVerification(req, res, next) {
    try {
      const { institutionId } = req.params;
      const actorId = req.user?.sub || req.user?.id;
      const isAdmin = req.user?.role === 'ADMIN';
      const result = await institutionService.submitVerification(
        institutionId,
        req.body,
        actorId,
        isAdmin
      );
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async verifyInstitution(req, res, next) {
    try {
      const { institutionId } = req.params;
      const adminId = req.user?.sub || req.user?.id;
      const result = await institutionService.verifyInstitution(
        institutionId,
        req.body,
        adminId
      );
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async regenerateSecretCode(req, res, next) {
    try {
      const { institutionId } = req.params;
      const managerId = req.user?.sub || req.user?.id;
      const result = await institutionService.regenerateSecretCode(
        institutionId,
        managerId
      );
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  async inviteExpert(req, res, next) {
    try {
      const managerId = req.user?.sub || req.user?.id;
      const result = await institutionService.inviteExpert(req.body, managerId);
      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new InstitutionController();
