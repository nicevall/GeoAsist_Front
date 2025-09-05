import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Process attendance based on geofencing
 * Migrated from Node.js backend geofencing logic
 */
export const processAttendance = functions.https.onCall(async (data, context) => {
  try {
    // Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to process attendance'
      );
    }

    const { latitude, longitude, eventId, action = 'checkin' } = data;

    // Validate required fields
    if (!latitude || !longitude) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Latitude and longitude are required'
      );
    }

    const userId = context.auth.uid;
    
    functions.logger.info("Processing attendance", {
      userId,
      latitude,
      longitude,
      eventId,
      action
    });

    // Get active events if no specific eventId provided
    let targetEvents: any[] = [];
    
    if (eventId) {
      const eventDoc = await admin.firestore()
        .collection('eventos')
        .doc(eventId)
        .get();
      
      if (eventDoc.exists) {
        targetEvents.push({ id: eventDoc.id, ...eventDoc.data() });
      }
    } else {
      // Get all active events
      const now = new Date();
      const eventsSnapshot = await admin.firestore()
        .collection('eventos')
        .where('estado', '==', 'activo')
        .where('fechaInicio', '<=', now)
        .where('fechaFin', '>=', now)
        .get();
      
      targetEvents = eventsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    }

    if (targetEvents.length === 0) {
      return {
        success: false,
        message: 'No active events found',
        attendanceProcessed: false
      };
    }

    const attendanceResults: any[] = [];

    // Process each event
    for (const event of targetEvents) {
      const distance = calculateDistance(
        latitude, longitude,
        event.ubicacion.latitud, event.ubicacion.longitud
      );

      const isInRange = distance <= (event.radioMetros || 100); // Default 100m radius
      
      functions.logger.info("Distance calculation", {
        eventId: event.id,
        distance,
        radius: event.radioMetros || 100,
        inRange: isInRange
      });

      if (isInRange) {
        // Check if attendance already exists
        const existingAttendance = await admin.firestore()
          .collection('asistencias')
          .where('usuarioId', '==', userId)
          .where('eventoId', '==', event.id)
          .where('fecha', '>=', getStartOfDay())
          .where('fecha', '<=', getEndOfDay())
          .get();

        let attendanceRecord;

        if (existingAttendance.empty) {
          // Create new attendance record
          attendanceRecord = {
            usuarioId: userId,
            eventoId: event.id,
            eventoNombre: event.nombre,
            fecha: admin.firestore.FieldValue.serverTimestamp(),
            horaEntrada: admin.firestore.FieldValue.serverTimestamp(),
            horaSalida: null,
            ubicacionEntrada: {
              latitud: latitude,
              longitud: longitude,
              precision: data.accuracy || null
            },
            ubicacionSalida: null,
            distanciaMetros: Math.round(distance),
            estado: 'presente',
            tipo: action,
            metadata: {
              deviceInfo: data.deviceInfo || null,
              timestamp: new Date().toISOString()
            }
          };

          const attendanceRef = await admin.firestore()
            .collection('asistencias')
            .add(attendanceRecord);

          attendanceResults.push({
            eventId: event.id,
            eventName: event.nombre,
            attendanceId: attendanceRef.id,
            action: 'checkin',
            distance: Math.round(distance),
            status: 'success'
          });

        } else {
          // Update existing attendance (checkout)
          const existingDoc = existingAttendance.docs[0];
          const updateData: any = {};

          if (action === 'checkout') {
            updateData.horaSalida = admin.firestore.FieldValue.serverTimestamp();
            updateData.ubicacionSalida = {
              latitud: latitude,
              longitud: longitude,
              precision: data.accuracy || null
            };
          }

          await existingDoc.ref.update(updateData);

          attendanceResults.push({
            eventId: event.id,
            eventName: event.nombre,
            attendanceId: existingDoc.id,
            action: action,
            distance: Math.round(distance),
            status: 'updated'
          });
        }
      } else {
        attendanceResults.push({
          eventId: event.id,
          eventName: event.nombre,
          distance: Math.round(distance),
          radius: event.radioMetros || 100,
          status: 'out_of_range'
        });
      }
    }

    const successfulAttendances = attendanceResults.filter(r => 
      r.status === 'success' || r.status === 'updated'
    );

    functions.logger.info("Attendance processing completed", {
      userId,
      totalEvents: targetEvents.length,
      successfulAttendances: successfulAttendances.length,
      results: attendanceResults
    });

    return {
      success: successfulAttendances.length > 0,
      attendanceProcessed: successfulAttendances.length > 0,
      processedEvents: successfulAttendances.length,
      totalEvents: targetEvents.length,
      results: attendanceResults,
      message: successfulAttendances.length > 0 
        ? `Attendance recorded for ${successfulAttendances.length} event(s)`
        : 'No events in range for attendance'
    };

  } catch (error) {
    functions.logger.error("Error processing attendance", error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to process attendance'
    );
  }
});

/**
 * Calculate distance between two coordinates using Haversine formula
 */
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3; // Earth's radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) *
    Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

/**
 * Get start of current day
 */
function getStartOfDay(): Date {
  const date = new Date();
  date.setHours(0, 0, 0, 0);
  return date;
}

/**
 * Get end of current day
 */
function getEndOfDay(): Date {
  const date = new Date();
  date.setHours(23, 59, 59, 999);
  return date;
}