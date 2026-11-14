import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_profile.dart';

/// Holds the signed-in user's profile for the duration of the session.
/// Screens read it reactively; [JoinFormScreen] is the only writer, and it
/// always writes through [ProfileRepository] first.
final currentProfileProvider = StateProvider<UserProfile?>((ref) => null);
