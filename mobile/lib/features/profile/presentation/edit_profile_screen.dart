import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../domain/user_profile.dart';
import 'profile_providers.dart';
import 'widgets/institution_picker.dart';
import 'widgets/join_photo_picker.dart';

const _usernameTaken = 'That username is already taken';

/// Screen 47: Edit profile (`/settings/profile`). Save stays disabled until
/// something changed and every field is valid; email is read-only here.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    if (profile == null) {
      return const Scaffold(backgroundColor: AppColors.page, body: Skeleton());
    }
    return _EditProfileForm(key: ValueKey(profile.id), profile: profile);
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _username = TextEditingController(text: widget.profile.username);
  late final _phone = TextEditingController(text: widget.profile.phone);
  late final _churchName = TextEditingController(
    text: widget.profile.homeChurch?.name ?? '',
  );
  late final _churchLocation = TextEditingController(
    text: widget.profile.homeChurch?.location ?? '',
  );
  late final _churchPastor = TextEditingController(
    text: widget.profile.homeChurch?.pastor ?? '',
  );
  late int? _year = widget.profile.yearOfStudy;
  late var _type = widget.profile.institutionType;
  late String? _institution = widget.profile.institutionName;
  late String? _photo = widget.profile.photoPath;
  String? _usernameError;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _name,
      _username,
      _phone,
      _churchName,
      _churchLocation,
      _churchPastor,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _phone.dispose();
    _churchName.dispose();
    _churchLocation.dispose();
    _churchPastor.dispose();
    super.dispose();
  }

  /// Null while every church field is empty (accounts made before the
  /// home church was asked for).
  HomeChurch? get _church {
    final c = HomeChurch(
      name: _churchName.text.trim(),
      location: _churchLocation.text.trim(),
      pastor: _churchPastor.text.trim(),
    );
    return c.name.isEmpty && c.location.isEmpty && c.pastor.isEmpty ? null : c;
  }

  UserProfile get _draft => widget.profile.copyWith(
    fullName: _name.text.trim(),
    username: _username.text.trim(),
    phone: _phone.text.trim(),
    institutionType: _type,
    institutionName: _institution ?? '',
    photoPath: _photo,
    yearOfStudy: _year,
    clearYearOfStudy: _type != InstitutionType.university,
    homeChurch: _church,
  );

  Map<String, String?> get _errors => {
    'fullName': Validators.required(_name.text, 'Full name'),
    'username': Validators.username(_username.text) ?? _usernameError,
    'phone': Validators.phone(_phone.text),
    'institution': Validators.required(_institution, _type.label),
    'yearOfStudy': _type == InstitutionType.university && _year == null
        ? 'Year of study is required'
        : null,
    // Home church: all three once any is filled in (or already saved).
    if (_church != null || widget.profile.homeChurch != null) ...{
      'churchName': Validators.required(_churchName.text, 'Church name'),
      'churchLocation': Validators.required(
        _churchLocation.text,
        'Church location',
      ),
      'churchPastor': Validators.required(_churchPastor.text, "Pastor's name"),
    },
  };

  bool get _changed {
    final p = widget.profile;
    final d = _draft;
    return d.fullName != p.fullName ||
        d.username != p.username ||
        d.phone != p.phone ||
        d.institutionType != p.institutionType ||
        d.institutionName != p.institutionName ||
        d.photoPath != p.photoPath ||
        d.yearOfStudy != p.yearOfStudy ||
        d.homeChurch != p.homeChurch;
  }

  bool get _valid => _errors.values.every((e) => e == null);

  Future<bool> _checkUsername() async {
    final value = _username.text.trim();
    if (value == widget.profile.username ||
        Validators.username(value) != null) {
      return true;
    }
    final free = await ref
        .read(profileRepositoryProvider)
        .isUsernameAvailable(value, ownerId: widget.profile.id);
    if (mounted) setState(() => _usernameError = free ? null : _usernameTaken);
    return free;
  }

  Future<void> _save() async {
    if (_saving || !_changed || !_valid) return;
    setState(() => _saving = true);
    try {
      if (!await _checkUsername()) return;
      await ref.read(profileControllerProvider.notifier).save(_draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profile saved')));
      context.canPop() ? context.pop() : context.go('/settings');
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final errors = _errors;
    String? shown(String key, TextEditingController c) =>
        c.text.isEmpty ? null : errors[key];

    return AmberHeaderScaffold(
      title: 'Edit profile',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Center(
            child: JoinPhotoPicker(
              photoPath: _photo,
              onPhotoPicked: (path) => setState(() => _photo = path),
            ),
          ),
          const SizedBox(height: 4),
          Center(child: Text('Change photo', style: AppTextStyles.fieldLabel)),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Full name',
            controller: _name,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            errorText: _name.text.isEmpty ? errors['fullName'] : null,
          ),
          const SizedBox(height: 16),
          Focus(
            onFocusChange: (focused) {
              if (!focused) _checkUsername();
            },
            child: AppTextField(
              label: 'Username',
              controller: _username,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              errorText: shown('username', _username),
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Phone number',
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            textInputAction: TextInputAction.done,
            errorText: shown('phone', _phone),
          ),
          const SizedBox(height: 8),
          Text(
            'Email: ${widget.profile.email} · cannot be changed here.',
            style: AppTextStyles.body.copyWith(color: AppColors.placeholder),
          ),
          const SizedBox(height: 16),
          InstitutionPicker(
            country: widget.profile.country,
            type: _type,
            name: _institution,
            errorText: errors['institution'],
            onTypeChanged: (t) => setState(() {
              _type = t;
              _institution = null;
            }),
            onNameChanged: (n) => setState(() => _institution = n),
            yearOfStudy: _year,
            yearErrorText: errors['yearOfStudy'],
            onYearChanged: (y) => setState(() => _year = y),
          ),
          const SizedBox(height: 24),
          Text(
            'Home church',
            style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Church name',
            controller: _churchName,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            errorText: errors['churchName'],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Location',
            controller: _churchLocation,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            errorText: errors['churchLocation'],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: "Pastor's name",
            controller: _churchPastor,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            errorText: errors['churchPastor'],
          ),
        ],
      ),
      bottomBar: AppPrimaryButton(
        label: 'Save changes',
        isLoading: _saving,
        onPressed: online && _changed && _valid && !_saving ? _save : null,
      ),
    );
  }
}
