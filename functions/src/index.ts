import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Import function modules
import { healthCheck } from "./health/healthCheck";
import { sendNotification } from "./notifications/sendNotification";
import { processAttendance } from "./geofencing/processAttendance";
import { syncUserData } from "./auth/userSync";
import { getEventStatistics } from "./analytics/eventStats";

// Export all Cloud Functions
export {
  healthCheck,
  sendNotification,
  processAttendance,
  syncUserData,
  getEventStatistics,
};