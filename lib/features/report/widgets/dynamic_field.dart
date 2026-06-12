import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../campaign/campaign.dart';

/// Renders a single campaign-defined [ReportField] as the appropriate input.
/// Values are surfaced as strings to match how reports store them.
class DynamicField extends StatelessWidget {
  const DynamicField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final ReportField field;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (field.icon != null) ...[
              Icon(field.icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                field.required ? '${field.label} *' : field.label,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (field.helpText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(field.helpText!,
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        const SizedBox(height: 8),
        _input(context),
      ],
    );
  }

  Widget _input(BuildContext context) {
    switch (field.type) {
      case ReportFieldType.text:
      case ReportFieldType.multiline:
      case ReportFieldType.integer:
        return TextFormField(
          initialValue: value,
          keyboardType: field.type == ReportFieldType.integer
              ? TextInputType.number
              : TextInputType.text,
          inputFormatters: field.type == ReportFieldType.integer
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          minLines: field.type == ReportFieldType.multiline ? 3 : 1,
          maxLines: field.type == ReportFieldType.multiline ? 5 : 1,
          decoration: InputDecoration(hintText: field.hint),
          onChanged: onChanged,
        );

      case ReportFieldType.choice:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: field.choices.map((choice) {
            final selected = value == choice;
            return ChoiceChip(
              label: Text(choice),
              selected: selected,
              onSelected: (_) => onChanged(selected ? null : choice),
            );
          }).toList(),
        );

      case ReportFieldType.boolean:
        final selected = value == null ? null : value == 'true';
        return SegmentedButton<bool>(
          emptySelectionAllowed: true,
          segments: const [
            ButtonSegment(value: true, label: Text('Yes')),
            ButtonSegment(value: false, label: Text('No')),
          ],
          selected: selected == null ? <bool>{} : {selected},
          onSelectionChanged: (s) =>
              onChanged(s.isEmpty ? null : s.first.toString()),
        );
    }
  }
}
