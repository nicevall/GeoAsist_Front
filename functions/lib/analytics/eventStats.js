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
exports.getEventStatistics = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
/**
 * Get event statistics and analytics (simplified version)
 * Migrated from Node.js statistics endpoints
 */
exports.getEventStatistics = functions.https.onCall(async (data, context) => {
    try {
        // Validate authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated to access statistics');
        }
        const { eventId, detailed = false } = data;
        functions.logger.info("Fetching event statistics", {
            eventId,
            detailed,
            requesterId: context.auth.uid
        });
        if (eventId) {
            return await getSingleEventStats(eventId, detailed);
        }
        else {
            return await getAllEventsStats(detailed);
        }
    }
    catch (error) {
        functions.logger.error("Error fetching event statistics", error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to fetch event statistics');
    }
});
/**
 * Get statistics for a single event
 */
async function getSingleEventStats(eventId, detailed = false) {
    var _a, _b;
    const firestore = admin.firestore();
    const eventDoc = await firestore
        .collection('eventos')
        .doc(eventId)
        .get();
    if (!eventDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Event not found');
    }
    const eventData = eventDoc.data();
    // Get attendance records for this event
    const attendanceSnapshot = await firestore
        .collection('asistencias')
        .where('eventoId', '==', eventId)
        .get();
    const totalAttendees = attendanceSnapshot.size;
    const stats = {
        eventId: eventId,
        eventName: eventData.nombre || 'Sin nombre',
        eventDates: {
            start: eventData.fechaInicio,
            end: eventData.fechaFin
        },
        attendance: {
            total: totalAttendees,
            unique: totalAttendees, // Simplified - assume all are unique for now
        },
        location: {
            latitude: ((_a = eventData.ubicacion) === null || _a === void 0 ? void 0 : _a.latitud) || null,
            longitude: ((_b = eventData.ubicacion) === null || _b === void 0 ? void 0 : _b.longitud) || null,
            radius: eventData.radioMetros || 100
        },
        status: eventData.estado || 'desconocido',
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    };
    if (detailed) {
        const detailedRecords = attendanceSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                date: data.fecha || null,
                status: data.estado || 'presente'
            };
        });
        stats.detailed = {
            records: detailedRecords
        };
    }
    return stats;
}
/**
 * Get statistics for all events (simplified)
 */
async function getAllEventsStats(detailed = false) {
    const firestore = admin.firestore();
    const eventsSnapshot = await firestore.collection('eventos').get();
    const attendanceSnapshot = await firestore.collection('asistencias').get();
    const totalEvents = eventsSnapshot.size;
    const totalAttendanceRecords = attendanceSnapshot.size;
    const overallStats = {
        overview: {
            totalEvents,
            totalAttendanceRecords,
            avgAttendancePerEvent: totalEvents > 0 ? Math.round(totalAttendanceRecords / totalEvents) : 0
        },
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    };
    if (detailed) {
        const eventStats = eventsSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                eventId: doc.id,
                eventName: data.nombre || 'Sin nombre',
                status: data.estado || 'desconocido'
            };
        });
        overallStats.events = eventStats;
    }
    return overallStats;
}
//# sourceMappingURL=eventStats.js.map