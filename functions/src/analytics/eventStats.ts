import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Get event statistics and analytics (simplified version)
 * Migrated from Node.js statistics endpoints
 */
export const getEventStatistics = functions.https.onCall(async (data, context) => {
  try {
    // Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to access statistics'
      );
    }

    const { eventId, detailed = false } = data;

    functions.logger.info("Fetching event statistics", {
      eventId,
      detailed,
      requesterId: context.auth.uid
    });

    if (eventId) {
      return await getSingleEventStats(eventId, detailed);
    } else {
      return await getAllEventsStats(detailed);
    }

  } catch (error) {
    functions.logger.error("Error fetching event statistics", error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch event statistics'
    );
  }
});

/**
 * Get statistics for a single event
 */
async function getSingleEventStats(eventId: string, detailed: boolean = false): Promise<any> {
  const firestore = admin.firestore();
  
  const eventDoc = await firestore
    .collection('eventos')
    .doc(eventId)
    .get();

  if (!eventDoc.exists) {
    throw new functions.https.HttpsError(
      'not-found',
      'Event not found'
    );
  }

  const eventData = eventDoc.data()!;

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
      latitude: eventData.ubicacion?.latitud || null,
      longitude: eventData.ubicacion?.longitud || null,
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
    
    (stats as any).detailed = {
      records: detailedRecords
    };
  }

  return stats;
}

/**
 * Get statistics for all events (simplified)
 */
async function getAllEventsStats(detailed: boolean = false): Promise<any> {
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
    
    (overallStats as any).events = eventStats;
  }

  return overallStats;
}