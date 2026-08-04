import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  final String baseUrl;
  final List<String> allowedDomains;
  final String environment;
  final String securityKey;

  //============================== Singleton ==============================
  // Holds the single instance of AppEnv
  static AppEnv? _instance;

  // Accessor for the singleton instance. Ensure `init` is called first.
  static AppEnv get instance =>
      _instance ??
      (throw StateError(
          'AppEnv is not initialized. Call AppEnv.init(env) first.'));

  // Initialize the singleton based on an environment string.
  // Usage: await AppEnv.init('dev' | 'staging' | 'prod');
  static Future<AppEnv> init(String env) async {
    _instance = await AppEnv.fromEnvironment(env);
    return _instance!;
  }

  // Private constructor
  AppEnv._(
      this.baseUrl, this.allowedDomains, this.environment, this.securityKey);

  // Development configuration
  static Future<AppEnv> dev() async {
    await dotenv.load(fileName: 'assets/env/.env.dev');
    return AppEnv._(
      dotenv.env['BASE_URL'] ?? 'https://dev-api.yourdomain.com',
      (dotenv.env['ALLOWED_DOMAINS'] ?? 'localhost,dev.yourdomain.com')
          .split(',')
          .map((domain) => domain.trim())
          .toList(),
      'development',
      dotenv.env['SECURITY_KEY'] ?? '',
    );
  }

  // Staging configuration
  static Future<AppEnv> staging() async {
    await dotenv.load(fileName: 'assets/env/.env.staging');
    return AppEnv._(
      dotenv.env['BASE_URL'] ?? 'https://staging-api.yourdomain.com',
      (dotenv.env['ALLOWED_DOMAINS'] ?? 'staging.yourdomain.com')
          .split(',')
          .map((domain) => domain.trim())
          .toList(),
      'staging',
      dotenv.env['SECURITY_KEY'] ?? '',
    );
  }

  // Production configuration
  static Future<AppEnv> production() async {
    await dotenv.load(fileName: 'assets/env/.env.production');
    return AppEnv._(
      dotenv.env['BASE_URL'] ?? 'https://api.yourdomain.com',
      (dotenv.env['ALLOWED_DOMAINS'] ?? 'yourdomain.com,api.yourdomain.com')
          .split(',')
          .map((domain) => domain.trim())
          .toList(),
      'production',
      dotenv.env['SECURITY_KEY'] ?? '',
    );
  }

  // Convenience method to create config based on environment string
  static Future<AppEnv> fromEnvironment(String env) async {
    switch (env.toLowerCase()) {
      case 'development':
      case 'dev':
        return AppEnv.dev();
      case 'staging':
      case 'stage':
        return AppEnv.staging();
      case 'production':
      case 'prod':
        return AppEnv.production();
      default:
        return AppEnv.dev(); // Default to development
    }
  }

  // Helper method to check if a domain is allowed
  bool isDomainAllowed(String domain) {
    final lowerDomain = domain.toLowerCase();
    return allowedDomains.any((allowedDomain) =>
        lowerDomain == allowedDomain.toLowerCase() ||
        lowerDomain.endsWith('.$allowedDomain'.toLowerCase()));
  }

  // Helper method to build full URL
  String buildUrl(String endpoint) {
    // Remove leading slash from endpoint
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

    // Remove trailing slash from baseUrl if present
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return '$cleanBaseUrl/$cleanEndpoint';
  }

  @override
  String toString() {
    return 'AppConfig(environment: $environment, baseUrl: $baseUrl, allowedDomains: $allowedDomains)';
  }
}
