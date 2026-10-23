import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('nouveau message : illustration via imagePath (bucket chat_images)', () {
      final message = ChatMessage(
        id: 'm1',
        text: 'Voici une idée de plat',
        isUser: false,
        createdAt: DateTime(2026, 1, 1),
        imagePath: 'user-123/abc.jpg',
      );

      expect(message.imagePath, 'user-123/abc.jpg');
      expect(message.imageUrl, isNull);
      expect(message.hasLegacyImage, isFalse);
    });

    test('ancien message (avant migration 0019) : data URI base64 via imageUrl', () {
      const dataUri = 'data:image/jpeg;base64,/9j/4AAQSkZJRg==';
      final message = ChatMessage(
        id: 'm2',
        text: 'Essaie ce plat',
        isUser: false,
        createdAt: DateTime(2025, 1, 1),
        imageUrl: dataUri,
      );

      expect(message.imageUrl, dataUri);
      expect(message.imagePath, isNull);
      expect(message.hasLegacyImage, isFalse);
    });

    test('message sans illustration (texte simple)', () {
      final message = ChatMessage(
        id: 'm3',
        text: 'Bonjour',
        isUser: true,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(message.imageUrl, isNull);
      expect(message.imagePath, isNull);
      expect(message.hasLegacyImage, isFalse);
    });

    test('message legacy chargé depuis la base sans image_url en mémoire (hasLegacyImage)', () {
      // Voir ChatNotifier._fetchPage : l'historique est chargé sans
      // sélectionner image_url en masse, donc un message legacy a
      // hasLegacyImage=true mais imageUrl=null jusqu'au chargement à la
      // demande (fetchLegacyImageDataUri).
      final message = ChatMessage(
        id: 'm4',
        text: 'Plat recommandé',
        isUser: false,
        createdAt: DateTime(2025, 6, 1),
        hasLegacyImage: true,
      );

      expect(message.imageUrl, isNull);
      expect(message.imagePath, isNull);
      expect(message.hasLegacyImage, isTrue);
    });

    test('engine est null par défaut (message utilisateur ou historique rechargé)', () {
      final message = ChatMessage(
        id: 'm5',
        text: 'Bonjour',
        isUser: true,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(message.engine, isNull);
    });

    test('engine porte le moteur ayant répondu (local ou cloud)', () {
      final local = ChatMessage(
        id: 'm6',
        text: 'Réponse locale',
        isUser: false,
        createdAt: DateTime(2026, 1, 1),
        engine: 'local',
      );
      final cloud = ChatMessage(
        id: 'm7',
        text: 'Réponse cloud',
        isUser: false,
        createdAt: DateTime(2026, 1, 1),
        engine: 'cloud',
      );

      expect(local.engine, 'local');
      expect(cloud.engine, 'cloud');
    });
  });
}
