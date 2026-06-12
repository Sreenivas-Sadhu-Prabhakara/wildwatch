import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../app_scope.dart';
import '../../campaign/campaign.dart';
import '../../models/report.dart';
import '../../models/report_prefill.dart';
import 'widgets/dynamic_field.dart';
import 'widgets/location_picker.dart';
import 'widgets/photo_field.dart';

class NewReportScreen extends StatefulWidget {
  const NewReportScreen({super.key, this.prefill});

  /// Optional values to seed the form, e.g. from a deep link / Shortcut.
  final ReportPrefill? prefill;

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> {
  String? _speciesId;
  String? _photoPath;
  GeoPoint? _location;
  DateTime _observedAt = DateTime.now();
  bool _submitting = false;
  bool _contactExpanded = false;

  final _locality = TextEditingController();
  final _notes = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final Map<String, String> _fieldValues = {};

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _speciesId = p.speciesId;
      _location = p.location;
      if (p.localityText != null) _locality.text = p.localityText!;
      if (p.notes != null) _notes.text = p.notes!;
      _fieldValues.addAll(p.fieldValues);
      if (p.contact != null) {
        _name.text = p.contact!.name ?? '';
        _phone.text = p.contact!.phone ?? '';
        _email.text = p.contact!.email ?? '';
        _contactExpanded = !p.contact!.isEmpty;
      }
    }
  }

  @override
  void dispose() {
    _locality.dispose();
    _notes.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Campaign get _campaign => AppScope.of(context).campaign;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _observedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_observedAt),
    );
    if (!mounted) return;
    setState(() {
      _observedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _observedAt.hour,
        time?.minute ?? _observedAt.minute,
      );
    });
  }

  String? _validate() {
    if (_speciesId == null) {
      return 'Please choose what you saw.';
    }
    if (_campaign.requirePhoto && _photoPath == null) {
      return 'A photo is required for this report.';
    }
    if (_location == null && _locality.text.trim().isEmpty) {
      return 'Add a location: use the map pin or type a landmark/address.';
    }
    for (final f in _campaign.fields) {
      if (f.required && (_fieldValues[f.key]?.isEmpty ?? true)) {
        return 'Please answer: ${f.label}';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      _snack(error);
      return;
    }
    setState(() => _submitting = true);

    final species = _campaign.speciesById(_speciesId);
    final report = Report(
      id: const Uuid().v4(),
      campaignId: _campaign.id,
      createdAt: DateTime.now(),
      observedAt: _observedAt,
      speciesId: _speciesId,
      speciesName: species?.displayName,
      location: _location,
      localityText: _locality.text.trim().isEmpty ? null : _locality.text.trim(),
      photoPath: _photoPath,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      fieldValues: Map.of(_fieldValues),
      contact: ContactInfo(
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      ),
    );

    final result = await AppScope.of(context).submissionManager.submitNow(report);
    if (!mounted) return;
    setState(() => _submitting = false);

    await _showOutcome(report, result.message);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showOutcome(Report report, String? message) {
    final (IconData icon, String title, String body) = switch (report.status) {
      ReportStatus.submitted => (
          Icons.check_circle,
          'Report sent',
          message ?? _campaign.locale.thanksMessage,
        ),
      ReportStatus.queued => (
          Icons.schedule,
          'Saved — will send when online',
          'You appear to be offline. Your report is safe and will be sent '
              'automatically when you reconnect.',
        ),
      _ => (
          Icons.error_outline,
          'Could not send yet',
          message ??
              'Something went wrong. Your report is saved in “My reports”, '
                  'where you can try again.',
        ),
    };
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon),
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final campaign = _campaign;
    final scheme = Theme.of(context).colorScheme;
    final selectedSpecies = campaign.speciesById(_speciesId);

    return Scaffold(
      appBar: AppBar(title: Text(campaign.locale.reportTitle)),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _SectionLabel(campaign.locale.speciesPrompt),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: campaign.species.map((s) {
                final selected = _speciesId == s.id;
                return ChoiceChip(
                  label: Text(s.commonName),
                  selected: selected,
                  avatar: s.isPrimaryTarget
                      ? const Icon(Icons.priority_high, size: 16)
                      : null,
                  onSelected: (_) => setState(() => _speciesId = s.id),
                );
              }).toList(),
            ),
            if (selectedSpecies?.idHint != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _InfoNote(selectedSpecies!.idHint!),
              ),
            const SizedBox(height: 24),

            _SectionLabel(campaign.locale.photoPrompt),
            PhotoField(
              photoPath: _photoPath,
              onChanged: (p) => setState(() => _photoPath = p),
            ),
            const SizedBox(height: 24),

            _SectionLabel(campaign.locale.locationPrompt),
            LocationPicker(
              value: _location,
              onChanged: (p) => setState(() => _location = p),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locality,
              decoration: const InputDecoration(
                labelText: 'Landmark or address (optional)',
                hintText: 'e.g. near Ayala Triangle, Makati',
                prefixIcon: Icon(Icons.signpost_outlined),
              ),
            ),
            const SizedBox(height: 24),

            _SectionLabel('When did you see it?'),
            Card(
              child: ListTile(
                leading: Icon(Icons.event, color: scheme.primary),
                title: Text(
                  DateFormat('EEE, d MMM yyyy · h:mm a').format(_observedAt),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickDateTime,
              ),
            ),
            const SizedBox(height: 24),

            for (final field in campaign.fields) ...[
              DynamicField(
                field: field,
                value: _fieldValues[field.key],
                onChanged: (v) => setState(() {
                  if (v == null) {
                    _fieldValues.remove(field.key);
                  } else {
                    _fieldValues[field.key] = v;
                  }
                }),
              ),
              const SizedBox(height: 24),
            ],

            _SectionLabel('Anything else? (optional)'),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Colour, size, direction it went, etc.',
              ),
            ),
            const SizedBox(height: 16),

            _ContactSection(
              expanded: _contactExpanded,
              onExpansionChanged: (v) => setState(() => _contactExpanded = v),
              name: _name,
              phone: _phone,
              email: _email,
              agencyName: campaign.agency.shortName,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_submitting ? 'Sending…' : campaign.locale.submitLabel),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Sends to ${campaign.agency.name}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({
    required this.expanded,
    required this.onExpansionChanged,
    required this.name,
    required this.phone,
    required this.email,
    required this.agencyName,
  });

  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final String agencyName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        leading: const Icon(Icons.person_outline),
        title: const Text('Your contact details (optional)'),
        subtitle: Text('Leave blank to stay anonymous',
            style: Theme.of(context).textTheme.bodySmall),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            'Only shared with $agencyName so they can follow up if needed.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
