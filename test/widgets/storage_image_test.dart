import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_health_chef/providers/storage_image_provider.dart';
import 'package:ai_health_chef/services/storage_image_service.dart';
import 'package:ai_health_chef/widgets/storage_image.dart';

class _FakeStorageImageService implements StorageImageService {
  _FakeStorageImageService(this.urlToReturn);
  final String? urlToReturn;

  @override
  Future<String?> resolve(String bucket, String? path) async {
    return path == null ? null : urlToReturn;
  }

  @override
  void invalidate(String bucket, String path) {}
}

Future<void> _pump(
  WidgetTester tester,
  String? path,
  StorageImageService service,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [storageImageServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        home: StorageImage(
          bucket: 'avatars',
          path: path,
          builder: (context, snapshot) => Text(snapshot.data ?? 'placeholder'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the placeholder while path is null', (tester) async {
    await _pump(tester, null, _FakeStorageImageService(null));
    await tester.pumpAndSettle();

    expect(find.text('placeholder'), findsOneWidget);
  });

  testWidgets('shows the resolved url once resolution completes', (tester) async {
    await _pump(tester, 'user-1/a.jpg', _FakeStorageImageService('https://signed.example/a.jpg'));
    await tester.pumpAndSettle();

    expect(find.text('https://signed.example/a.jpg'), findsOneWidget);
  });
}
