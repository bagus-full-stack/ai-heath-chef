import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import 'auth_provider.dart';

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(authStateProvider);
  final service = ref.watch(authServiceProvider);
  final data = await service.fetchMyProfile();
  if (data == null) {
    return null;
  }
  return UserProfile.fromJson(data);
});
