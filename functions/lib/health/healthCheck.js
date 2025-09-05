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
exports.healthCheck = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
/**
 * Health check function to verify system status
 * Migrated from /api/firestore/health endpoint
 */
exports.healthCheck = functions.https.onRequest(async (req, res) => {
    try {
        functions.logger.info("Health check initiated");
        // Test Firestore connection
        const testDoc = await admin.firestore().collection('system').doc('health').get();
        // Test FCM service
        const messagingActive = admin.messaging() !== null;
        const healthStatus = {
            success: true,
            system: 'firebase_cloud_functions',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            services: {
                firestore: testDoc ? 'active' : 'inactive',
                fcm: messagingActive ? 'active' : 'inactive',
                functions: 'active',
                auth: admin.auth() ? 'active' : 'inactive'
            },
            version: '2.0.0',
            migration: 'node_to_firebase_complete'
        };
        functions.logger.info("Health check completed successfully", healthStatus);
        // Set CORS headers
        res.set('Access-Control-Allow-Origin', '*');
        res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        res.status(200).json(healthStatus);
    }
    catch (error) {
        functions.logger.error("Health check failed", error);
        res.status(500).json({
            success: false,
            system: 'firebase_cloud_functions',
            error: 'Health check failed',
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
    }
});
//# sourceMappingURL=healthCheck.js.map