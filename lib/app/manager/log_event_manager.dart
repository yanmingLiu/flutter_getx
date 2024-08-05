// 抽象的策略接口
abstract class AnalyticsStrategy {
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});
}

// 日志记录类
class Logger {
  void info(String message) {
    print('🚩 INFO: $message');
  }

  void error(String message) {
    print('🚩 ERROR: $message');
  }
}

// 依赖注入容器
class ServiceLocator {
  static final Map<Type, dynamic> _services = {};

  static void register<T>(T instance) {
    _services[T] = instance;
  }

  static T get<T>() {
    return _services[T] as T;
  }
}

// 事件上报管理类
class LogEventManager {
  final Logger _logger = Logger();

  List<String> allStrategies = ['firebase', 'another_platform'];

  LogEventManager() {
    // 注册所有策略
    ServiceLocator.register<FirebaseAnalyticsStrategy>(FirebaseAnalyticsStrategy());
    ServiceLocator.register<AnotherPlatformAnalyticsStrategy>(AnotherPlatformAnalyticsStrategy());
    ServiceLocator.register<Logger>(_logger);
  }

  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
    List<String>? strategies,
  }) async {
    final strategyTypes = strategies ?? allStrategies;

    for (var type in strategyTypes) {
      switch (type) {
        case 'firebase':
          final firebaseStrategy = ServiceLocator.get<FirebaseAnalyticsStrategy>();
          await firebaseStrategy.logEvent(name, parameters: parameters);
          break;
        case 'another_platform':
          final anotherPlatformStrategy = ServiceLocator.get<AnotherPlatformAnalyticsStrategy>();
          await anotherPlatformStrategy.logEvent(name, parameters: parameters);
          break;
        default:
          _logger.error('Unsupported strategy type: $type');
      }
    }

    _logger.info('Event reported: $name, parameters: $parameters, strategies: $strategyTypes');
  }
}

/// <summary>
/// 日志记录函数
/// </summary>
/// <param name="name">事件名称</param>
/// <param name="parameters">事件参数</param>
/// <param name="strategies">要使用的策略列表</param>
/// <returns></returns>
Future<void> logEvent(
  String name, {
  Map<String, dynamic>? parameters,
  List<String>? strategies,
}) {
  final eventReportManager = ServiceLocator.get<LogEventManager>();
  return eventReportManager.logEvent(name, parameters: parameters, strategies: strategies);
}

// Firebase 策略的具体实现
class FirebaseAnalyticsStrategy implements AnalyticsStrategy {
  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    print('FirebaseAnalyticsStrategy: $name, parameters: $parameters');
  }
}

// 其他平台策略的具体实现
class AnotherPlatformAnalyticsStrategy implements AnalyticsStrategy {
  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    print('AnotherPlatformAnalyticsStrategy: $name, parameters: $parameters');
  }
}
