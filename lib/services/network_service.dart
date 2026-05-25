import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // Debug logging only
    // Auto disabled in release builds
    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint(
              'REQUEST: ${options.method} '
              '${options.uri}',
            );
            handler.next(options);
          },
          onError: (error, handler) {
            debugPrint(
              'ERROR: ${error.message}',
            );
            handler.next(error);
          },
        ),
      );
    }

    // BUG 21 fix: Firebase token refresh
    // on 401 unauthorized
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              // Refresh Firebase token
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await user.getIdToken(true);
                // Retry original request
                final opts = error.requestOptions;
                final response = await dio.fetch(opts);
                handler.resolve(response);
                return;
              }
            } catch (_) {}
          }
          handler.next(error);
        },
      ),
    );

    // Retry interceptor for network errors
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final options = error.requestOptions;
          final retryCount = options.extra['retryCount'] ?? 0;

          if (retryCount < 3 &&
              (error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.receiveTimeout ||
                  error.type == DioExceptionType.connectionError)) {
            options.extra['retryCount'] = retryCount + 1;

            await Future.delayed(
              Duration(seconds: retryCount + 1),
            );

            try {
              final response = await dio.fetch(options);
              handler.resolve(response);
              return;
            } catch (_) {}
          }
          handler.next(error);
        },
      ),
    );
  }
}
