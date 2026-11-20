import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/step_progress.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../data/institution_data.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';
import 'profile_providers.dart';
import 'widgets/institution_picker.dart';
import 'widgets/join_photo_picker.dart';
import '../../../core/widgets/labeled_dropdown.dart';

/// Screen 2 of the brief: "Create your profile". Also reused, pre-filled,
/// as the My profile screen's edit form when [existingProfile] is set.
class JoinFormScreen extends ConsumerStatefulWidget {
  const JoinFormScreen({super.key, this.existingProfile});

  final UserProfile? existingProfile;

  @override
  ConsumerState<JoinFormScreen> createState() => _JoinFormScreenState();
}

class _JoinFormScreenState extends ConsumerState<JoinFormScreen> {
  late final _fullNameController = TextEditingController(
    text: _initial?.fullName ?? '',
  );
  late final _usernameController = TextEditingController(
    text: _initial?.username ?? '',
  );
  late final _emailController = TextEditingController(
    text: _initial?.email ?? '',
  );
  late final _phoneController = TextEditingController(
    text: _initial?.phone ?? '',
  );
  late final _birthdateController = TextEditingController(
    text: _formatBirthdate(_initial?.birthdate),
  );
  late final _churchNameController = TextEditingController(
    text: _initial?.homeChurch?.name ?? '',
  );
  late final _churchLocationController = TextEditingController(
    text: _initial?.homeChurch?.location ?? '',
  );
  late final _churchPastorController = TextEditingController(
    text: _initial?.homeChurch?.pastor ?? '',
  );

  final _fullNameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  DateTime? _birthdate;
  late String _country;
  late InstitutionType _institutionType;
  String? _institutionName;
  int? _yearOfStudy;
  String? _photoPath;
  bool _isSubmitting = false;

  final Map<String, String?> _errors = {};

  bool get _isEditing => widget.existingProfile != null;

  /// Edit mode: the saved profile. Sign-up: the draft, so coming back to
  /// this step never loses what was typed.
  late final UserProfile? _initial =
      widget.existingProfile ?? ref.read(signUpControllerProvider).details;

  static String _formatBirthdate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')} / '
        '${date.month.toString().padLeft(2, '0')} / '
        '${date.year}';
  }

  @override
  void initState() {
    super.initState();
    final existing = _initial;
    _birthdate = existing?.birthdate;
    _country = existing?.country ?? InstitutionData.countries.first;
    _institutionType = existing?.institutionType ?? InstitutionType.university;
    _institutionName = existing?.institutionName;
    _yearOfStudy = existing?.yearOfStudy;
    _photoPath = existing?.photoPath;

    _fullNameFocus.addListener(
      () => _onBlur(
        _fullNameFocus,
        'fullName',
        () => Validators.required(_fullNameController.text, 'Full name'),
      ),
    );
    _usernameFocus.addListener(
      () => _onBlur(
        _usernameFocus,
        'username',
        () => Validators.username(_usernameController.text),
      ),
    );
    _usernameFocus.addListener(() {
      if (!_usernameFocus.hasFocus) _checkUsernameAvailable();
    });
    _emailFocus.addListener(
      () => _onBlur(
        _emailFocus,
        'email',
        () => Validators.email(_emailController.text),
      ),
    );
    _phoneFocus.addListener(
      () => _onBlur(
        _phoneFocus,
        'phone',
        () => Validators.phone(_phoneController.text),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    _churchNameController.dispose();
    _churchLocationController.dispose();
    _churchPastorController.dispose();
    _fullNameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onBlur(FocusNode node, String key, String? Function() validate) {
    if (!node.hasFocus) {
      setState(() => _errors[key] = validate());
    }
  }

  /// Null while every church field is empty: it can be added later.
  HomeChurch? get _homeChurch {
    final c = HomeChurch(
      name: _churchNameController.text.trim(),
      location: _churchLocationController.text.trim(),
      pastor: _churchPastorController.text.trim(),
    );
    return c.name.isEmpty && c.location.isEmpty && c.pastor.isEmpty ? null : c;
  }

  Map<String, String?> _validateAll() {
    return {
      'fullName': Validators.required(_fullNameController.text, 'Full name'),
      'username': Validators.username(_usernameController.text),
      'birthdate': Validators.birthdate(_birthdate),
      'country': Validators.required(_country, 'Country'),
      'email': Validators.email(_emailController.text),
      'phone': Validators.phone(_phoneController.text),
      'institutionName': Validators.required(
        _institutionName,
        _institutionType.label,
      ),
      'yearOfStudy':
          _institutionType == InstitutionType.university && _yearOfStudy == null
          ? 'Year of study is required'
          : null,
      // Optional, but complete once started.
      if (_homeChurch != null) ...{
        'churchName': Validators.required(
          _churchNameController.text,
          'Church name',
        ),
        'churchLocation': Validators.required(
          _churchLocationController.text,
          'Church location',
        ),
        'churchPastor': Validators.required(
          _churchPastorController.text,
          "Pastor's name",
        ),
      } else ...{
        'churchName': null,
        'churchLocation': null,
        'churchPastor': null,
      },
    };
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthdate = picked;
        _birthdateController.text = _formatBirthdate(picked);
        _errors['birthdate'] = Validators.birthdate(picked);
      });
    }
  }

  Future<void> _checkUsernameAvailable() async {
    final username = _usernameController.text.trim();
    if (Validators.username(username) != null) return;
    final available = await ref
        .read(profileRepositoryProvider)
        .isUsernameAvailable(username, ownerId: widget.existingProfile?.id);
    if (!mounted || _usernameController.text.trim() != username) return;
    if (!available) {
      setState(() => _errors['username'] = _usernameTakenMessage);
    }
  }

  static const _usernameTakenMessage = 'That username is already taken';

  Future<void> _submit() async {
    // Re-entry guard first: two taps in one frame must create one profile.
    if (_isSubmitting) return;
    final errors = _validateAll();
    setState(() => _errors.addAll(errors));
    if (errors.values.any((error) => error != null)) {
      return;
    }

    setState(() => _isSubmitting = true);
    final profile = UserProfile(
      id:
          widget.existingProfile?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      birthdate: _birthdate!,
      country: _country,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      institutionType: _institutionType,
      institutionName: _institutionName!,
      photoPath: _photoPath,
      yearOfStudy: _institutionType == InstitutionType.university
          ? _yearOfStudy
          : null,
      homeChurch: _homeChurch,
    );

    try {
      if (_isEditing) {
        await ref.read(profileControllerProvider.notifier).save(profile);
      } else {
        // Sign-up: nothing is created yet. Check uniqueness now, keep the
        // answers in the draft, and create the account after the charter.
        final profiles = ref.read(profileRepositoryProvider);
        final auth = ref.read(authRepositoryProvider);
        final errors = {
          ...validateProfile(profile),
          ...validateSignUpDetails(profile),
        };
        if (errors.isNotEmpty) throw ProfileValidationError(errors);
        if (!await profiles.isUsernameAvailable(profile.username)) {
          throw UsernameTakenError(profile.username);
        }
        if (!await auth.isEmailAvailable(profile.email)) {
          if (mounted) {
            setState(
              () => _errors['email'] =
                  'An account already uses this email. Sign in instead.',
            );
          }
          return;
        }
        ref.read(signUpControllerProvider.notifier).setDetails(profile);
      }
    } on UsernameTakenError {
      if (mounted) {
        setState(() => _errors['username'] = _usernameTakenMessage);
      }
      return;
    } on ProfileValidationError catch (e) {
      if (mounted) setState(() => _errors.addAll(e.errors));
      return;
    } catch (_) {
      if (mounted) showErrorSnack(context);
      return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    if (_isEditing) {
      context.canPop() ? context.pop() : context.go('/profile');
    } else {
      unawaited(context.push('/join/password'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: 'Back',
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      if (!_isEditing) const XpPill(label: '0 XP'),
                    ],
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 12),
                    const StepProgress(currentStep: 1),
                    const SizedBox(height: 6),
                    Text(
                      'STEP 1 OF 3',
                      style: AppTextStyles.fieldLabel.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEditing
                                      ? 'Edit your profile'
                                      : 'Create your profile',
                                  style: AppTextStyles.joinFormTitle,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tell us who you are to join your campus caregroup.',
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          JoinPhotoPicker(
                            photoPath: _photoPath,
                            onPhotoPicked: (path) =>
                                setState(() => _photoPath = path),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle('About you'),
                      AppTextField(
                        label: 'Full name',
                        controller: _fullNameController,
                        focusNode: _fullNameFocus,
                        placeholder: 'e.g. Grace Namuli',
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _usernameFocus.requestFocus(),
                        errorText: _errors['fullName'],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Username',
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        placeholder: 'username',
                        prefixText: '@',
                        autofillHints: const [AutofillHints.newUsername],
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                        errorText: _errors['username'],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Birthdate',
                              readOnly: true,
                              onTap: _pickBirthdate,
                              controller: _birthdateController,
                              placeholder: 'DD / MM / YYYY',
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: AppColors.placeholder,
                              ),
                              errorText: _errors['birthdate'],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LabeledDropdown<String>(
                              label: 'Country',
                              value: _country,
                              items: InstitutionData.countries,
                              itemLabel: (country) => country,
                              errorText: _errors['country'],
                              onChanged: (country) {
                                if (country == null) return;
                                setState(() {
                                  _country = country;
                                  _institutionName = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Email',
                        controller: _emailController,
                        focusNode: _emailFocus,
                        placeholder: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _phoneFocus.requestFocus(),
                        errorText: _errors['email'],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Phone number',
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        placeholder: '+256 700 000 000',
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        textInputAction: TextInputAction.done,
                        errorText: _errors['phone'],
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle('Your school'),
                      InstitutionPicker(
                        country: _country,
                        type: _institutionType,
                        name: _institutionName,
                        errorText: _errors['institutionName'],
                        onTypeChanged: (type) {
                          setState(() {
                            _institutionType = type;
                            _institutionName = null;
                            _errors.remove('yearOfStudy');
                          });
                        },
                        onNameChanged: (name) =>
                            setState(() => _institutionName = name),
                        yearOfStudy: _yearOfStudy,
                        yearErrorText: _errors['yearOfStudy'],
                        onYearChanged: (year) => setState(() {
                          _yearOfStudy = year;
                          _errors['yearOfStudy'] = null;
                        }),
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle('Your home church'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Optional. You can add it now or later from your '
                          'profile.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.inkDeemphasized80,
                          ),
                        ),
                      ),
                      AppTextField(
                        label: 'Church name',
                        controller: _churchNameController,
                        placeholder: 'e.g. Watoto Church',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        errorText: _errors['churchName'],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Location',
                        controller: _churchLocationController,
                        placeholder: 'e.g. Kampala, Central',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        errorText: _errors['churchLocation'],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: "Pastor's name",
                        controller: _churchPastorController,
                        placeholder: 'e.g. Pastor John Mukasa',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        errorText: _errors['churchPastor'],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: BoxDecoration(color: AppColors.page),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isEditing) ...[
                      const Center(
                        child: XpPill(
                          label: '+10 XP when you continue',
                          soft: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    AppPrimaryButton(
                      label: _isEditing ? 'Save' : 'Continue',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Heading over one group of the profile form.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: AppTextStyles.cardTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
