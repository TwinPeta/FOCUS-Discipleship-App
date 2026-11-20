import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/labeled_dropdown.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';
import 'providers/auth_providers.dart';

/// Screen 24: Ask your guardian (`/join/guardian`, under-18 accounts).
class GuardianScreen extends ConsumerStatefulWidget {
  const GuardianScreen({super.key});

  static const relationships = ['Parent', 'Legal guardian', 'Other relative'];

  @override
  ConsumerState<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends ConsumerState<GuardianScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _relationship;
  final Map<String, String?> _errors = {};
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Map<String, String?> _validate(String ownEmail) {
    var emailError = Validators.email(_email.text);
    if (emailError == null &&
        _email.text.trim().toLowerCase() == ownEmail.toLowerCase()) {
      emailError = "Use your guardian's email, not your own";
    }
    return {
      'name': Validators.required(_name.text, "Guardian's full name"),
      'email': emailError,
      'relationship': Validators.required(_relationship, 'Relationship'),
    };
  }

  Future<void> _send() async {
    if (_sending) return;
    final session = ref.read(authSessionProvider);
    final profile = ref.read(currentProfileProvider);
    if (session == null || profile == null) return;
    final errors = _validate(profile.email);
    setState(
      () => _errors
        ..clear()
        ..addAll(errors),
    );
    if (errors.values.any((e) => e != null)) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .submitGuardianRequest(
            session.accountId,
            GuardianRequest(
              guardianName: _name.text.trim(),
              guardianEmail: _email.text.trim(),
              relationship: _relationship!,
            ),
            ownEmail: profile.email,
          );
      ref.invalidate(guardianRequestProvider);
      if (!mounted) return;
      context.go('/join/done');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to your guardian.')),
      );
    } on GuardianEmailInvalid catch (e) {
      if (mounted) setState(() => _errors['email'] = e.message);
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Ask your guardian',
      subtitle: const Text(
        'Because you are under 18, a parent or guardian needs to say yes.',
      ),
      // The account exists already; Back goes to the hub, not the form.
      onBack: () => context.go('/communities'),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Guardian full name',
              controller: _name,
              placeholder: 'e.g. Ruth Namuli',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              errorText: _errors['name'],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Guardian email',
              controller: _email,
              placeholder: 'guardian@example.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              errorText: _errors['email'],
            ),
            const SizedBox(height: 16),
            LabeledDropdown<String>(
              label: 'Relationship',
              value: _relationship,
              items: GuardianScreen.relationships,
              itemLabel: (r) => r,
              hint: 'Select',
              errorText: _errors['relationship'],
              onChanged: (r) => setState(() => _relationship = r),
            ),
            const SizedBox(height: 18),
            const InfoBanner(
              icon: Icons.mark_email_unread_outlined,
              child: Text(
                'We will email them a link to confirm. Until they do, you '
                'can browse your caregroups but cannot message mentors or '
                'other adults.',
              ),
            ),
          ],
        ),
      ),
      bottom: AppPrimaryButton(
        label: 'Send request',
        isLoading: _sending,
        onPressed: _send,
      ),
    );
  }
}
