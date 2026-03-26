import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_track/models/health_record.dart';
import 'package:health_track/providers/records_provider.dart';
import 'package:health_track/services/health_kit_service.dart';

const _measurementTimes = [
  'Before Breakfast',
  'After Breakfast',
  'Before Lunch',
  'After Lunch',
  'Before Dinner',
  'After Dinner',
  'Bedtime',
];

class AddRecordScreen extends ConsumerStatefulWidget {
  const AddRecordScreen({super.key});

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _glucoseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _measurementTime = _measurementTimes.first;
  bool _saving = false;

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _heartRateCtrl.dispose();
    _glucoseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final record = HealthRecord(
        date: DateTime.now(),
        systolic: _systolicCtrl.text.trim().isEmpty
            ? null
            : _systolicCtrl.text.trim(),
        diastolic: _diastolicCtrl.text.trim().isEmpty
            ? null
            : _diastolicCtrl.text.trim(),
        heartRate: _heartRateCtrl.text.trim().isEmpty
            ? null
            : _heartRateCtrl.text.trim(),
        glucoseLevel: _glucoseCtrl.text.trim().isEmpty
            ? null
            : _glucoseCtrl.text.trim(),
        measurementTime: _measurementTime,
        notes:
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      final hkStatus = await ref.read(recordsProvider.notifier).addRecord(record);

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      _clearForm();

      final hkSuffix = switch (hkStatus) {
        HealthKitStatus.success => '  •  Apple Health saved',
        HealthKitStatus.failed => '  •  Apple Health: check permissions',
        HealthKitStatus.noData => '',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Record saved$hkSuffix'),
          backgroundColor: Colors.green,
        ),
      );
      ref.read(selectedTabProvider.notifier).state = 0;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearForm() {
    _systolicCtrl.clear();
    _diastolicCtrl.clear();
    _heartRateCtrl.clear();
    _glucoseCtrl.clear();
    _notesCtrl.clear();
    setState(() => _measurementTime = _measurementTimes.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Record')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionHeader('Blood Pressure'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      controller: _systolicCtrl,
                      label: 'Systolic (mmHg)',
                      hint: '120',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberField(
                      controller: _diastolicCtrl,
                      label: 'Diastolic (mmHg)',
                      hint: '80',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _NumberField(
                controller: _heartRateCtrl,
                label: 'Heart Rate (bpm)',
                hint: '72',
              ),
              const SizedBox(height: 20),
              const _SectionHeader('Glucose'),
              const SizedBox(height: 8),
              _NumberField(
                controller: _glucoseCtrl,
                label: 'Glucose Level (mg/dL)',
                hint: '95',
                decimal: true,
              ),
              const SizedBox(height: 20),
              const _SectionHeader('Details'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _measurementTime,
                decoration: const InputDecoration(
                  labelText: 'Measurement Time',
                  border: OutlineInputBorder(),
                ),
                items: _measurementTimes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _measurementTime = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool decimal;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        decimal
            ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            : FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }
}
