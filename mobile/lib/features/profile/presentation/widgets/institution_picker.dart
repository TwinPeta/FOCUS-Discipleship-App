import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/providers/repository_providers.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/labeled_dropdown.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../domain/user_profile.dart';

/// "I study at": University / High school toggle plus the institution list
/// for [country]. Shared by the Join form (2) and Edit profile (47).
/// The institutions for a country and type, from the server.
final institutionOptionsProvider = FutureProvider.autoDispose
    .family<List<String>, ({String country, InstitutionType type})>(
      (ref, key) => ref
          .watch(institutionRepositoryProvider)
          .names(country: key.country, type: key.type),
    );

class InstitutionPicker extends ConsumerWidget {
  const InstitutionPicker({
    super.key,
    required this.country,
    required this.type,
    required this.name,
    required this.onTypeChanged,
    required this.onNameChanged,
    this.errorText,
  });

  final String country;
  final InstitutionType type;
  final String? name;

  /// Changing the type clears the chosen name (the caller resets it).
  final ValueChanged<InstitutionType> onTypeChanged;
  final ValueChanged<String?> onNameChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final university = type == InstitutionType.university;
    final loaded = ref.watch(
      institutionOptionsProvider((country: country, type: type)),
    );
    final options = loaded.valueOrNull ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('I study at', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        SegmentedToggle<InstitutionType>(
          value: type,
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
          onChanged: onTypeChanged,
        ),
        const SizedBox(height: 16),
        LabeledDropdown<String>(
          label: university ? 'University' : 'High school',
          value: options.contains(name) ? name : null,
          items: options,
          itemLabel: (n) => n,
          hint: loaded.isLoading
              ? 'Loading...'
              : university
              ? 'Select your university'
              : 'Select your high school',
          errorText: loaded.hasError
              ? 'Could not load the list. Check your connection and try again.'
              : (options.isEmpty && !loaded.isLoading
                    ? 'No schools are listed here yet.'
                    : errorText),
          onChanged: onNameChanged,
        ),
      ],
    );
  }
}
