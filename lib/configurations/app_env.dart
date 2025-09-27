import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  final String baseUrl;
  final List<String> allowedDomains;
  final String environment;
  
  //============================== Singleton ==============================
  // Holds the single instance of AppEnv
  static AppEnv? _instance;
  
  // Accessor for the singleton instance. Ensure `init` is called first.
  static AppEnv get instance => _instance ??
      (throw StateError('AppEnv is not initialized. Call AppEnv.init(env) first.'));
  
  // Initialize the singleton based on an environment string.
  // Usage: await AppEnv.init('dev' | 'staging' | 'prod');
  static Future<AppEnv> init(String env) async {
    _instance = await AppEnv.fromEnvironment(env);
    return _instance!;
  }

  // Private constructor
  AppEnv._(
    this.baseUrl,
    this.allowedDomains,
    this.environment,
  );

  // Development configuration
  static Future<AppEnv> dev() async {
    await dotenv.load(fileName: '.env.development');
    return AppEnv._(
      DotEnv().env['BASE_URL'] ?? 'https://dev-api.yourdomain.com',
      (DotEnv().env['ALLOWED_DOMAINS'] ?? 'localhost,dev.yourdomain.com')
          .split(',')
          .map((domain) => domain.trim())
          .toList(),
      'development',
    );
  }

  // Staging configuration
  static Future<AppEnv> staging() async {
    await dotenv.load(fileName: '.env.staging');
    return AppEnv._(
      DotEnv().env['BASE_URL'] ?? 'https://staging-api.yourdomain.com',
      (DotEnv().env['ALLOWED_DOMAINS'] ?? 'staging.yourdomain.com')
          .split(',')
          .map((domain) => domain.trim())
          .toList(),
      'staging',
    );
  }

  // Production configuration
  static Future<AppEnv> production() async {
    await dotenv.load(fileName: '.env.production');
    return AppEnv._(
      DotEnv().env['BASE_URL'] ?? 'https://api.yourdomain.com',
      (DotEnv().env['ALLOWED_DOMAINS'] ?? 'yourdomain.com,api.yourdomain.com')
          .split(',')
          .map((domain) => domain.trim())
          .toList(),
      'production',
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
    return allowedDomains.any((allowedDomain) =>
        domain.toLowerCase().contains(allowedDomain.toLowerCase()));
  }

  // Helper method to build full URL
  String buildUrl(String endpoint) {
    // Remove leading slash if present
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

    return '$baseUrl/$cleanEndpoint';
  }

  @override
  String toString() {
    return 'AppConfig(environment: $environment, baseUrl: $baseUrl, allowedDomains: $allowedDomains)';
  }
}
