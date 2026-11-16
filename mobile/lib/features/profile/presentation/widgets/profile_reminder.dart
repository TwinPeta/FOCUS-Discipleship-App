import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/user_profile.dart';
import '../profile_providers.dart';

/// Profile details a student may skip at sign-up and add later.
List<String> missingProfileDetails(UserProfile p) => [
  if (p.homeChurch == null) 'Home church (name, location and pastor)',
  if (p.institutionType == InstitutionType.university && p.yearOfStudy == null)
    'Year of study',
];

/// The reminder shows at most once per app session.
final profileReminderShownProvider = StateProvider<bool>((ref) => false);

/// Wraps a signed-in home screen: when the profile is missing details,
/// shows the "Complete your profile" pop-up once per session.
class ProfileReminderGate extends ConsumerStatefulWidget {
  const ProfileReminderGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ProfileReminderGate> createState() =>
      _ProfileReminderGateState();
}

class _ProfileReminderGateState extends ConsumerState<ProfileReminderGate> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<UserProfile?>(
      currentProfileProvider,
      (_, profile) => _maybeRemind(profile),
      fireImmediately: true,
    );
  }

  void _maybeRemind(UserProfile? profile) {
    if (profile == null || ref.read(profileReminderShownProvider)) return;
    final missing = missingProfileDetails(profile);
    if (missing.isEmpty) return;
    ref.read(profileReminderShownProvider.notifier).state = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => CompleteProfileDialog(missing: missing),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "Complete your profile": lists what is missing; "Complete now" opens
/// Edit profile, "Later" closes it until the next app session.
class CompleteProfileDialog extends StatelessWidget {
  const CompleteProfileDialog({super.key, required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Complete your profile',
              style: AppTextStyles.sectionHeading.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'A few details are still missing. Add them so mentors and '
              'FOCUS can get to know you.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 14),
            for (final item in missing)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: AppColors.amberDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item, style: AppTextStyles.bodyMedium),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Complete now',
              onPressed: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.push('/settings/profile');
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink,
                minimumSize: const Size(44, 44),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          ],
        ),
      ),
    );
  }
}
