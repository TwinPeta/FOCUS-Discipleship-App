import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/labeled_dropdown.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../domain/user_profile.dart';

/// The institutions for a country and type, from the server.
final institutionOptionsProvider = FutureProvider.autoDispose
    .family<List<String>, ({String country, InstitutionType type})>(
      (ref, key) => ref
          .watch(institutionRepositoryProvider)
          .names(country: key.country, type: key.type),
    );

/// Dropdown value meaning "my institute is not in the list".
const _notListed = '\u0000not-listed';

/// "I study at": University / Institute toggle, the institution list for
/// [country], and for university students the year of study. An institute
/// that is not listed can be typed in. Shared by the Join form (2) and Edit
/// profile (47). Accounts created as high school keep that type until they
/// pick another.
class InstitutionPicker extends ConsumerStatefulWidget {
  const InstitutionPicker({
    super.key,
    required this.country,
    required this.type,
    required this.name,
    required this.onTypeChanged,
    required this.onNameChanged,
    this.errorText,
    this.yearOfStudy,
    this.onYearChanged,
    this.yearErrorText,
  });

  final String country;
  final InstitutionType type;
  final String? name;

  /// Changing the type clears the chosen name (the caller resets it).
  final ValueChanged<InstitutionType> onTypeChanged;
  final ValueChanged<String?> onNameChanged;
  final String? errorText;

  /// University students only. Hidden when [onYearChanged] is null.
  final int? yearOfStudy;
  final ValueChanged<int?>? onYearChanged;
  final String? yearErrorText;

  @override
  ConsumerState<InstitutionPicker> createState() => _InstitutionPickerState();
}

class _InstitutionPickerState extends ConsumerState<InstitutionPicker> {
  late final _typed = TextEditingController(text: widget.name ?? '');
  bool _typing = false;

  @override
  void didUpdateWidget(InstitutionPicker old) {
    super.didUpdateWidget(old);
    if (old.type != widget.type || old.country != widget.country) {
      _typing = false;
      _typed.clear();
    }
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final institute = type == InstitutionType.institute;
    final loaded = ref.watch(
      institutionOptionsProvider((country: widget.country, type: type)),
    );
    final options = loaded.valueOrNull ?? const <String>[];
    final name = widget.name ?? '';
    // A saved institute that is not (or no longer) in the list was typed.
    final typing =
        institute &&
        (_typing ||
            (loaded.hasValue && name.isNotEmpty && !options.contains(name)));
    final label = type.label;

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
              label: 'Institute',
              value: InstitutionType.institute,
            ),
          ],
          onChanged: widget.onTypeChanged,
        ),
        const SizedBox(height: 16),
        LabeledDropdown<String>(
          label: label,
          value: typing ? _notListed : (options.contains(name) ? name : null),
          items: [...options, if (institute) _notListed],
          itemLabel: (n) => n == _notListed ? "My institute isn't listed" : n,
          hint: loaded.isLoading
              ? 'Loading...'
              : 'Select your ${label.toLowerCase()}',
          errorText: loaded.hasError
              ? 'Could not load the list. Check your connection and try again.'
              : (options.isEmpty && !loaded.isLoading && !institute
                    ? 'No ${label.toLowerCase()}s are listed here yet.'
                    : (typing ? null : widget.errorText)),
          onChanged: (value) {
            if (value == _notListed) {
              setState(() => _typing = true);
              widget.onNameChanged(
                _typed.text.trim().isEmpty ? null : _typed.text.trim(),
              );
            } else {
              setState(() => _typing = false);
              widget.onNameChanged(value);
            }
          },
        ),
        if (typing) ...[
          const SizedBox(height: 16),
          AppTextField(
            label: 'Institute name',
            controller: _typed,
            placeholder: 'e.g. Kampala Institute of Business',
            textCapitalization: TextCapitalization.words,
            errorText: widget.errorText,
            onChanged: (v) =>
                widget.onNameChanged(v.trim().isEmpty ? null : v.trim()),
          ),
        ],
        if (type == InstitutionType.university &&
            widget.onYearChanged != null) ...[
          const SizedBox(height: 16),
          LabeledDropdown<int>(
            label: 'Year of study',
            value: widget.yearOfStudy,
            items: yearsOfStudy,
            itemLabel: (y) => 'Year $y',
            hint: 'Select your year',
            errorText: widget.yearErrorText,
            onChanged: widget.onYearChanged!,
          ),
        ],
      ],
    );
  }
}
