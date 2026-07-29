class AppConstants {
  static const String appName = 'LocaDirect CM';
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api/v1';

  // Specifics Cameroon
  static const String currencySymbol = 'FCFA';
  static const String currencyCode = 'XAF';
  static const int defaultVisitFeeXAF = 2000;
  static const int minAgentPayoutXAF = 5000;

  // Key Cities
  static const List<String> supportedCities = ['Douala', 'Yaoundé'];
}
