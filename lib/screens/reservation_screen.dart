import 'package:flutter/material.dart';
import '../widgets/date_picker_widget.dart';
import '../widgets/time_picker_widget.dart';
import '../widgets/reservation_summary_card.dart';
import '../models/instructor.dart';
import '../models/schedule_slot.dart';
import 'payment_screen.dart';
import '../services/auth_service.dart';
import '../services/reservation_service.dart';
import '../services/instructor_service.dart';
import '../services/notification_service.dart';
import 'package:provider/provider.dart';

class ReservationScreen extends StatefulWidget {
  final Instructor? instructor;

  const ReservationScreen({
    Key? key,
    this.instructor,
  }) : super(key: key);

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  int _currentStep = 0;
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  bool _multiSlotEnabled = false;
  final Set<DateTime> _selectedTimes = {};
  bool isProcessing = false;
  bool _agreedToTerms = false;
  bool _initialized = false;
  bool _loadingInstructors = false;
  List<Instructor> _availableInstructors = [];
  Instructor? _selectedInstructor;
  final Map<String, Color> _instructorColorMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    if (widget.instructor != null) {
      _selectedInstructor = widget.instructor;
      _initialized = true;
      return;
    }
    _loadInstructors();
    _initialized = true;
  }

  Future<void> _loadInstructors() async {
    if (_loadingInstructors) return;
    setState(() => _loadingInstructors = true);
    final service = context.read<InstructorService>();
    if (service.instructors.isEmpty) {
      await service.fetchInstructors();
    }
    if (!mounted) return;
    setState(() {
      _availableInstructors = List.unmodifiable(service.instructors);
      if (_selectedInstructor == null && _availableInstructors.isNotEmpty) {
        _selectedInstructor = _availableInstructors.first;
      }
      _assignInstructorColors();
      _loadingInstructors = false;
    });
  }

  void _assignInstructorColors() {
    const palette = [
      Colors.teal,
      Colors.deepOrange,
      Colors.indigo,
      Colors.pink,
      Colors.green,
      Colors.purple,
      Colors.blueGrey,
    ];
    for (var i = 0; i < _availableInstructors.length; i++) {
      final instructor = _availableInstructors[i];
      _instructorColorMap[instructor.id] = palette[i % palette.length];
    }
    if (_selectedInstructor != null &&
        !_instructorColorMap.containsKey(_selectedInstructor!.id)) {
      _instructorColorMap[_selectedInstructor!.id] = Colors.teal;
    }
  }

  List<DateTime> _buildSelectedStartTimes() {
    if (_multiSlotEnabled) {
      final list = _selectedTimes.toList()..sort((a, b) => a.compareTo(b));
      return list;
    }
    if (_selectedDate == null || _selectedTime == null) {
      return [];
    }
    final time = _selectedTime!;
    return [
      DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        time.hour,
        time.minute,
      ),
    ];
  }

  Map<DateTime, List<Color>> _buildAvailabilityColorsByDate() {
    final map = <DateTime, List<Color>>{};
    final instructors = widget.instructor != null
        ? [_selectedInstructor].whereType<Instructor>().toList()
        : _availableInstructors;

    for (final instructor in instructors) {
      final color = _instructorColorMap[instructor.id] ?? Colors.teal;
      for (final slot in instructor.schedule) {
        if (!slot.isAvailable) continue;
        final dateKey = DateUtils.dateOnly(slot.start);
        final colors = map.putIfAbsent(dateKey, () => []);
        if (!colors.contains(color)) {
          colors.add(color);
        }
      }
    }

    return map;
  }

  ({Instructor instructor, ScheduleSlot slot})? _findEarliestSlot() {
    final now = DateTime.now();
    final instructors = widget.instructor != null
        ? [_selectedInstructor].whereType<Instructor>().toList()
        : _availableInstructors;
    Instructor? bestInstructor;
    ScheduleSlot? bestSlot;

    for (final instructor in instructors) {
      for (final slot in instructor.schedule) {
        if (!slot.isAvailable) continue;
        if (slot.start.isBefore(now)) continue;
        if (bestSlot == null || slot.start.isBefore(bestSlot.start)) {
          bestSlot = slot;
          bestInstructor = instructor;
        }
      }
    }

    if (bestInstructor == null || bestSlot == null) return null;
    return (instructor: bestInstructor, slot: bestSlot);
  }

  ({Instructor instructor, ScheduleSlot slot})? _findRecommendedSlot() {
    final userId = context.read<AuthService>().currentUser?.id ?? 'user_001';
    final history = context
        .read<ReservationService>()
        .reservations
        .where((r) => r.userId == userId)
        .toList();
    if (history.isEmpty) return null;

    final Map<int, int> hourCounts = {};
    for (final r in history) {
      hourCounts[r.start.hour] = (hourCounts[r.start.hour] ?? 0) + 1;
    }
    final preferredHour =
        hourCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final now = DateTime.now();
    final instructors = widget.instructor != null
        ? [_selectedInstructor].whereType<Instructor>().toList()
        : _availableInstructors;
    Instructor? bestInstructor;
    ScheduleSlot? bestSlot;

    for (final instructor in instructors) {
      for (final slot in instructor.schedule) {
        if (!slot.isAvailable) continue;
        if (slot.start.isBefore(now)) continue;
        if (slot.start.hour != preferredHour) continue;
        if (bestSlot == null || slot.start.isBefore(bestSlot.start)) {
          bestSlot = slot;
          bestInstructor = instructor;
        }
      }
    }

    if (bestInstructor == null || bestSlot == null) return null;
    return (instructor: bestInstructor, slot: bestSlot);
  }

  Widget _buildRecommendationCard() {
    final recommended = _findRecommendedSlot();
    if (recommended == null) return const SizedBox.shrink();
    final slot = recommended.slot;
    final label =
        '${recommended.instructor.name} ${slot.start.month}/${slot.start.day} ${_formatTime(slot.start)}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'おすすめ: $label',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedInstructor = recommended.instructor;
                _selectedDate = DateUtils.dateOnly(slot.start);
                _selectedTime = slot.start;
              });
            },
            child: const Text('選択'),
          ),
        ],
      ),
    );
  }

  String? _buildEarliestLabel() {
    final result = _findEarliestSlot();
    if (result == null) return null;
    final date = result.slot.start;
    final label =
        '${result.instructor.name} ${date.month}/${date.day} ${_formatTime(date)}';
    return label;
  }

  Instructor? get _currentInstructor => _selectedInstructor;

  Future<void> _handleReservation() async {
    if (!_canProceed(step: 2)) {
      _showErrorSnackBar('必要な項目を入力してください');
      return;
    }

    final instructor = _currentInstructor;
    if (instructor == null) {
      _showErrorSnackBar('講師を選択してください');
      return;
    }

    setState(() => isProcessing = true);

    final userId = context.read<AuthService>().currentUser?.id ?? 'user_001';
    final reservationService = context.read<ReservationService>();
    final starts = _buildSelectedStartTimes();
    final createdIds = <String>[];

    for (final start in starts) {
      final end = start.add(const Duration(hours: 1));
      final reservation = await reservationService.createReservation(
        userId,
        instructor.id,
        start,
        end,
      );
      if (reservation != null) {
        createdIds.add(reservation.id);
      }
    }

    if (mounted) {
      setState(() => isProcessing = false);
      if (createdIds.isNotEmpty) {
        final totalCount = createdIds.length;
        context.read<NotificationService>().addNotification(
              title: '新しい予約が入りました',
              message: totalCount == 1
                  ? '${instructor.name} / ${_formatDate(starts.first)} ${_formatTimeRange(starts.first, starts.first.add(const Duration(hours: 1)))}'
                  : '${instructor.name} の予約を$totalCount件作成しました。',
            );
        if (totalCount == 1) {
          _showReservationConfirmDialog(createdIds.first);
        } else {
          _showReservationConfirmDialogMulti(createdIds, starts);
        }
      } else {
        _showErrorSnackBar('予約の作成に失敗しました');
      }
    }
  }

  /// 決済画面へ遷移
  void _goToPaymentScreen(List<String> reservationIds, double amount) async {
    final instructor = _currentInstructor;
    if (instructor == null) {
      _showErrorSnackBar('講師を選択してください');
      return;
    }
    final paymentReferenceId = reservationIds.length == 1
        ? reservationIds.first
        : 'multi_${DateTime.now().millisecondsSinceEpoch}';
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: amount,
          reservationId: paymentReferenceId,
          instructorName: instructor.name,
          reservationIds: reservationIds,
        ),
      ),
    );

    if (result == true && mounted) {
      for (final id in reservationIds) {
        await context.read<ReservationService>().confirmReservation(id);
      }
      // 決済成功時
      Navigator.of(context).pop();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  bool _canProceed({required int step}) {
    if (_currentInstructor == null) {
      return false;
    }
    if (step == 0) {
      return _selectedDate != null;
    }
    if (step == 1) {
      return _multiSlotEnabled
          ? _selectedTimes.isNotEmpty
          : _selectedTime != null;
    }
    if (step == 2) {
      final hasTime =
          _multiSlotEnabled ? _selectedTimes.isNotEmpty : _selectedTime != null;
      return _selectedDate != null && hasTime && _agreedToTerms;
    }
    return false;
  }

  void _nextStep() {
    if (!_canProceed(step: _currentStep)) {
      _showErrorSnackBar('必要な項目を入力してください');
      return;
    }
    setState(() {
      if (_currentStep < 2) _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameTimeOfDay(DateTime a, DateTime b) {
    return a.hour == b.hour && a.minute == b.minute;
  }

  List<ScheduleSlot> _availableSlotsForDate(DateTime date) {
    final instructor = _currentInstructor;
    if (instructor == null) {
      return [];
    }
    return instructor.schedule
        .where((slot) => slot.isAvailable && _isSameDay(slot.start, date))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  void _showReservationConfirmDialog(String reservationId) {
    final instructor = _currentInstructor;
    if (instructor == null) {
      _showErrorSnackBar('講師を選択してください');
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('予約確認'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogRow('講師', instructor.name),
              _buildDialogRow('日付', _formatDate(_selectedDate!)),
              _buildDialogRow(
                '時間',
                '${_formatTime(_selectedTime!)} - ${_formatTime(_selectedTime!.add(const Duration(hours: 1)))}',
              ),
              _buildDialogRow('金額', '¥${instructor.pricePerSession}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _goToPaymentScreen(
                  [reservationId],
                  instructor.pricePerSession.toDouble(),
                );
              },
              child: const Text('決済に進む'),
            ),
          ],
        );
      },
    );
  }

  void _showReservationConfirmDialogMulti(
    List<String> reservationIds,
    List<DateTime> starts,
  ) {
    final instructor = _currentInstructor;
    if (instructor == null) {
      _showErrorSnackBar('講師を選択してください');
      return;
    }
    final totalAmount = instructor.pricePerSession * reservationIds.length;
    final timeLabels = starts
        .map((start) => _formatTimeRange(
              start,
              start.add(const Duration(hours: 1)),
            ))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('予約確認（複数枠）'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogRow('講師', instructor.name),
              _buildDialogRow('日付', _formatDate(_selectedDate!)),
              const SizedBox(height: 8),
              const Text('時間', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...timeLabels.map(
                (label) => Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              _buildDialogRow('枠数', '${reservationIds.length}枠'),
              _buildDialogRow('金額', '¥$totalAmount'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _goToPaymentScreen(
                  reservationIds,
                  totalAmount.toDouble(),
                );
              },
              child: const Text('決済に進む'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final dayOfWeek = weekdays[date.weekday % 7];
    return '${date.year}年${date.month}月${date.day}日（$dayOfWeek）';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予約'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _currentStep == 2 ? _handleReservation : _nextStep,
        onStepCancel: _prevStep,
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : (isLast ? _handleReservation : _nextStep),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isProcessing && isLast
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isLast ? '決済する' : '次へ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '戻る',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('日付選択'),
            isActive: _currentStep >= 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructorSelector(),
                const SizedBox(height: 12),
                _buildInstructorLegend(),
                const SizedBox(height: 12),
                _buildRecommendationCard(),
                const SizedBox(height: 16),
                DatePickerWidget(
                  initialDate: _selectedDate ?? DateTime.now(),
                  showViewModeToggle: true,
                  showEarliestLabel: true,
                  earliestLabel: _buildEarliestLabel(),
                  availabilityColorsByDate: _buildAvailabilityColorsByDate(),
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                      _selectedTime = null;
                      _selectedTimes.clear();
                    });
                  },
                ),
              ],
            ),
          ),
          Step(
            title: const Text('時間選択'),
            isActive: _currentStep >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('複数枠をまとめて予約'),
                  subtitle: const Text('空き枠を複数選択できます'),
                  value: _multiSlotEnabled,
                  onChanged: (value) {
                    setState(() {
                      _multiSlotEnabled = value;
                      if (_multiSlotEnabled &&
                          _selectedTime != null &&
                          _selectedDate != null) {
                        final time = _selectedTime!;
                        _selectedTimes.add(DateTime(
                          _selectedDate!.year,
                          _selectedDate!.month,
                          _selectedDate!.day,
                          time.hour,
                          time.minute,
                        ));
                      }
                      if (!_multiSlotEnabled && _selectedTimes.isNotEmpty) {
                        _selectedTime = _selectedTimes.first;
                      }
                    });
                  },
                ),
                if (_selectedDate == null)
                  const Text('日付を選択してください')
                else ...[
                  _buildAvailableSlots(),
                  const SizedBox(height: 12),
                  TimePickerWidget(
                    initialTime: _selectedTime ?? DateTime(2024, 1, 1, 10, 0),
                    onTimeSelected: (time) {
                      setState(() => _selectedTime = time);
                    },
                  ),
                  if (_multiSlotEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: _selectedTime == null
                              ? null
                              : () {
                                  final time = _selectedTime!;
                                  final start = DateTime(
                                    _selectedDate!.year,
                                    _selectedDate!.month,
                                    _selectedDate!.day,
                                    time.hour,
                                    time.minute,
                                  );
                                  setState(() {
                                    _selectedTimes.add(start);
                                  });
                                },
                          icon: const Icon(Icons.add),
                          label: const Text('選択した時間を追加'),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Step(
            title: const Text('確認'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedDate != null &&
                    _currentInstructor != null &&
                    _buildSelectedStartTimes().isNotEmpty)
                  ReservationSummaryCard(
                    instructorName: _currentInstructor!.name,
                    selectedTimes: _buildSelectedStartTimes(),
                    pricePerHour: _currentInstructor!.pricePerSession,
                  ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _agreedToTerms,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('利用規約に同意します'),
                  onChanged: (value) {
                    setState(() => _agreedToTerms = value ?? false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorHeader() {
    final instructor = _currentInstructor;
    if (instructor == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Text('講師を選択してください。'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepPurple.shade300,
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instructor.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '¥${instructor.pricePerSession}/時間',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.deepPurple.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorSelector() {
    if (widget.instructor != null) {
      return _buildInstructorHeader();
    }

    if (_loadingInstructors) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableInstructors.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Text('講師が見つかりません。'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Instructor>(
          initialValue: _selectedInstructor,
          decoration: const InputDecoration(
            labelText: '講師を選択',
            border: OutlineInputBorder(),
          ),
          items: _availableInstructors
              .map(
                (instructor) => DropdownMenuItem(
                  value: instructor,
                  child: Text(
                      '${instructor.name} / ¥${instructor.pricePerSession}'),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedInstructor = value;
              _selectedTime = null;
              _selectedTimes.clear();
            });
          },
        ),
        const SizedBox(height: 12),
        _buildInstructorHeader(),
      ],
    );
  }

  Widget _buildInstructorLegend() {
    final instructors = widget.instructor != null
        ? [_selectedInstructor].whereType<Instructor>().toList()
        : _availableInstructors;
    if (instructors.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: instructors.map((instructor) {
        final color = _instructorColorMap[instructor.id] ?? Colors.teal;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              instructor.name,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAvailableSlots() {
    if (_currentInstructor == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Text('講師を選択してください。'),
      );
    }
    final date = _selectedDate!;
    final slots = _availableSlotsForDate(date);

    if (slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Text('指定日の空きがありません。手動で時間を選択してください。'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '空き時間',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = _multiSlotEnabled
                ? _selectedTimes.any((t) => t.isAtSameMomentAs(slot.start))
                : (_selectedTime != null &&
                    _isSameTimeOfDay(_selectedTime!, slot.start));
            final label =
                '${_formatTime(slot.start)} - ${_formatTime(slot.end)}';
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  if (_multiSlotEnabled) {
                    if (isSelected) {
                      _selectedTimes
                          .removeWhere((t) => t.isAtSameMomentAs(slot.start));
                    } else {
                      _selectedTimes.add(slot.start);
                    }
                  } else {
                    _selectedTime = slot.start;
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_multiSlotEnabled && _selectedTimes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_selectedTimes.toList()..sort((a, b) => a.compareTo(b)))
                .map(
                  (time) => Chip(
                    label: Text(
                        '${_formatTime(time)} - ${_formatTime(time.add(const Duration(hours: 1)))}'),
                    onDeleted: () {
                      setState(() {
                        _selectedTimes
                            .removeWhere((t) => t.isAtSameMomentAs(time));
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
