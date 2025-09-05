"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ErrorHandler = exports.ResponseHelper = void 0;
const functions = __importStar(require("firebase-functions"));
/**
 * Standardized response helper for Cloud Functions
 */
class ResponseHelper {
    /**
     * Create success response
     */
    static success(data, message) {
        return {
            success: true,
            data: data,
            message: message || 'Operation completed successfully',
            timestamp: new Date().toISOString()
        };
    }
    /**
     * Create error response
     */
    static error(message, code, details) {
        return {
            success: false,
            error: {
                message: message,
                code: code || 'UNKNOWN_ERROR',
                details: details || null
            },
            timestamp: new Date().toISOString()
        };
    }
    /**
     * Create validation error response
     */
    static validationError(field, message) {
        return this.error(`Validation failed: ${message}`, 'VALIDATION_ERROR', { field: field });
    }
    /**
     * Create unauthorized response
     */
    static unauthorized(message = 'Authentication required') {
        return this.error(message, 'UNAUTHORIZED');
    }
    /**
     * Create forbidden response
     */
    static forbidden(message = 'Access denied') {
        return this.error(message, 'FORBIDDEN');
    }
    /**
     * Create not found response
     */
    static notFound(resource = 'Resource') {
        return this.error(`${resource} not found`, 'NOT_FOUND');
    }
    /**
     * Create rate limit response
     */
    static rateLimited(message = 'Rate limit exceeded') {
        return this.error(message, 'RATE_LIMITED');
    }
}
exports.ResponseHelper = ResponseHelper;
/**
 * Error handler for Cloud Functions
 */
class ErrorHandler {
    /**
     * Handle and format errors consistently
     */
    static handle(error, context) {
        functions.logger.error(`Error in ${context || 'function'}:`, error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        // Map common error types
        if (error.code === 'auth/user-not-found') {
            throw new functions.https.HttpsError('not-found', 'User not found');
        }
        if (error.code === 'permission-denied') {
            throw new functions.https.HttpsError('permission-denied', 'Insufficient permissions');
        }
        if (error.code === 'not-found') {
            throw new functions.https.HttpsError('not-found', 'Resource not found');
        }
        // Generic internal error
        throw new functions.https.HttpsError('internal', 'An internal error occurred');
    }
    /**
     * Validate required fields
     */
    static validateRequired(data, requiredFields) {
        for (const field of requiredFields) {
            if (!data[field] && data[field] !== 0 && data[field] !== false) {
                throw new functions.https.HttpsError('invalid-argument', `Missing required field: ${field}`);
            }
        }
    }
    /**
     * Validate user authentication
     */
    static validateAuth(context) {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        return context.auth.uid;
    }
    /**
     * Validate user role/permissions
     */
    static async validateRole(userId, allowedRoles) {
        const admin = await Promise.resolve().then(() => __importStar(require('firebase-admin')));
        try {
            const userDoc = await admin.firestore()
                .collection('usuarios')
                .doc(userId)
                .get();
            if (!userDoc.exists) {
                throw new functions.https.HttpsError('not-found', 'User profile not found');
            }
            const userData = userDoc.data();
            const userRole = userData.role || 'student';
            if (!allowedRoles.includes(userRole)) {
                throw new functions.https.HttpsError('permission-denied', 'Insufficient role permissions');
            }
        }
        catch (error) {
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            throw new functions.https.HttpsError('internal', 'Failed to validate user role');
        }
    }
}
exports.ErrorHandler = ErrorHandler;
//# sourceMappingURL=responseHelper.js.map