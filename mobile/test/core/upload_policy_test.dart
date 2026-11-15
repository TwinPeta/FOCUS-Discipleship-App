import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'package:focus_1/core/media/photo_picker.dart';
import 'package:focus_1/core/media/upload_policy.dart';
import 'package:focus_1/core/theme/app_theme.dart';
import 'package:focus_1/core/widgets/message_input_bar.dart';

import '../support/fake_backend.dart';

/// Returns a fixed file instead of opening the gallery, and records the
/// compression settings it was asked for.
class _FakePicker extends ImagePicker {
  _FakePicker(this.file);

  final XFile file;
  int? quality;
  double? maxWidth;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    quality = imageQuality;
    this.maxWidth = maxWidth;
    return file;
  }
}

/// Like a picked file: in-memory bytes, with a path (the name comes from
/// the path on mobile).
XFile _file(String name, int bytes) =>
    XFile.fromData(Uint8List(bytes), name: name, path: '/picked/$name');

void main() {
  group('UploadPolicy.checkPhoto', () {
    test('common photo formats pass, others are refused', () {
      for (final ok in ['a.jpg', 'b.JPEG', 'c.png', 'd.webp', 'e.heic']) {
        expect(
          UploadPolicy.checkPhoto(name: ok, bytes: 10),
          isNull,
          reason: ok,
        );
      }
      for (final bad in ['a.gif', 'b.mp4', 'c.pdf', 'noext']) {
        expect(
          UploadPolicy.checkPhoto(name: bad, bytes: 10),
          isNotNull,
          reason: bad,
        );
      }
    });

    test('2 MB is the limit', () {
      expect(
        UploadPolicy.checkPhoto(
          name: 'a.jpg',
          bytes: UploadPolicy.maxPhotoBytes,
        ),
        isNull,
      );
      expect(
        UploadPolicy.checkPhoto(
          name: 'a.jpg',
          bytes: UploadPolicy.maxPhotoBytes + 1,
        ),
        contains('under 2 MB'),
      );
    });
  });

  Future<XFile?> run(WidgetTester tester, _FakePicker picker) async {
    late BuildContext ctx;
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeBackend(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Consumer(
              builder: (c, r, _) {
                ctx = c;
                ref = r;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    final result = await pickPhoto(ctx, ref, picker: picker);
    await tester.pump();
    return result;
  }

  testWidgets('pickPhoto compresses to 80% and accepts a PNG', (tester) async {
    final picker = _FakePicker(_file('photo.png', 500 * 1024));
    expect(await run(tester, picker), isNotNull);
    expect(picker.quality, 80);
    expect(picker.maxWidth, UploadPolicy.photoMaxDimension);
  });

  testWidgets('pickPhoto refuses a GIF with a message', (tester) async {
    expect(await run(tester, _FakePicker(_file('anim.gif', 1000))), isNull);
    expect(find.textContaining('Please choose a photo'), findsOneWidget);
  });

  testWidgets('pickPhoto refuses more than 2 MB with a message', (
    tester,
  ) async {
    final big = _FakePicker(_file('big.jpg', UploadPolicy.maxPhotoBytes + 1));
    expect(await run(tester, big), isNull);
    expect(find.textContaining('under 2 MB'), findsOneWidget);
  });

  testWidgets('chat input stops at the message limit', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MessageInputBar(
            controller: controller,
            onSend: () {},
            hintText: 'Write',
            sendLabel: 'Send',
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextField),
      'a' * (UploadPolicy.maxMessageChars + 200),
    );
    expect(controller.text.length, UploadPolicy.maxMessageChars);
  });
}
