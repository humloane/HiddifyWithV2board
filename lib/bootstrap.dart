import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/logger/logger_controller.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_migration.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/app/widget/app.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';
import 'package:hiddify/features/deep_link/notifier/deep_link_notifier.dart';
import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/panel/xboard/services/auth_provider.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/user_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/system_tray/notifier/system_tray_notifier.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/singbox/service/singbox_service_provider.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> lazyBootstrap(
  WidgetsBinding widgetsBinding,
  Environment env,
) async {
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  LoggerController.preInit();
  FlutterError.onError = Logger.logFlutterError;
  WidgetsBinding.instance.platformDispatcher.onError =
      Logger.logPlatformDispatcherError;
  final userService = UserService();
  final stopWatch = Stopwatch()..start();

  final container = ProviderContainer(
    overrides: [
      environmentProvider.overrideWithValue(env),
    ],
  );
// 初始化域名
  try {
    container.read(authProvider.notifier).state = false;
    // print("Initializing domain...");
    // await HttpService.initialize();
    // print("Domain initialized successfully: ${HttpService.baseUrl}");
  } catch (e) {
    // 如果初始化域名出错，设置为未登录状态
    print("Error during domain initialization: $e");
    container.read(authProvider.notifier).state = false;
    return;
  }

// 尝试读取 token 并设置登录状态
  try {
    final token = await getToken(); // 从 SharedPreferences 中获取 token
    print("Retrieved token: $token");

    if (token != null) {
      // 调用 authService 实例上的 validateToken 方法
      print("Validating token...");
      final isValid = await userService.validateToken(token);
      print("Token validation result: $isValid");

      if (isValid) {
        container.read(authProvider.notifier).state = true; // 设置为已登录
        print("User is logged in");
      } else {
        container.read(authProvider.notifier).state = false; // 设置为未登录
        print("Token is invalid, setting user to not logged in");
      }
    } else {
      container.read(authProvider.notifier).state = false; // 没有 token 时设置为未登录
      print("No token found, setting user to not logged in");
    }
  } catch (e) {
    // 在任何错误情况下设置为未登录
    print("Error during token validation: $e");
    container.read(authProvider.notifier).state = false;
  }

  await _init(
    "directories",
    () => container.read(appDirectoriesProvider.future),
  );
  LoggerController.init(container.read(logPathResolverProvider).appFile().path);

  final appInfo = await _init(
    "app info",
    () => container.read(appInfoProvider.future),
  );
  await _init(
    "preferences",
    () => container.read(sharedPreferencesProvider.future),
  );

  final enableAnalytics =
      await container.read(analyticsControllerProvider.future);
  if (enableAnalytics) {
    await _init(
      "analytics",
      () => container
          .read(analyticsControllerProvider.notifier)
          .enableAnalytics(),
    );
  }

  await _init(
    "preferences migration",
    () async {
      try {
        await PreferencesMigration(
          sharedPreferences:
              container.read(sharedPreferencesProvider).requireValue,
        ).migrate();
      } catch (e, stackTrace) {
        Logger.bootstrap.error("preferences migration failed", e, stackTrace);
        if (env == Environment.dev) rethrow;
        Logger.bootstrap.info("clearing preferences");
        await container.read(sharedPreferencesProvider).requireValue.clear();
      }
    },
  );

  final debug = container.read(debugModeNotifierProvider) || kDebugMode;

  if (PlatformUtils.isDesktop) {
    await _init(
      "window controller",
      () => container.read(windowNotifierProvider.future),
    );

    final silentStart = container.read(Preferences.silentStart);
    Logger.bootstrap
        .debug("silent start [${silentStart ? "Enabled" : "Disabled"}]");
    if (!silentStart) {
      await container.read(windowNotifierProvider.notifier).open(focus: false);
    } else {
      Logger.bootstrap.debug("silent start, remain hidden accessible via tray");
    }
    await _init(
      "auto start service",
      () => container.read(autoStartNotifierProvider.future),
    );
  }
  await _init(
    "logs repository",
    () => container.read(logRepositoryProvider.future),
  );
  await _init("logger controller", () => LoggerController.postInit(debug));

  Logger.bootstrap.info(appInfo.format());

  await _init(
    "profile repository",
    () => container.read(profileRepositoryProvider.future),
  );

  await _safeInit(
    "active profile",
    () => container.read(activeProfileProvider.future),
    timeout: 1000,
  );
  await _safeInit(
    "deep link service",
    () => container.read(deepLinkNotifierProvider.future),
    timeout: 1000,
  );
  await _init(
    "extension database",
    () => _initExtensionDatabase(container),
  );
  await _init(
    "sing-box",
    () => container.read(singboxServiceProvider).init(),
  );
  if (PlatformUtils.isDesktop) {
    await _safeInit(
      "system tray",
      () => container.read(systemTrayNotifierProvider.future),
      timeout: 1000,
    );
  }

  if (Platform.isAndroid) {
    await _safeInit(
      "android display mode",
      () async {
        await FlutterDisplayMode.setHighRefreshRate();
      },
    );
  }

  Logger.bootstrap.info("bootstrap took [${stopWatch.elapsedMilliseconds}ms]");
  stopWatch.stop();

  runApp(
    ProviderScope(
      parent: container,
      child: SentryUserInteractionWidget(
        child: const App(),
      ),
    ),
  );

  FlutterNativeSplash.remove();
}

Future<T> _init<T>(
  String name,
  Future<T> Function() initializer, {
  int? timeout,
}) async {
  final stopWatch = Stopwatch()..start();
  Logger.bootstrap.info("initializing [$name]");
  Future<T> func() => timeout != null
      ? initializer().timeout(Duration(milliseconds: timeout))
      : initializer();
  try {
    final result = await func();
    Logger.bootstrap
        .debug("[$name] initialized in ${stopWatch.elapsedMilliseconds}ms");
    return result;
  } catch (e, stackTrace) {
    Logger.bootstrap.error("[$name] error initializing", e, stackTrace);
    rethrow;
  } finally {
    stopWatch.stop();
  }
}

Future<T?> _safeInit<T>(
  String name,
  Future<T> Function() initializer, {
  int? timeout,
}) async {
  try {
    return await _init(name, initializer, timeout: timeout);
  } catch (e) {
    return null;
  }
}

/// 初始化扩展数据库目录
Future<void> _initExtensionDatabase(ProviderContainer container) async {
  try {
    final directories = await container.read(appDirectoriesProvider.future);
    
    // libcore会切换工作目录到workingDir，然后在相对路径"./data"中查找数据库
    // 所以我们需要在workingDir中创建data目录和extensionData.db目录
    final workingDataDir = Directory('${directories.workingDir.path}/data');
    final workingExtensionDbDir = Directory('${workingDataDir.path}/extensionData.db');
    
    Logger.bootstrap.debug('Working directory: ${directories.workingDir.path}');
    Logger.bootstrap.debug('Target data directory: ${workingDataDir.path}');
    Logger.bootstrap.debug('Target extension database directory: ${workingExtensionDbDir.path}');
    
    // 创建working目录下的data目录
    if (!await workingDataDir.exists()) {
      await workingDataDir.create(recursive: true);
      Logger.bootstrap.info('Created working data directory: ${workingDataDir.path}');
    } else {
      Logger.bootstrap.debug('Working data directory already exists: ${workingDataDir.path}');
    }
    
    // 创建working目录下的extensionData.db目录（LevelDB需要目录而不是文件）
    if (!await workingExtensionDbDir.exists()) {
      await workingExtensionDbDir.create(recursive: true);
      Logger.bootstrap.info('Created working extension database directory: ${workingExtensionDbDir.path}');
    } else {
      Logger.bootstrap.debug('Working extension database directory already exists: ${workingExtensionDbDir.path}');
    }
    
    // 验证目录结构
    final dataExists = await workingDataDir.exists();
    final extensionDbExists = await workingExtensionDbDir.exists();
    
    Logger.bootstrap.info('Extension database initialization completed:');
    Logger.bootstrap.info('  - Data directory exists: $dataExists');
    Logger.bootstrap.info('  - Extension database directory exists: $extensionDbExists');
    
    if (!dataExists || !extensionDbExists) {
      throw Exception('Failed to create required database directories');
    }
    
  } catch (e, stackTrace) {
    Logger.bootstrap.error('Failed to initialize extension database', e, stackTrace);
    // 不抛出异常，避免阻止应用启动，但记录详细错误信息
  }
}
