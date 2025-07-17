class ApiConfig {
  /// Base URL of the backend API. Update this value when deploying.
  static const String baseUrl = 'http://172.22.208.95:5000';

  /// Token sent in the `X-API-Token` header for authenticated requests.
  /// The same token must be provided to the backend via the `API_TOKEN`
  /// environment variable.
  static const String apiToken = 'changeme';
}
