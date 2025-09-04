// lib/src/core/network/network_info.dart
// Network connectivity information service

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectionStream;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  
  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result.isNotEmpty && !result.contains(ConnectivityResult.none);
  }

  @override
  Stream<bool> get connectionStream {
    return connectivity.onConnectivityChanged.map(
      (result) => result.isNotEmpty && !result.contains(ConnectivityResult.none),
    );
  }
}