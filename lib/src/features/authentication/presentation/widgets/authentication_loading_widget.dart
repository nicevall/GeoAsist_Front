// lib/src/features/authentication/presentation/widgets/authentication_loading_widget.dart
// Loading widget for authentication processes

import 'package:flutter/material.dart';

class AuthenticationLoadingWidget extends StatelessWidget {
  final String? message;
  final bool showLogo;
  
  const AuthenticationLoadingWidget({
    super.key,
    this.message,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showLogo) ...[
            const Icon(
              Icons.location_on,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
          ],
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}