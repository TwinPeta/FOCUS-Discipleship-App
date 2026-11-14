import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/segmented_toggle.dart';
import '../../../core/widgets/step_progress.dart';
import '../data/institution_data.dart';
import '../domain/user_profile.dart';
import 'profile_providers.dart';
import 'widgets/join_photo_picker.dart';
import 'widgets/labeled_dropdown.dart';

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
    text: widget.existingProfile?.fullName ?? '',
  );
  late final _usernameController = TextEditingController(
    text: widget.existingProfile?.username ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.existingProfile?.email ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.existingProfile?.phone ?? '',
  );
  late final _birthdateController = TextEditingController(
    text: _formatBirthdate(widget.existingProfile?.birthdate),
  );

  final _fullNameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  DateTime? _birthdate;
  late String _country;
  late InstitutionType _institutionType;
  String? _institutionName;
  String? _photoPath;
  bool _isSubmitting = false;

  final Map<String, String?> _errors = {};

  bool get _isEditing => widget.existingProfile != null;

  static String _formatBirthdate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')} / '
        '${date.month.toString().padLeft(2, '0')} / '
        '${date.year}';
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProfile;
    _birthdate = existing?.birthdate;
    _country = existing?.country ?? InstitutionData.countries.first;
    _institutionType = existing?.institutionType ?? InstitutionType.university;
    _institutionName = existing?.institutionName;
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

  List<String> get _institutionOptions {
    final byCountry = _institutionType == InstitutionType.university
        ? InstitutionData.universitiesByCountry
        : InstitutionData.highSchoolsByCountry;
    return byCountry[_country] ?? const [];
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
        _institutionType == InstitutionType.university
            ? 'University'
            : 'High school',
      ),
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

  Future<void> _submit() async {
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
    );

    final repository = ref.read(profileRepositoryProvider);
    final saved = _isEditing
        ? await repository.updateProfile(profile)
        : await repository.createProfile(profile);
    ref.read(currentProfileProvider.notifier).state = saved;

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (_isEditing) {
      context.pop();
    } else {
      context.go('/communities');
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
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: 'Back',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(height: 12),
                  StepProgress(currentStep: 1),
                  const SizedBox(height: 6),
                  Text(
                    'Step 1 of 3',
                    style: AppTextStyles.fieldLabel.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                                'Tell us who you are to join your campus community.',
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
                    AppTextField(
                      label: 'Full name',
                      controller: _fullNameController,
                      focusNode: _fullNameFocus,
                      placeholder: 'e.g. Grace Namuli',
                      textCapitalization: TextCapitalization.words,
                      errorText: _errors['fullName'],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Username',
                      controller: _usernameController,
                      focusNode: _usernameFocus,
                      placeholder: 'username',
                      prefixText: '@',
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
                            suffixIcon: const Icon(
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
                      errorText: _errors['email'],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Phone number',
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      placeholder: '+256 700 000 000',
                      keyboardType: TextInputType.phone,
                      errorText: _errors['phone'],
                    ),
                    const SizedBox(height: 16),
                    Text('I study at', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    SegmentedToggle<InstitutionType>(
                      value: _institutionType,
                      options: const [
                        SegmentedOption(
                          label: 'University',
                          value: InstitutionType.university,
                        ),
                        SegmentedOption(
                          label: 'High school',
                          value: InstitutionType.highSchool,
                        ),
                      ],
                      onChanged: (type) {
                        setState(() {
                          _institutionType = type;
                          _institutionName = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    LabeledDropdown<String>(
                      label: _institutionType == InstitutionType.university
                          ? 'University'
                          : 'High school',
                      value: _institutionName,
                      items: _institutionOptions,
                      itemLabel: (name) => name,
                      hint: _institutionType == InstitutionType.university
                          ? 'Select your university'
                          : 'Select your high school',
                      errorText: _errors['institutionName'],
                      onChanged: (name) =>
                          setState(() => _institutionName = name),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.cream, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: AppPrimaryButton(
                  label: _isEditing ? 'Save' : 'Submit',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
