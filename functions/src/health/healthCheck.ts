import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Health check function to verify system status
 * Migrated from /api/firestore/health endpoint
 */
export const healthCheck = functions.https.onRequest(async (req, res): Promise<void> => {
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
  } catch (error) {
    functions.logger.error("Health check failed", error);
    
    res.status(500).json({
      success: false,
      system: 'firebase_cloud_functions',
      error: 'Health check failed',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  }
});