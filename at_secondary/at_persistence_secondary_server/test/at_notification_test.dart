import 'dart:io';

import 'package:at_persistence_secondary_server/at_persistence_secondary_server.dart';
import 'package:test/test.dart';

void main() async {
  group('A group notification model test', () {
    test('test notification expired', () async {
      final notificationBuilder = AtNotificationBuilder()..ttl = 100;
      final atNotification = notificationBuilder.build();
      sleep(Duration(milliseconds: 200));
      expect(atNotification.isExpired(), true);
    });

    test('test notification not expired', () async {
      final notificationBuilder = AtNotificationBuilder()..ttl = 500;
      final atNotification = notificationBuilder.build();
      sleep(Duration(milliseconds: 50));
      expect(atNotification.isExpired(), false);
    });
  });
}
