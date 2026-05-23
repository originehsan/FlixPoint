// New file: lib/services/network_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  late final Dio dio;

  void initialize() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Logging interceptor (debug only)
    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('REQUEST: ${options.method} ${options.uri}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              'RESPONSE: ${response.statusCode} ${response.requestOptions.uri}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint('ERROR: ${error.message}');
            handler.next(error);
          },
        ),
      );
    }

    // Retry interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final options = error.requestOptions;
          final retryCount = options.extra['retryCount'] ?? 0;

          // Retry up to 3 times on network errors
          if (retryCount < 3 &&
              (error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.receiveTimeout ||
                  error.type == DioExceptionType.connectionError)) {
            options.extra['retryCount'] = retryCount + 1;

            // Wait before retry
            await Future.delayed(
              Duration(seconds: retryCount + 1),
            );

            try {
              final response = await dio.fetch(options);
              handler.resolve(response);
              return;
            } catch (e) {
              // Continue to error handler
            }
          }
          handler.next(error);
        },
      ),
    );
  }
}