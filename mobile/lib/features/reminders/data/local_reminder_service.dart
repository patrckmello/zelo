import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/theme/zelo_colors.dart';
import '../domain/expiration_reminder_plan.dart';
import '../domain/reminder_service.dart';

/// Avisos de validade pelo `flutter_local_notifications`, só no Android.
///
/// Usa alarmes inexatos (sem a permissão de alarme exato): o aviso das 9h
/// pode chegar com alguns minutos de diferença, o que basta para um lembrete.
/// A hora local é convertida para um instante em UTC, então o banco de fusos
/// do pacote `timezone` não precisa ser carregado.
class LocalReminderService implements ReminderService {
  LocalReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'validade';
  static const channelName = 'Validade dos medicamentos';
  static const _channelDescription =
      'Avisos antes do vencimento dos medicamentos cadastrados.';
  static const _icon = 'ic_stat_zelo';

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  Future<void>? _initialization;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Stream<String> get taps => _taps.stream;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _ensureInitialized() => _initialization ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings(_icon),
    ),
    onDidReceiveNotificationResponse: (response) {
      final payload = response.payload;
      if (payload != null && !_taps.isClosed) {
        _taps.add(payload);
      }
    },
  );

  @override
  Future<ReminderPermission> permission() async {
    if (!isSupported) {
      return ReminderPermission.unsupported;
    }
    await _ensureInitialized();
    final enabled = await _android?.areNotificationsEnabled();
    return enabled == true
        ? ReminderPermission.granted
        : ReminderPermission.denied;
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    if (!isSupported) {
      return ReminderPermission.unsupported;
    }
    await _ensureInitialized();
    await _android?.requestNotificationsPermission();
    return permission();
  }

  @override
  Future<void> openSettings() async {
    if (isSupported) {
      await _ensureInitialized();
      await _android?.openAppNotificationSettings();
    }
  }

  NotificationDetails _details(String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: _channelDescription,
      icon: _icon,
      color: ZeloColors.petroleumBlue,
      styleInformation: BigTextStyleInformation(body),
      // Em tela bloqueada com senha, o sistema esconde os nomes (dados de
      // saúde, D018).
      visibility: NotificationVisibility.private,
    ),
  );

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    if (!isSupported) {
      return;
    }
    await _ensureInitialized();
    await _plugin.cancelAllPendingNotifications();
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.at, tz.UTC),
        notificationDetails: _details(reminder.body),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: expirationReminderPayload,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!isSupported) {
      return;
    }
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  @override
  Future<void> showTest() async {
    if (!isSupported) {
      return;
    }
    await _ensureInitialized();
    const body = 'É assim que os lembretes de validade vão chegar.';
    await _plugin.show(
      id: 0,
      title: 'Teste do Zelo',
      body: body,
      notificationDetails: _details(body),
      payload: expirationReminderPayload,
    );
  }

  @override
  Future<String?> launchPayload() async {
    if (!isSupported) {
      return null;
    }
    await _ensureInitialized();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) {
      return null;
    }
    return details?.notificationResponse?.payload;
  }
}
