import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chime/chime.dart';
import 'package:toastification/toastification.dart';

void main() {
  ToastificationItem testItem() => ToastificationItem(
    builder: (context, id) => const SizedBox(),
    alignment: Alignment.topRight,
  );

  group('ChimeNotification', () {
    test('constructs with all fields', () {
      final notification = ChimeNotification(
        id: 1,
        action: 'open_chat',
        input: 'user_reply',
        payload: '{"chat_id": "abc"}',
        identifier: 'chat:abc',
        data: {'key': 'value'},
      );

      expect(notification.id, 1);
      expect(notification.action, 'open_chat');
      expect(notification.input, 'user_reply');
      expect(notification.payload, '{"chat_id": "abc"}');
      expect(notification.identifier, 'chat:abc');
      expect(notification.data, {'key': 'value'});
    });

    test('constructs with nullable fields null', () {
      final notification = ChimeNotification(
        id: 2,
        action: null,
        input: null,
        payload: null,
        identifier: 'test:2',
      );

      expect(notification.action, isNull);
      expect(notification.input, isNull);
      expect(notification.payload, isNull);
      expect(notification.data, isEmpty);
    });

    test('withGeneratedId generates unique ids', () {
      final n1 = ChimeNotification.withGeneratedId(
        action: 'a',
        input: 'b',
        identifier: 'id1',
      );
      final n2 = ChimeNotification.withGeneratedId(
        action: 'a',
        input: 'b',
        identifier: 'id2',
      );

      expect(n1.id, isNot(n2.id));
    });

    test('getPayloadAsJson parses valid JSON', () {
      final notification = ChimeNotification(
        id: 1,
        action: null,
        input: null,
        payload: '{"chat_id": "123", "sender": "John"}',
        identifier: 'test',
      );

      final json = notification.getPayloadAsJson();
      expect(json, isNotNull);
      expect(json!['chat_id'], '123');
      expect(json['sender'], 'John');
    });

    test('getPayloadAsJson returns null for invalid JSON', () {
      final notification = ChimeNotification(
        id: 1,
        action: null,
        input: null,
        payload: 'not json',
        identifier: 'test',
      );

      expect(notification.getPayloadAsJson(), isNull);
    });

    test('getPayloadAsJson returns null when payload is null', () {
      final notification = ChimeNotification(
        id: 1,
        action: null,
        input: null,
        payload: null,
        identifier: 'test',
      );

      expect(notification.getPayloadAsJson(), isNull);
    });

    test('toJson serializes correctly', () {
      final notification = ChimeNotification(
        id: 1,
        action: 'open',
        input: 'reply',
        payload: '{"a": 1}',
        identifier: 'test:1',
        data: {'extra': true},
      );

      final json = notification.toJson();
      expect(json['id'], 1);
      expect(json['action'], 'open');
      expect(json['input'], 'reply');
      expect(json['payload'], '{"a": 1}');
      expect(json['identifier'], 'test:1');
      expect(json['data'], {'extra': true});
    });

    test('equality based on equalizedProperties', () {
      final n1 = ChimeNotification(
        id: 1, action: 'a', input: 'b', payload: 'p', identifier: 'x',
      );
      final n2 = ChimeNotification(
        id: 1, action: 'a', input: 'b', payload: 'p', identifier: 'y',
      );
      final n3 = ChimeNotification(
        id: 2, action: 'a', input: 'b', payload: 'p', identifier: 'x',
      );

      expect(n1, equals(n2));
      expect(n1, isNot(equals(n3)));
    });
  });

  group('ChimeCreatedNotification', () {
    test('constructs with title and body', () {
      final notification = ChimeCreatedNotification(
        id: 10,
        identifier: 'welcome:1',
        title: 'Welcome',
        body: 'Thanks for joining',
      );

      expect(notification.id, 10);
      expect(notification.identifier, 'welcome:1');
      expect(notification.title, 'Welcome');
      expect(notification.body, 'Thanks for joining');
      expect(notification.action, '');
      expect(notification.input, '');
    });

    test('toJson includes title and body', () {
      final notification = ChimeCreatedNotification(
        id: 10,
        identifier: 'welcome:1',
        title: 'Welcome',
        body: 'Thanks',
      );

      final json = notification.toJson();
      expect(json['title'], 'Welcome');
      expect(json['body'], 'Thanks');
    });

    test('equality includes title and body', () {
      final n1 = ChimeCreatedNotification(
        id: 1, identifier: 'a', title: 'T', body: 'B',
      );
      final n2 = ChimeCreatedNotification(
        id: 1, identifier: 'a', title: 'T', body: 'B',
      );
      final n3 = ChimeCreatedNotification(
        id: 1, identifier: 'a', title: 'T', body: 'Different',
      );

      expect(n1, equals(n2));
      expect(n1, isNot(equals(n3)));
    });
  });

  group('ChimeAppNotification', () {
    test('constructs with required fields', () {
      final item = testItem();
      final notification = ChimeAppNotification(
        identifier: 'toast:1',
        title: 'Update',
        description: 'Settings saved',
        state: ChimeInAppState.success,
        item: item,
      );

      expect(notification.identifier, 'toast:1');
      expect(notification.title, 'Update');
      expect(notification.description, 'Settings saved');
      expect(notification.state, ChimeInAppState.success);
      expect(notification.item, item);
      expect(notification.action, 'IN_APP');
      expect(notification.input, 'IN_APP');
    });

    test('toJson includes title, description, state', () {
      final item = testItem();
      final notification = ChimeAppNotification(
        identifier: 'toast:1',
        title: 'Title',
        description: 'Desc',
        state: ChimeInAppState.error,
        item: item,
      );

      final json = notification.toJson();
      expect(json['title'], 'Title');
      expect(json['description'], 'Desc');
      expect(json['state'], 'error');
    });
  });

  group('ChimeCreatedAppNotification', () {
    test('constructs with required fields', () {
      final item = testItem();
      final notification = ChimeCreatedAppNotification(
        identifier: 'toast:2',
        title: 'Warning',
        description: 'Check input',
        state: ChimeInAppState.warning,
        item: item,
      );

      expect(notification.identifier, 'toast:2');
      expect(notification.title, 'Warning');
      expect(notification.description, 'Check input');
      expect(notification.state, ChimeInAppState.warning);
    });

    test('toJson includes description and state', () {
      final item = testItem();
      final notification = ChimeCreatedAppNotification(
        identifier: 'toast:2',
        title: 'Title',
        description: 'Desc',
        state: ChimeInAppState.info,
        item: item,
      );

      final json = notification.toJson();
      expect(json['description'], 'Desc');
      expect(json['state'], 'info');
    });
  });

  group('ChimeCreatedCustomAppNotification', () {
    test('constructs with item', () {
      final item = testItem();
      final notification = ChimeCreatedCustomAppNotification(
        identifier: 'custom:1',
        item: item,
      );

      expect(notification.identifier, 'custom:1');
      expect(notification.item, item);
      expect(notification.title, 'Custom Notificaation');
    });
  });

  group('_generateSecureRandomId', () {
    test('generates ids in valid range', () {
      final n1 = ChimeNotification.withGeneratedId(
        action: null, input: null, identifier: 'test',
      );
      final n2 = ChimeNotification.withGeneratedId(
        action: null, input: null, identifier: 'test',
      );

      expect(n1.id, greaterThanOrEqualTo(0));
      expect(n1.id, lessThan(1 << 32));
      expect(n2.id, greaterThanOrEqualTo(0));
      expect(n2.id, lessThan(1 << 32));
    });
  });
}