import 'package:flutter/material.dart';

import 'data/appointment_details_model.dart';
import 'data/appointment_details_service.dart';
import 'data/appointment_service.dart';

class AppointmentEditScreen extends StatefulWidget {
  const AppointmentEditScreen({
    required this.details,
    required this.isDarkMode,
    super.key,
  });

  final AppointmentDetails details;
  final bool isDarkMode;

  @override
  State<AppointmentEditScreen> createState() => _AppointmentEditScreenState();
}

class _AppointmentEditScreenState extends State<AppointmentEditScreen> {
  static const _gold = Color(0xFFB89552);
  final _service = const AppointmentDetailsService();
  final _notesController = TextEditingController();
  late DateTime _selectedDateTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDateTime =
        widget.details.confirmedStartAt ??
        widget.details.requestedStartAt ??
        DateTime.now().add(const Duration(days: 1));
    _notesController.text = widget.details.adminNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await _service.update(
        appointmentId: widget.details.id,
        requestedStartAt: _selectedDateTime,
        confirmedStartAt: widget.details.status == 'confirmed'
            ? _selectedDateTime
            : null,
        adminNotes: _notesController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on AppointmentException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.isDarkMode ? Colors.black : Colors.white;
    final foreground = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF171717);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: foreground,
        centerTitle: true,
        title: const Text('تعديل الموعد'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _gold),
              ),
              leading: const Icon(Icons.calendar_month, color: _gold),
              title: const Text('التاريخ والوقت'),
              subtitle: Text(_formatDate(_selectedDateTime)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _selectDateTime,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              minLines: 4,
              maxLines: 7,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: 'ملاحظات الإدارة',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: widget.isDarkMode
                    ? const Color(0xFFD3B06B)
                    : const Color(0xFF171717),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} - '
        '${local.hour}:$minute';
  }
}
