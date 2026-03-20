import 'package:flutter/material.dart';
import 'package:location_alarm/shared/data/models/travel_mode.dart';

class DepartureSettings extends StatefulWidget {
  const DepartureSettings({
    super.key,
    required this.travelMode,
    required this.bufferMinutes,
    required this.arrivalTime,
    required this.onTravelModeChanged,
    required this.onBufferChanged,
    required this.onArrivalTimeChanged,
  });

  final TravelMode travelMode;
  final int bufferMinutes;
  final DateTime? arrivalTime;
  final ValueChanged<TravelMode> onTravelModeChanged;
  final ValueChanged<int> onBufferChanged;
  final ValueChanged<DateTime> onArrivalTimeChanged;

  @override
  State<DepartureSettings> createState() => _DepartureSettingsState();
}

class _DepartureSettingsState extends State<DepartureSettings> {
  late TextEditingController _arrivalController;

  @override
  void initState() {
    super.initState();
    _arrivalController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateArrivalText();
  }

  @override
  void didUpdateWidget(DepartureSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.arrivalTime != widget.arrivalTime) {
      _updateArrivalText();
    }
  }

  void _updateArrivalText() {
    _arrivalController.text = widget.arrivalTime != null
        ? _formatDateTime(context, widget.arrivalTime!)
        : '';
  }

  @override
  void dispose() {
    _arrivalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          readOnly: true,
          controller: _arrivalController,
          decoration: const InputDecoration(
            labelText: 'Arrive by',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.schedule),
          ),
          onTap: () => _pickDateTime(context),
        ),
        const SizedBox(height: 24),
        Text('Travel mode', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<TravelMode>(
          segments: const [
            ButtonSegment(
              value: TravelMode.walk,
              label: Text('Walk'),
              icon: Icon(Icons.directions_walk),
            ),
            ButtonSegment(
              value: TravelMode.cycle,
              label: Text('Cycle'),
              icon: Icon(Icons.directions_bike),
            ),
            ButtonSegment(
              value: TravelMode.drive,
              label: Text('Drive'),
              icon: Icon(Icons.directions_car),
            ),
          ],
          selected: {widget.travelMode},
          onSelectionChanged: (s) => widget.onTravelModeChanged(s.first),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Arrive early by',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Expanded(
              child: Slider(
                value: widget.bufferMinutes.toDouble(),
                min: 0,
                max: 60,
                divisions: 60,
                label: '${widget.bufferMinutes} min',
                semanticFormatterCallback: (v) => '${v.round()} minutes early',
                onChanged: (v) => widget.onBufferChanged(v.round()),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '${widget.bufferMinutes} min',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: widget.arrivalTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: widget.arrivalTime != null
          ? TimeOfDay.fromDateTime(widget.arrivalTime!)
          : TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;
    widget.onArrivalTimeChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  String _formatDateTime(BuildContext context, DateTime dt) {
    final timeStr = TimeOfDay.fromDateTime(dt).format(context);
    final today = DateTime.now();
    if (dt.year == today.year &&
        dt.month == today.month &&
        dt.day == today.day) {
      return 'Today $timeStr';
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day) {
      return 'Tomorrow $timeStr';
    }
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${monthNames[dt.month - 1]} $timeStr';
  }
}
