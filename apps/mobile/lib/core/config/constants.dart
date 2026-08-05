class AppConstants {
  static const String appName = 'LocaDirect CM';

  /// URL de base de l'API. `localhost` fonctionne dans tous les cas d'usage
  /// actuels du projet :
  /// - Desktop (Linux/macOS/Windows), iOS Simulator, Web : direct, l'app tourne
  ///   sur la même machine que l'API.
  /// - Android (émulateur OU appareil physique en USB) : nécessite un tunnel
  ///   `adb reverse tcp:3000 tcp:3000` (à relancer à chaque connexion USB) —
  ///   plus fiable que l'alias `10.0.2.2` qui ne marche que sur l'émulateur
  ///   par défaut d'Android Studio, pas sur un appareil physique.
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';

  // Specifics Cameroon
  static const String currencySymbol = 'FCFA';
  static const String currencyCode = 'XAF';
  static const int defaultVisitFeeXAF = 2000;
  static const int minAgentPayoutXAF = 5000;

  // Key Cities
  static const List<String> supportedCities = ['Douala', 'Yaoundé'];

  /// Web Client ID Google OAuth (type "Application Web" dans Google Cloud Console).
  /// Nécessaire même sur Android : c'est l'audience contre laquelle le backend
  /// vérifie l'idToken (`serverClientId` passé à GoogleSignIn). Le client Android
  /// (package + SHA-1) est enregistré séparément côté Google et détecté
  /// automatiquement par le plugin — il n'a pas besoin d'être codé ici.
  ///
  /// Package Android à enregistrer dans Google Cloud Console (OAuth Client ID
  /// type "Android") : cm.locadirect.locadirect_mobile
  static const String googleWebClientId =
      '730615905965-truni6i06cvkt6n9hijehubj1q7l3n7m.apps.googleusercontent.com';

  /// Client ID Google OAuth type "iOS" (Google Cloud Console). Contrairement à
  /// Android, iOS a besoin de ce client id explicitement côté Dart (passé à
  /// `GoogleSignIn(clientId: ...)` dans auth_repository.dart) ET du schéma
  /// d'URL "reversed" correspondant déclaré dans ios/Runner/Info.plist
  /// (clé CFBundleURLTypes — voir le commentaire à cet endroit du fichier).
  ///
  /// Bundle ID à enregistrer dans Google Cloud Console (OAuth Client ID type
  /// "iOS") : cm.locadirect.locadirectMobile (ATTENTION : différent du
  /// package Android, pas de underscore ici — c'est le vrai identifiant iOS
  /// tel que défini dans ios/Runner.xcodeproj).
  static const String googleIosClientId =
      '730615905965-0vut1a0ponpgt1fragt1plgcaao80s52.apps.googleusercontent.com';

  static bool get isGoogleSignInConfigured => googleWebClientId.isNotEmpty;
}
