import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/labeled_dropdown.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../data/institution_data.dart';
import '../../domain/user_profile.dart';

/// "I study at": University / High school toggle plus the institution list
/// for [country]. Shared by the Join form (2) and Edit profile (47).
class InstitutionPicker extends StatelessWidget {
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

  static List<String> optionsFor(String country, InstitutionType type) {
    final byCountry = type == InstitutionType.university
        ? InstitutionData.universitiesByCountry
        : InstitutionData.highSchoolsByCountry;
    return byCountry[country] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final university = type == InstitutionType.university;
    final options = optionsFor(country, type);
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
          hint: university
              ? 'Select your university'
              : 'Select your high school',
          errorText: errorText,
          onChanged: onNameChanged,
        ),
      ],
    );
  }
}
