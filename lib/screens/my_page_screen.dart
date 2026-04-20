import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../services/reservation_service.dart';
import '../services/instructor_service.dart';
import '../services/notification_service.dart';
import '../models/schedule_slot.dart';
import '../models/reservation.dart';
import '../models/review.dart';
import '../models/transaction.dart';
import 'kif_library_screen.dart';
import 'instructor_quality_screen.dart';
import 'package:provider/provider.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String _userName = '';
  String _userEmail = '';
  String _userBio = '将棋初心者です。基礎から学びたいです。';
  Uint8List? _avatarBytes;
  bool _isPickingAvatar = false;
  String? _avatarUserId;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isEditing = false;
  bool _notificationsEnabled = true;
  bool _marketingEnabled = false;
  bool _initialized = false;
  bool _loadingInstructors = false;
  final Map<String, String> _instructorNameMap = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      _userName = user.name;
    }
    _userEmail = context.read<AuthService>().currentEmail ?? _userEmail;
    final userId = user?.id ?? 'user_001';
    _loadAvatarFromStorage(userId);
    _nameController.text = _userName;
    _bioController.text = _userBio;
    _loadInstructors();
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    if (_loadingInstructors) return;
    _loadingInstructors = true;
    final service = context.read<InstructorService>();
    if (service.instructors.isEmpty) {
      await service.fetchInstructors();
    }
    if (!mounted) return;
    setState(() {
      for (final instructor in service.instructors) {
        _instructorNameMap[instructor.id] = instructor.name;
      }
    });
    _loadingInstructors = false;
  }

  Future<void> _showInstructorRegistrationDialog() async {
    final bioController = TextEditingController(text: _userBio);
    final priceController = TextEditingController(text: '5000');
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('講師として登録'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '自己紹介',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '1回の料金（円）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final bio = bioController.text.trim();
                          final price =
                              int.tryParse(priceController.text.trim()) ?? 0;
                          if (bio.isEmpty || price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('自己紹介と料金を入力してください'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);
                          try {
                            await context
                                .read<AuthService>()
                                .registerAsInstructor(
                                  bio: bio,
                                  pricePerSession: price,
                                );
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            setState(() {
                              _userBio = bio;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('講師登録が完了しました'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('エラー: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('登録'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickAvatarImage() async {
    if (_isPickingAvatar) return;
    setState(() => _isPickingAvatar = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
      });
      final userId = context.read<AuthService>().currentUser?.id ?? 'user_001';
      await _saveAvatarToStorage(userId, bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の読み込みに失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingAvatar = false);
      }
    }
  }

  Future<void> _loadAvatarFromStorage(String userId) async {
    if (_avatarUserId == userId && _avatarBytes != null) return;
    _avatarUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('avatar_$userId');
    if (!mounted) return;
    if (data == null || data.isEmpty) {
      setState(() {
        _avatarBytes = null;
      });
      return;
    }
    try {
      final bytes = base64Decode(data);
      setState(() {
        _avatarBytes = bytes;
      });
    } catch (_) {
      setState(() {
        _avatarBytes = null;
      });
    }
  }

  Future<void> _saveAvatarToStorage(String userId, Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    final data = base64Encode(bytes);
    await prefs.setString('avatar_$userId', data);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final currentEmail =
        context.watch<AuthService>().currentEmail ?? _userEmail;
    final userId = user?.id ?? 'user_001';
    final paymentService = context.watch<PaymentService>();
    final reservationService = context.watch<ReservationService>();
    final reservations = reservationService.reservations
        .where((r) => r.userId == userId)
        .toList();
    final pastReservations = reservations
        .where((r) => r.end.isBefore(DateTime.now()))
        .toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    final transactions = paymentService.getUserTransactionHistory(userId);
    final totalSpent = transactions
        .where((t) => t.status == TransactionStatus.completed)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalLessons = reservations.length;
    final isInstructor = user?.isInstructor ?? false;
    final displayName = _isEditing ? _nameController.text : _userName;
    final displayBio = _isEditing ? _bioController.text : _userBio;
    final instructorId = _resolveInstructorId();
    final instructorName = _resolveInstructorName();

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // プロフィールセクション
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.deepPurple.shade300,
                            backgroundImage: _avatarBytes != null
                                ? MemoryImage(_avatarBytes!)
                                : null,
                            child: _avatarBytes == null
                                ? Text(
                                    (displayName.isNotEmpty
                                        ? displayName[0]
                                        : 'U'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isPickingAvatar ? null : _pickAvatarImage,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: _isPickingAvatar
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Colors.deepPurple,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentEmail.isEmpty
                                  ? 'user@example.com'
                                  : currentEmail,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              displayBio,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text(
                                    isInstructor ? '講師' : '生徒',
                                  ),
                                  backgroundColor: isInstructor
                                      ? Colors.orange.shade100
                                      : Colors.blue.shade100,
                                ),
                                if (user != null)
                                  Chip(
                                    label: const Text('ログイン中'),
                                    backgroundColor: Colors.green.shade100,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '名前',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '自己紹介',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 統計情報
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('総レッスン数', '$totalLessons'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          '総支払額',
                          '¥${totalSpent.toStringAsFixed(0)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // プロフィール編集ボタン
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (_isEditing) {
                                _userName = _nameController.text.trim();
                                _userBio = _bioController.text.trim();
                                context
                                    .read<AuthService>()
                                    .updateProfile(name: _userName);
                              }
                              _isEditing = !_isEditing;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(_isEditing ? '保存する' : 'プロフィール編集'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isEditing)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _nameController.text = _userName;
                                _bioController.text = _userBio;
                                _isEditing = false;
                              });
                            },
                            child: const Text('キャンセル'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!isInstructor)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showInstructorRegistrationDialog,
                        icon: const Icon(Icons.school),
                        label: const Text('講師として登録'),
                      ),
                    ),
                ],
              ),
            ),

            // クイックアクション
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('クイックアクション'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.event,
                          label: '予約一覧',
                          onTap: () => _showReservationList(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.history,
                          label: '支払い履歴',
                          onTap: () => _showPaymentHistory(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 予約履歴
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('最近の予約'),
                  const SizedBox(height: 8),
                  if (reservations.isEmpty)
                    const Text('予約履歴がありません')
                  else
                    ...reservations.take(3).map((reservation) {
                      final instructorName =
                          _instructorNameMap[reservation.instructorId] ??
                              reservation.instructorId;
                      final statusLabel = _reservationStatusLabel(
                        reservation.status,
                      );
                      final statusColor = _reservationStatusColor(
                        reservation.status,
                      );
                      return Card(
                        child: ListTile(
                          title: Text(instructorName),
                          subtitle: Text(
                            '${_formatDate(reservation.start)} / ${_formatTimeRange(reservation.start, reservation.end)}',
                          ),
                          trailing: Chip(
                            label: Text(statusLabel),
                            backgroundColor: statusColor.withValues(alpha: 0.2),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),

            // 指導対局履歴
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('指導対局履歴'),
                  const SizedBox(height: 8),
                  if (pastReservations.isEmpty)
                    const Text('過去の指導対局はありません')
                  else
                    ...pastReservations.map((reservation) {
                      final instructorName =
                          _instructorNameMap[reservation.instructorId] ??
                              reservation.instructorId;
                      final review = reservationService
                          .getReviewForReservation(reservation.id);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                instructorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDate(reservation.start)} / ${_formatTimeRange(reservation.start, reservation.end)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showKifDialog(
                                      context,
                                      reservation.id,
                                      instructorName,
                                    ),
                                    icon: const Icon(Icons.description),
                                    label: const Text('棋譜を見る'),
                                  ),
                                  if (review == null)
                                    ElevatedButton.icon(
                                      onPressed: () => _showReviewDialog(
                                        context,
                                        reservation,
                                        instructorName,
                                      ),
                                      icon: const Icon(Icons.rate_review),
                                      label: const Text('レビュー投稿'),
                                    )
                                  else
                                    Chip(
                                      label: Text('レビュー済み ★${review.rating}'),
                                      backgroundColor: Colors.green.shade100,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),

            // 設定セクション
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('設定'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('通知'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('お知らせメール'),
                    value: _marketingEnabled,
                    onChanged: (value) {
                      setState(() => _marketingEnabled = value);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    label: '詳細設定',
                    onTap: () => _showSettings(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.folder_open,
                    label: '棋譜ライブラリ',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const KifLibraryScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.help,
                    label: 'ヘルプ',
                    onTap: () => _showHelp(context),
                  ),
                ],
              ),
            ),

            if (isInstructor) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('指導者メニュー'),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.date_range,
                      label: '空き枠を一括登録',
                      onTap: () => _showBulkScheduleDialog(
                        context,
                        instructorId,
                      ),
                    ),
                    _buildMenuItem(
                      icon: Icons.repeat,
                      label: '定期スケジュール登録',
                      onTap: () => _showRecurringScheduleDialog(
                        context,
                        instructorId,
                      ),
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications,
                      label: '予約通知',
                      onTap: () => _showNotificationDialog(context),
                    ),
                    _buildMenuItem(
                      icon: Icons.bar_chart,
                      label: '月別売上',
                      onTap: () => _showMonthlySalesDialog(
                        context,
                        instructorId,
                        instructorName,
                      ),
                    ),
                    _buildMenuItem(
                      icon: Icons.emoji_events,
                      label: '指導者品質ダッシュボード',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const InstructorQualityScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // メニューセクション
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.history,
                    label: '支払い履歴',
                    onTap: () => _showPaymentHistory(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.event,
                    label: '予約一覧',
                    onTap: () => _showReservationList(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    label: '設定',
                    onTap: () => _showSettings(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.help,
                    label: 'ヘルプ',
                    onTap: () => _showHelp(context),
                  ),
                ],
              ),
            ),

            // ログアウトボタン
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'ログアウト',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  String _resolveInstructorId() {
    final user = context.read<AuthService>().currentUser;
    final name = user?.name;
    if (name == null || name.isEmpty) return 'inst_001';
    final match = _instructorNameMap.entries.firstWhere((e) => e.value == name,
        orElse: () => const MapEntry('', ''));
    return match.key.isEmpty ? 'inst_001' : match.key;
  }

  String _resolveInstructorName() {
    final user = context.read<AuthService>().currentUser;
    final name = user?.name;
    if (name != null && name.isNotEmpty) return name;
    return _instructorNameMap.values.isNotEmpty
        ? _instructorNameMap.values.first
        : '指導者';
  }

  Future<void> _showBulkScheduleDialog(
    BuildContext context,
    String instructorId,
  ) async {
    DateTime startDate = DateUtils.dateOnly(DateTime.now());
    DateTime endDate =
        DateUtils.dateOnly(DateTime.now().add(const Duration(days: 7)));
    TimeOfDay startTime = const TimeOfDay(hour: 19, minute: 0);
    int durationHours = 1;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('空き枠を一括登録'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('開始日'),
                    subtitle: Text(_formatDate(startDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked == null) return;
                      setState(() => startDate = DateUtils.dateOnly(picked));
                    },
                  ),
                  ListTile(
                    title: const Text('終了日'),
                    subtitle: Text(_formatDate(endDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate,
                        lastDate: DateTime.now().add(const Duration(days: 120)),
                      );
                      if (picked == null) return;
                      setState(() => endDate = DateUtils.dateOnly(picked));
                    },
                  ),
                  ListTile(
                    title: const Text('開始時刻'),
                    subtitle: Text(
                      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked == null) return;
                      setState(() => startTime = picked);
                    },
                  ),
                  Row(
                    children: [
                      const Text('時間(時間数)'),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: durationHours,
                        items: const [1, 2, 3]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('$value'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => durationHours = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (endDate.isBefore(startDate)) {
                      return;
                    }
                    final slots = <ScheduleSlot>[];
                    var date = startDate;
                    while (!date.isAfter(endDate)) {
                      final start = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        startTime.hour,
                        startTime.minute,
                      );
                      slots.add(
                        ScheduleSlot(
                          start: start,
                          end: start.add(Duration(hours: durationHours)),
                          isAvailable: true,
                        ),
                      );
                      date = date.add(const Duration(days: 1));
                    }
                    await context
                        .read<InstructorService>()
                        .addScheduleSlots(instructorId, slots);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('空き枠を登録しました')),
                    );
                  },
                  child: const Text('登録'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRecurringScheduleDialog(
    BuildContext context,
    String instructorId,
  ) async {
    int weekday = DateTime.tuesday;
    TimeOfDay startTime = const TimeOfDay(hour: 19, minute: 0);
    int durationHours = 1;
    int weeks = 8;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('定期スケジュール登録'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: weekday,
                    items: const [
                      DropdownMenuItem(
                          value: DateTime.monday, child: Text('月曜')),
                      DropdownMenuItem(
                          value: DateTime.tuesday, child: Text('火曜')),
                      DropdownMenuItem(
                          value: DateTime.wednesday, child: Text('水曜')),
                      DropdownMenuItem(
                          value: DateTime.thursday, child: Text('木曜')),
                      DropdownMenuItem(
                          value: DateTime.friday, child: Text('金曜')),
                      DropdownMenuItem(
                          value: DateTime.saturday, child: Text('土曜')),
                      DropdownMenuItem(
                          value: DateTime.sunday, child: Text('日曜')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => weekday = value);
                    },
                  ),
                  ListTile(
                    title: const Text('開始時刻'),
                    subtitle: Text(
                      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked == null) return;
                      setState(() => startTime = picked);
                    },
                  ),
                  Row(
                    children: [
                      const Text('時間(時間数)'),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: durationHours,
                        items: const [1, 2, 3]
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => durationHours = value);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('回数(週)'),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: weeks,
                        items: const [4, 8, 12]
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => weeks = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await context.read<InstructorService>().addRecurringSlots(
                          instructorId: instructorId,
                          weekday: weekday,
                          startTime: startTime,
                          duration: Duration(hours: durationHours),
                          weeks: weeks,
                        );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('定期スケジュールを登録しました')),
                    );
                  },
                  child: const Text('登録'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNotificationDialog(BuildContext context) {
    final notifications = context.watch<NotificationService>().items;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('予約通知'),
          content: SizedBox(
            width: double.maxFinite,
            child: notifications.isEmpty
                ? const Text('通知はありません')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return ListTile(
                        title: Text(item.title),
                        subtitle: Text(item.message),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showMonthlySalesDialog(
    BuildContext context,
    String instructorId,
    String instructorName,
  ) {
    final paymentService = context.read<PaymentService>();
    final transactions = paymentService.transactionHistory
        .where((t) => t.instructorId == instructorId)
        .where((t) => t.status == TransactionStatus.completed)
        .toList();
    final Map<String, double> totals = {};
    for (final t in transactions) {
      final key =
          '${t.createdAt.year}-${t.createdAt.month.toString().padLeft(2, '0')}';
      totals[key] = (totals[key] ?? 0) + t.amount;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$instructorName の月別売上'),
          content: SizedBox(
            width: double.maxFinite,
            child: totals.isEmpty
                ? const Text('売上データがありません')
                : ListView(
                    shrinkWrap: true,
                    children: totals.entries.map((entry) {
                      return ListTile(
                        title: Text(entry.key),
                        trailing: Text('¥${entry.value.toStringAsFixed(0)}'),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentHistory(BuildContext context) {
    final paymentService = context.read<PaymentService>();
    final transactions = paymentService.getUserTransactionHistory('user_001');

    showDialog(
      context: context,
      builder: (context) {
        if (transactions.isEmpty) {
          return AlertDialog(
            title: const Text('支払い履歴'),
            content: const Text('支払い履歴がありません'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('支払い履歴'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: transactions.map((transaction) {
                final statusColor = _getStatusColor(transaction.status);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            transaction.instructorName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              transaction.statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.formattedDate,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '¥${transaction.amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            transaction.paymentMethod,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (transaction.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            transaction.errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      const Divider(height: 16),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.pending => Colors.orange,
      TransactionStatus.completed => Colors.green,
      TransactionStatus.failed => Colors.red,
      TransactionStatus.cancelled => Colors.grey,
    };
  }

  void _showReservationList(BuildContext context) {
    final reservationService = context.read<ReservationService>();
    final userId = context.read<AuthService>().currentUser?.id ?? 'user_001';
    final reservations = reservationService.reservations
        .where((r) => r.userId == userId)
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('予約一覧'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: reservations.isEmpty
                  ? [const Text('予約がありません')]
                  : reservations.map((reservation) {
                      final instructorName =
                          _instructorNameMap[reservation.instructorId] ??
                              reservation.instructorId;
                      final statusLabel =
                          _reservationStatusLabel(reservation.status);
                      final statusColor =
                          _reservationStatusColor(reservation.status);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$instructorName - ${_formatDate(reservation.start)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatTimeRange(
                                reservation.start,
                                reservation.end,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Chip(
                                  label: Text(statusLabel),
                                  backgroundColor:
                                      statusColor.withValues(alpha: 0.2),
                                ),
                                const Spacer(),
                                if (reservation.status == 'confirmed' ||
                                    reservation.status == 'pending')
                                  OutlinedButton(
                                    onPressed: () async {
                                      await context
                                          .read<ReservationService>()
                                          .cancelReservation(reservation.id);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('キャンセルしました'),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    },
                                    child: const Text('キャンセル'),
                                  ),
                              ],
                            ),
                            const Divider(),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showKifDialog(
    BuildContext context,
    String reservationId,
    String instructorName,
  ) {
    final kif =
        context.read<ReservationService>().getKifForReservation(reservationId);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$instructorName の棋譜'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(kif),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showReviewDialog(
    BuildContext context,
    Reservation reservation,
    String instructorName,
  ) {
    final commentController = TextEditingController();
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('$instructorName へのレビュー'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('評価'),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: rating,
                        items: List.generate(5, (i) => i + 1)
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('★$value'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => rating = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'コメント',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final user = context.read<AuthService>().currentUser;
                    final review = Review(
                      id: 'review_${DateTime.now().millisecondsSinceEpoch}',
                      reservationId: reservation.id,
                      instructorId: reservation.instructorId,
                      userId: user?.id ?? 'user_001',
                      userName: user?.name ?? 'ゲスト',
                      rating: rating,
                      comment: commentController.text.trim(),
                      createdAt: DateTime.now(),
                    );
                    await context.read<ReservationService>().addReview(review);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('レビューを投稿しました')),
                    );
                  },
                  child: const Text('投稿'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('設定'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingItem('通知設定', Icons.notifications),
              _buildSettingItem('プライバシー', Icons.privacy_tip),
              _buildSettingItem('言語設定', Icons.language),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ヘルプ'),
          content: const Text(
            'よくある質問や使い方についての情報が表示されます。\n\n'
            '• レッスンの予約方法\n'
            '• キャンセルについて\n'
            '• 決済について\n'
            '• 技術的な問題\n',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ログアウト'),
          content: const Text('ログアウトしてもよろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                // AuthServiceのログアウト処理
                context.read<AuthService>().logout();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ログアウトしました')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('ログアウト'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingItem(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final dayOfWeek = weekdays[date.weekday % 7];
    return '${date.year}年${date.month}月${date.day}日（$dayOfWeek）';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final startTime =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startTime - $endTime';
  }

  String _reservationStatusLabel(String status) {
    return switch (status) {
      'pending' => '仮予約',
      'confirmed' => '確定',
      'cancelled' => 'キャンセル',
      'completed' => '完了',
      _ => status,
    };
  }

  Color _reservationStatusColor(String status) {
    return switch (status) {
      'pending' => Colors.orange,
      'confirmed' => Colors.green,
      'cancelled' => Colors.red,
      'completed' => Colors.blueGrey,
      _ => Colors.grey,
    };
  }
}
