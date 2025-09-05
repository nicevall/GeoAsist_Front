import * as functions from "firebase-functions";

/**
 * Standardized response helper for Cloud Functions
 */
export class ResponseHelper {
  
  /**
   * Create success response
   */
  static success(data: any, message?: string) {
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
  static error(message: string, code?: string, details?: any) {
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
  static validationError(field: string, message: string) {
    return this.error(
      `Validation failed: ${message}`, 
      'VALIDATION_ERROR', 
      { field: field }
    );
  }

  /**
   * Create unauthorized response
   */
  static unauthorized(message: string = 'Authentication required') {
    return this.error(message, 'UNAUTHORIZED');
  }

  /**
   * Create forbidden response
   */
  static forbidden(message: string = 'Access denied') {
    return this.error(message, 'FORBIDDEN');
  }

  /**
   * Create not found response
   */
  static notFound(resource: string = 'Resource') {
    return this.error(`${resource} not found`, 'NOT_FOUND');
  }

  /**
   * Create rate limit response
   */
  static rateLimited(message: string = 'Rate limit exceeded') {
    return this.error(message, 'RATE_LIMITED');
  }
}

/**
 * Error handler for Cloud Functions
 */
export class ErrorHandler {
  
  /**
   * Handle and format errors consistently
   */
  static handle(error: any, context?: string): never {
    functions.logger.error(`Error in ${context || 'function'}:`, error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Map common error types
    if (error.code === 'auth/user-not-found') {
      throw new functions.https.HttpsError(
        'not-found',
        'User not found'
      );
    }

    if (error.code === 'permission-denied') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Insufficient permissions'
      );
    }

    if (error.code === 'not-found') {
      throw new functions.https.HttpsError(
        'not-found',
        'Resource not found'
      );
    }

    // Generic internal error
    throw new functions.https.HttpsError(
      'internal',
      'An internal error occurred'
    );
  }

  /**
   * Validate required fields
   */
  static validateRequired(data: any, requiredFields: string[]): void {
    for (const field of requiredFields) {
      if (!data[field] && data[field] !== 0 && data[field] !== false) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Missing required field: ${field}`
        );
      }
    }
  }

  /**
   * Validate user authentication
   */
  static validateAuth(context: functions.https.CallableContext): string {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }
    return context.auth.uid;
  }

  /**
   * Validate user role/permissions
   */
  static async validateRole(userId: string, allowedRoles: string[]): Promise<void> {
    const admin = await import('firebase-admin');
    
    try {
      const userDoc = await admin.firestore()
        .collection('usuarios')
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'User profile not found'
        );
      }

      const userData = userDoc.data()!;
      const userRole = userData.role || 'student';

      if (!allowedRoles.includes(userRole)) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Insufficient role permissions'
        );
      }
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        'internal',
        'Failed to validate user role'
      );
    }
  }
}