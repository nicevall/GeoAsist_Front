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
exports.cleanupUserData = exports.syncUserData = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
/**
 * Sync user data when new user is created
 * Replaces Node.js user management endpoints
 */
exports.syncUserData = functions.auth.user().onCreate(async (user) => {
    try {
        functions.logger.info("New user created", {
            uid: user.uid,
            email: user.email,
            displayName: user.displayName
        });
        // Create user document in Firestore
        const userRecord = {
            uid: user.uid,
            email: user.email || null,
            displayName: user.displayName || 'Usuario',
            photoURL: user.photoURL || null,
            emailVerified: user.emailVerified,
            role: 'student',
            estado: 'activo',
            fechaCreacion: admin.firestore.FieldValue.serverTimestamp(),
            ultimoLogin: admin.firestore.FieldValue.serverTimestamp(),
            configuraciones: {
                notificacionesEnabled: true,
                ubicacionEnabled: false,
                temaOscuro: false
            },
            estadisticas: {
                eventosAsistidos: 0,
                horasAcumuladas: 0,
                racha: 0
            },
            fcmTokens: [],
            metadata: {
                createdBy: 'firebase_auth',
                version: '2.0.0'
            }
        };
        await admin.firestore()
            .collection('usuarios')
            .doc(user.uid)
            .set(userRecord);
        // Send welcome notification
        try {
            const welcomeNotification = {
                title: '¡Bienvenido a GeoAsist!',
                body: 'Tu cuenta ha sido creada exitosamente. Comienza a registrar tu asistencia.',
                type: 'welcome',
                userId: user.uid,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                status: 'pending'
            };
            await admin.firestore()
                .collection('notificaciones')
                .add(welcomeNotification);
            functions.logger.info("Welcome notification queued for user", { uid: user.uid });
        }
        catch (notificationError) {
            functions.logger.warn("Failed to queue welcome notification", notificationError);
        }
        functions.logger.info("User data sync completed successfully", {
            uid: user.uid,
            email: user.email
        });
        return { success: true, uid: user.uid };
    }
    catch (error) {
        functions.logger.error("Error syncing user data", {
            uid: user.uid,
            error: error
        });
        // Don't throw error to avoid blocking user creation
        return { success: false, error: 'Failed to sync user data' };
    }
});
/**
 * Handle user deletion
 */
exports.cleanupUserData = functions.auth.user().onDelete(async (user) => {
    try {
        functions.logger.info("User deleted, cleaning up data", {
            uid: user.uid,
            email: user.email
        });
        const batch = admin.firestore().batch();
        // Delete user document
        const userRef = admin.firestore().collection('usuarios').doc(user.uid);
        batch.delete(userRef);
        // Clean up user's attendance records
        const attendanceSnapshot = await admin.firestore()
            .collection('asistencias')
            .where('usuarioId', '==', user.uid)
            .get();
        attendanceSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        // Clean up user's notifications
        const notificationsSnapshot = await admin.firestore()
            .collection('notificaciones')
            .where('targetUserId', '==', user.uid)
            .get();
        notificationsSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        await batch.commit();
        functions.logger.info("User data cleanup completed", {
            uid: user.uid,
            attendanceRecords: attendanceSnapshot.size,
            notifications: notificationsSnapshot.size
        });
        return { success: true, uid: user.uid };
    }
    catch (error) {
        functions.logger.error("Error cleaning up user data", {
            uid: user.uid,
            error: error
        });
        return { success: false, error: 'Failed to cleanup user data' };
    }
});
//# sourceMappingURL=userSync.js.map