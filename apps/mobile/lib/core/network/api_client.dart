import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static const _storage = FlutterSecureStorage();

  // Mutualise les rafraîchissements concurrents : si plusieurs requêtes
  // essuient un 401 en même temps, un seul appel à /auth/refresh est émis.
  static Future<String?>? _refreshing;

  static void init() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isAuthRoute = error.requestOptions.path.contains('/auth/');
          if (error.response?.statusCode == 401 && !isAuthRoute) {
            final newAccessToken = await _refreshAccessToken();
            if (newAccessToken != null) {
              try {
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final response = await dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (_) {
                // Le retry a échoué : on laisse remonter l'erreur d'origine ci-dessous.
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  static Future<String?> _refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  static Future<String?> _doRefresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return null;

    try {
      // Dio "nu", sans les intercepteurs ci-dessus, pour éviter une boucle infinie.
      final bareDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
      final response = await bareDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      final newAccess = response.data['access_token'] as String?;
      final newRefresh = response.data['refresh_token'] as String?;
      if (newAccess == null) return null;

      await _storage.write(key: 'access_token', value: newAccess);
      if (newRefresh != null) {
        await _storage.write(key: 'refresh_token', value: newRefresh);
      }
      return newAccess;
    } catch (_) {
      // Refresh token expiré/invalide : on efface la session locale (l'utilisateur
      // sera redirigé vers l'écran de connexion au prochain appel qui vérifie l'auth).
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      return null;
    }
  }
}
