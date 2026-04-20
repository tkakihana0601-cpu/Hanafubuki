import 'package:flutter/material.dart';
import '../models/instructor.dart';
import '../models/schedule_slot.dart';
import '../services/favorite_instructor_service.dart';
import '../services/notification_service.dart';
import '../widgets/instructor_profile_header.dart';
import '../widgets/review_card.dart';
import '../widgets/schedule_view.dart';
import 'reservation_screen.dart';
import 'package:provider/provider.dart';

class InstructorProfileScreen extends StatefulWidget {
  final String? instructorId;
  final Instructor? instructor;

  const InstructorProfileScreen({
    Key? key,
    this.instructorId,
    this.instructor,
  }) : super(key: key);

  @override
  State<InstructorProfileScreen> createState() =>
      _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // ダミー講師データ
  late Instructor instructor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeInstructor();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeInstructor() {
    // 渡されたinstructorオブジェクトを使用、なければダミーデータを生成
    if (widget.instructor != null) {
      instructor = widget.instructor!;
      return;
    }

    // ダミーデータを生成
    final now = DateTime.now();
    instructor = Instructor(
      id: widget.instructorId ?? '1',
      name: '田中太郎',
      bio: '将棋のプロ棋士です。初心者から上級者まで幅広く指導できます。',
      rating: 4.8,
      pricePerSession: 5000,
      schedule: [
        ScheduleSlot(
          start: now.add(const Duration(days: 1, hours: 10)),
          end: now.add(const Duration(days: 1, hours: 11)),
          isAvailable: true,
        ),
        ScheduleSlot(
          start: now.add(const Duration(days: 1, hours: 14)),
          end: now.add(const Duration(days: 1, hours: 15)),
          isAvailable: true,
        ),
        ScheduleSlot(
          start: now.add(const Duration(days: 2, hours: 10)),
          end: now.add(const Duration(days: 2, hours: 11)),
          isAvailable: true,
        ),
        ScheduleSlot(
          start: now.add(const Duration(days: 2, hours: 15)),
          end: now.add(const Duration(days: 2, hours: 16)),
          isAvailable: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteService = context.watch<FavoriteInstructorService>();
    final isFavorite = favoriteService.isFavorite(instructor.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('講師プロフィール'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            tooltip: 'お気に入り',
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () {
              favoriteService.toggleFavorite(instructor.id);
              if (favoriteService.isFavorite(instructor.id) &&
                  instructor.schedule.any((s) => s.isAvailable)) {
                context.read<NotificationService>().addNotification(
                      title: 'お気に入り指導者に空きあり',
                      message: '${instructor.name} に空き枠があります。',
                    );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // プロフィールヘッダー
          InstructorProfileHeader(instructor: instructor),

          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.deepPurple,
              indicatorWeight: 2,
              tabs: const [
                Tab(text: '概要'),
                Tab(text: 'レビュー'),
                Tab(text: 'スケジュール'),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 概要タブ
                _buildOverviewTab(),
                // レビュータブ
                _buildReviewTab(),
                // スケジュールタブ
                ScheduleView(schedule: instructor.schedule),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReservationScreen(
                  instructor: instructor,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            '予約する',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 自己紹介
          const Text(
            '自己紹介',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            instructor.bio,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // 資格・経歴
          const Text(
            '資格・経歴',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildQualificationItem(
            '日本将棋協会プロ棋士',
            '${instructor.rating}段',
          ),
          _buildQualificationItem(
            '教示経歴',
            '10年以上',
          ),
          const SizedBox(height: 24),

          // 指導スタイル
          const Text(
            '指導スタイル',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildStyleTag('初心者歓迎'),
          _buildStyleTag('棋力向上'),
          _buildStyleTag('楽しさ重視'),
          _buildStyleTag('丁寧な解説'),
          const SizedBox(height: 24),

          // 対応時間帯
          const Text(
            '対応時間帯',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '平日: 10:00〜22:00\n土日祝: 9:00〜22:00',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    // ダミーレビュー
    final reviews = [
      {
        'userName': 'ユーザーA',
        'rating': 5,
        'text': 'とても丁寧に教えてくださいました。棋力が向上した実感があります。',
        'date': '2024年1月15日',
      },
      {
        'userName': 'ユーザーB',
        'rating': 5,
        'text': '初心者ですが、わかりやすく指導してくれて助かります。',
        'date': '2024年1月10日',
      },
      {
        'userName': 'ユーザーC',
        'rating': 4,
        'text': '棋力向上に必要なポイントを教えてくれます。',
        'date': '2024年1月5日',
      },
      {
        'userName': 'ユーザーD',
        'rating': 5,
        'text': 'プロの視点からアドバイスをもらえるので非常に参考になります。',
        'date': '2024年1月1日',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return ReviewCard(
          userName: review['userName'] as String,
          rating: review['rating'] as int,
          reviewText: review['text'] as String,
          date: review['date'] as String,
        );
      },
    );
  }

  Widget _buildQualificationItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleTag(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.deepPurple.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
