const adminService = require('./admin.service');
const { uploadProfileImageForUser } = require('../../middlewares/profileImageUpload');

class AdminController {
    async loginAdmin(req, res, next) {
        const deviceInfo = {
            ip: req.ip,
            userAgent: req.headers['user-agent'],
            device: req.headers['sec-ch-ua-platform'] || 'Unknown'
        };

        const result = await adminService.loginAdmin(req.body, deviceInfo);
        res.status(200).json(result);
    }

    async createAdmin(req, res, next) {
        const adminId = req.user?.sub || req.user?.id;
        let result = await adminService.createAdmin(req.body, adminId);

        if (req.file) {
            const profileImage = await uploadProfileImageForUser({
                userId: result.id,
                file: req.file
            });
            result = await adminService.updateAdminProfile(result.id, { profileImage });
        }

        res.status(201).json(result);
    }

    async refreshToken(req, res, next) {
        const { refreshToken } = req.body;
        const result = await adminService.refreshAdminToken(refreshToken);
        res.status(200).json(result);
    }

    async logout(req, res, next) {
        const { refreshToken } = req.body;
        const result = await adminService.logoutAdmin(refreshToken);
        res.status(200).json(result);
    }

    async verifyAccount(req, res, next) {
        const adminId = req.user?.sub || req.user?.id;
        const { userId } = req.params;
        const { status, rejectionReason } = req.body;
        const result = await adminService.verifyAccount(adminId, userId, status, rejectionReason);
        res.status(200).json(result);
    }

    async getProfile(req, res, next) {
        const adminId = req.user?.sub || req.user?.id;
        const result = await adminService.adminProfile(adminId);
        res.status(200).json(result);
    }

    async updateProfile(req, res, next) {
        const adminId = req.user?.sub || req.user?.id;
        let payload = req.body;
        if (req.file) {
            const profileImage = await uploadProfileImageForUser({
                userId: adminId,
                file: req.file
            });
            payload = { ...req.body, profileImage };
        }
        const result = await adminService.updateAdminProfile(adminId, payload);
        res.status(200).json(result);
    }

    async moderateContent(req, res, next) {
        const adminId = req.user?.sub || req.user?.id;
        const { contentId, contentType, action, reason } = req.body;
        const result = await adminService.moderateContent(
            adminId,
            contentId,
            contentType,
            action,
            reason
        );
        res.status(200).json(result);
    }

    async getModerationQueue(req, res, next) {
        const adminId = req.user?.sub || req.user?.id;
        const { contentType, status, page, limit } = req.query;
        const result = await adminService.getModerationQueue(
            adminId,
            contentType,
            status,
            page ? Number(page) : undefined,
            limit ? Number(limit) : undefined
        );
        res.status(200).json(result);
    }

    async getUnverifiedUsers(req, res, next) {
        const adminId = req.user?.sub || req.user?.id;
        const { page, limit } = req.query;
        const result = await adminService.getUnverifiedUsers(
            adminId,
            page ? Number(page) : undefined,
            limit ? Number(limit) : undefined
        );
        res.status(200).json(result);
    }
    async listUserProfiles(req, res, next) {
        const adminId = req.user?.sub || req.user?.id;
        const result = await adminService.listUserProfiles(adminId, {
            ...req.query,
        });
        res.status(200).json(result);
    }

    async getDashboardStats(req, res, next) {
        const adminId = req.user?.sub || req.user?.id;
        const result = await adminService.getDashboardStats(adminId);
        res.status(200).json(result);
    }
}

module.exports = new AdminController();
