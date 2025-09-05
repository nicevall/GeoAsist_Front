import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Send notification function
 * Migrated from /api/firestore/send-notification endpoint
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  try {
    // Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to send notifications'
      );
    }

    const { title, body, userId, tokens, eventId, type = 'general' } = data;

    // Validate required fields
    if (!title || !body) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Title and body are required'
      );
    }

    functions.logger.info("Processing notification request", {
      title,
      userId: context.auth.uid,
      type,
      eventId
    });

    let targetTokens: string[] = [];

    if (tokens && Array.isArray(tokens)) {
      targetTokens = tokens;
    } else if (userId) {
      // Get user FCM tokens from Firestore
      const userDoc = await admin.firestore()
        .collection('usuarios')
        .doc(userId)
        .get();
      
      if (userDoc.exists) {
        const userData = userDoc.data();
        targetTokens = userData?.fcmTokens || [];
      }
    } else {
      // Send to all users (admin only)
      const usersSnapshot = await admin.firestore()
        .collection('usuarios')
        .get();
      
      usersSnapshot.docs.forEach(doc => {
        const userData = doc.data();
        if (userData.fcmTokens) {
          targetTokens.push(...userData.fcmTokens);
        }
      });
    }

    if (targetTokens.length === 0) {
      functions.logger.warn("No FCM tokens found for notification");
      return { success: false, error: 'No valid tokens found' };
    }

    // Create notification payload
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type,
        eventId: eventId || '',
        timestamp: new Date().toISOString(),
        senderId: context.auth.uid
      },
      tokens: targetTokens
    };

    // Send multicast message
    const response = await admin.messaging().sendMulticast(message);
    
    // Log results
    functions.logger.info("Notification sent", {
      successCount: response.successCount,
      failureCount: response.failureCount,
      totalTokens: targetTokens.length
    });

    // Save notification record to Firestore
    const notificationRecord = {
      title,
      body,
      type,
      eventId: eventId || null,
      senderId: context.auth.uid,
      targetUserId: userId || null,
      tokensCount: targetTokens.length,
      successCount: response.successCount,
      failureCount: response.failureCount,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'sent'
    };

    await admin.firestore()
      .collection('notificaciones')
      .add(notificationRecord);

    return {
      success: true,
      messageId: `notification_${Date.now()}`,
      successCount: response.successCount,
      failureCount: response.failureCount,
      totalTokens: targetTokens.length
    };

  } catch (error) {
    functions.logger.error("Error sending notification", error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send notification'
    );
  }
});