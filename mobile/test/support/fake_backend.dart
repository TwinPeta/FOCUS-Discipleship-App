import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focus_1/demo/demo_backend.dart';

export 'package:focus_1/demo/demo_backend.dart' show fakeBackend;

/// A container wired to the test doubles; [overrides] win over the defaults.
ProviderContainer fakeContainer({List<Override> overrides = const []}) =>
    ProviderContainer(overrides: [...fakeBackend(), ...overrides]);
