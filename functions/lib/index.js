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
exports.getEventStatistics = exports.syncUserData = exports.processAttendance = exports.sendNotification = exports.healthCheck = void 0;
const admin = __importStar(require("firebase-admin"));
// Initialize Firebase Admin
admin.initializeApp();
// Import function modules
const healthCheck_1 = require("./health/healthCheck");
Object.defineProperty(exports, "healthCheck", { enumerable: true, get: function () { return healthCheck_1.healthCheck; } });
const sendNotification_1 = require("./notifications/sendNotification");
Object.defineProperty(exports, "sendNotification", { enumerable: true, get: function () { return sendNotification_1.sendNotification; } });
const processAttendance_1 = require("./geofencing/processAttendance");
Object.defineProperty(exports, "processAttendance", { enumerable: true, get: function () { return processAttendance_1.processAttendance; } });
const userSync_1 = require("./auth/userSync");
Object.defineProperty(exports, "syncUserData", { enumerable: true, get: function () { return userSync_1.syncUserData; } });
const eventStats_1 = require("./analytics/eventStats");
Object.defineProperty(exports, "getEventStatistics", { enumerable: true, get: function () { return eventStats_1.getEventStatistics; } });
//# sourceMappingURL=index.js.map