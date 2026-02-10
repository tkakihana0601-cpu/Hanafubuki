import 'package:flutter/material.dart';
import '../models/instructor.dart';
import '../screens/instructor_profile_screen.dart';
import '../services/instructor_service.dart';
import '../services/favorite_instructor_service.dart';
import '../services/notification_service.dart';
import '../widgets/date_picker_widget.dart';
import 'package:provider/provider.dart';

class InstructorListScreen extends StatefulWidget {
  const InstructorListScreen({Key? key}) : super(key: key);

  @override
  State<InstructorListScreen> createState() => _InstructorListScreenState();
}

class _InstructorListScreenState extends State<InstructorListScreen> {
  String _searchQuery = '';
  int? _selectedPriceMax;
  double? _selectedMinRating;
  String _selectedSort = 'rating_desc';
  bool _availableOnly = false;
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _loadError;
  final Set<String> _compareIds = {};

  final List<Instructor> _allInstructors = [];

  late List<Instructor> _filteredInstructors;

  @override
  void initState() {
    super.initState();
    _filteredInstructors = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInstructors();
    });
  }

  Future<void> _loadInstructors() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final service = context.read<InstructorService>();
      final result = await service.fetchInstructors();
      if (!mounted) return;
      setState(() {
        _allInstructors
          ..clear()
          ..addAll(result);
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '読み込みに失敗しました';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredInstructors = _allInstructors.where((instructor) {
        // 検索キーワードでフィルタ
        final matchesSearch = _searchQuery.isEmpty ||
            instructor.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            instructor.bio.toLowerCase().contains(_searchQuery.toLowerCase());

        // 最大料金でフィルタ
        final matchesPrice = _selectedPriceMax == null ||
            instructor.pricePerSession <= _selectedPriceMax!;

        // 最小レーティングでフィルタ
        final matchesRating = _selectedMinRating == null ||
            instructor.rating >= _selectedMinRating!;

        // 空きありのみ
        final matchesAvailability = !_availableOnly ||
            instructor.schedule.any((slot) => slot.isAvailable);

        // 指定日での空き
        final matchesDate = _selectedDate == null ||
            instructor.schedule.any(
              (slot) =>
                  slot.isAvailable &&
                  DateUtils.isSameDay(slot.start, _selectedDate),
            );

        return matchesSearch &&
            matchesPrice &&
            matchesRating &&
            matchesAvailability &&
            matchesDate;
      }).toList();

      // ソート
      switch (_selectedSort) {
        case 'rating_desc':
          _filteredInstructors.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'price_asc':
          _filteredInstructors
              .sort((a, b) => a.pricePerSession.compareTo(b.pricePerSession));
          break;
        case 'price_desc':
          _filteredInstructors
              .sort((a, b) => b.pricePerSession.compareTo(a.pricePerSession));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('指導者を探す'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_compareIds.length >= 2)
            IconButton(
              onPressed: () => _showComparisonDialog(context),
              icon: const Icon(Icons.compare),
              tooltip: '比較',
            ),
          IconButton(
            onPressed: _loadInstructors,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_compareIds.isNotEmpty)
              Container(
                width: double.infinity,
                color: Colors.deepPurple.shade50,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('比較中: ${_compareIds.length}名'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(_compareIds.clear),
                      child: const Text('クリア'),
                    ),
                  ],
                ),
              ),
            // 検索バー
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.deepPurple.shade50,
              child: Column(
                children: [
                  // 検索フィールド
                  TextField(
                    onChanged: (value) {
                      _searchQuery = value;
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: '講師名や自己紹介で検索...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  DatePickerWidget(
                    initialDate: _selectedDate ?? DateTime.now(),
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 12),

                  // フィルターボタン
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showFilterDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.tune, size: 18),
                              SizedBox(width: 8),
                              Text('フィルター'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedPriceMax = null;
                            _selectedMinRating = null;
                            _availableOnly = false;
                            _selectedSort = 'rating_desc';
                            _selectedDate = null;
                          });
                          _applyFilters();
                        },
                        child: const Text('クリア'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ソート & 空きのみ
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(_selectedSort),
                          initialValue: _selectedSort,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'rating_desc',
                              child: Text('評価が高い順'),
                            ),
                            DropdownMenuItem(
                              value: 'price_asc',
                              child: Text('料金が安い順'),
                            ),
                            DropdownMenuItem(
                              value: 'price_desc',
                              child: Text('料金が高い順'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedSort = value);
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('空きのみ',
                              style: TextStyle(fontSize: 13)),
                          value: _availableOnly,
                          onChanged: (value) {
                            setState(() => _availableOnly = value);
                            _applyFilters();
                          },
                        ),
                      ),
                    ],
                  ),

                  // アクティブなフィルター表示
                  if (_selectedPriceMax != null ||
                      _selectedMinRating != null ||
                      _selectedDate != null ||
                      _availableOnly ||
                      _selectedSort != 'rating_desc')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_selectedPriceMax != null)
                            Chip(
                              label: Text('¥$_selectedPriceMax 以下'),
                              onDeleted: () {
                                setState(() => _selectedPriceMax = null);
                                _applyFilters();
                              },
                            ),
                          if (_selectedMinRating != null)
                            Chip(
                              label: Text('評価: $_selectedMinRating 以上'),
                              onDeleted: () {
                                setState(() => _selectedMinRating = null);
                                _applyFilters();
                              },
                            ),
                          if (_availableOnly)
                            Chip(
                              label: const Text('空きのみ'),
                              onDeleted: () {
                                setState(() => _availableOnly = false);
                                _applyFilters();
                              },
                            ),
                          if (_selectedDate != null)
                            Chip(
                              label: Text(
                                '${_selectedDate!.month}/${_selectedDate!.day} 空き',
                              ),
                              onDeleted: () {
                                setState(() => _selectedDate = null);
                                _applyFilters();
                              },
                            ),
                          if (_selectedSort != 'rating_desc')
                            Chip(
                              label: Text(
                                _selectedSort == 'price_asc'
                                    ? '料金: 安い順'
                                    : '料金: 高い順',
                              ),
                              onDeleted: () {
                                setState(() => _selectedSort = 'rating_desc');
                                _applyFilters();
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 指導者リスト
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _loadError!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadInstructors,
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              )
            else if (_filteredInstructors.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.people,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '該当する指導者がいません',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _filteredInstructors.length,
                itemBuilder: (context, index) {
                  return _buildInstructorCard(
                    context,
                    _filteredInstructors[index],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorCard(BuildContext context, Instructor instructor) {
    final isSelectedForCompare = _compareIds.contains(instructor.id);
    final favoriteService = context.watch<FavoriteInstructorService>();
    final isFavorite = favoriteService.isFavorite(instructor.id);
    final availableCount = _availableCountForDate(instructor);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                InstructorProfileScreen(instructor: instructor),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelectedForCompare ? Colors.deepPurple.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名前
                  Text(
                    instructor.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 自己紹介（2行まで）
                  Text(
                    instructor.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // レーティングと料金
                  Row(
                    children: [
                      // 星評価
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        instructor.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 料金
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '¥${instructor.pricePerSession}/時間',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 空き状況
                  if (availableCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        _selectedDate == null
                            ? '空き: $availableCount 枠'
                            : '${_selectedDate!.month}/${_selectedDate!.day} 空き: $availableCount 枠',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'お気に入り',
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.grey,
                  ),
                  onPressed: () {
                    favoriteService.toggleFavorite(instructor.id);
                    if (favoriteService.isFavorite(instructor.id) &&
                        availableCount > 0) {
                      context.read<NotificationService>().addNotification(
                            title: 'お気に入り指導者に空きあり',
                            message: '${instructor.name} に空き枠があります。',
                          );
                    }
                  },
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                IconButton(
                  tooltip: '比較に追加',
                  icon: Icon(
                    isSelectedForCompare
                        ? Icons.check_circle
                        : Icons.add_circle_outline,
                    color:
                        isSelectedForCompare ? Colors.deepPurple : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isSelectedForCompare) {
                        _compareIds.remove(instructor.id);
                      } else {
                        _compareIds.add(instructor.id);
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _availableCountForDate(Instructor instructor) {
    if (_selectedDate == null) {
      return instructor.schedule.where((slot) => slot.isAvailable).length;
    }
    return instructor.schedule
        .where((slot) =>
            slot.isAvailable && DateUtils.isSameDay(slot.start, _selectedDate))
        .length;
  }

  void _showComparisonDialog(BuildContext context) {
    final selected = _allInstructors
        .where((instructor) => _compareIds.contains(instructor.id))
        .toList();
    if (selected.length < 2) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('指導者の比較'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('項目')),
                  ...selected
                      .map((i) => DataColumn(label: Text(i.name)))
                      .toList(),
                ],
                rows: [
                  DataRow(
                    cells: [
                      const DataCell(Text('料金')),
                      ...selected
                          .map((i) => DataCell(Text('¥${i.pricePerSession}')))
                          .toList(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      const DataCell(Text('評価')),
                      ...selected
                          .map((i) =>
                              DataCell(Text(i.rating.toStringAsFixed(1))))
                          .toList(),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          _selectedDate == null
                              ? '空き枠(合計)'
                              : '${_selectedDate!.month}/${_selectedDate!.day} 空き',
                        ),
                      ),
                      ...selected
                          .map((i) => DataCell(
                                Text('${_availableCountForDate(i)}枠'),
                              ))
                          .toList(),
                    ],
                  ),
                ],
              ),
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

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('フィルター設定'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 料金フィルター
                  const Text(
                    '最大料金',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<int?>(
                    isExpanded: true,
                    value: _selectedPriceMax,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('指定なし')),
                      DropdownMenuItem(value: 2000, child: Text('¥2,000以下')),
                      DropdownMenuItem(value: 3000, child: Text('¥3,000以下')),
                      DropdownMenuItem(value: 4000, child: Text('¥4,000以下')),
                      DropdownMenuItem(value: 5000, child: Text('¥5,000以下')),
                      DropdownMenuItem(value: 6000, child: Text('¥6,000以下')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPriceMax = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // レーティングフィルター
                  const Text(
                    '最小評価',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<double?>(
                    isExpanded: true,
                    value: _selectedMinRating,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('指定なし')),
                      DropdownMenuItem(value: 4.0, child: Text('4.0以上')),
                      DropdownMenuItem(value: 4.5, child: Text('4.5以上')),
                      DropdownMenuItem(value: 4.7, child: Text('4.7以上')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedMinRating = value);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text('適用'),
            ),
          ],
        );
      },
    );
  }
}
