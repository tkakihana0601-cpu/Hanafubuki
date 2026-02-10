import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/kif_record.dart';
import '../services/kif_library_service.dart';

class KifLibraryScreen extends StatefulWidget {
  const KifLibraryScreen({super.key});

  @override
  State<KifLibraryScreen> createState() => _KifLibraryScreenState();
}

class _KifLibraryScreenState extends State<KifLibraryScreen> {
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _keywordController.dispose();
    _instructorController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<KifLibraryService>();
    final tags = _tagController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final records = service.search(
      keyword: _keywordController.text.trim(),
      instructor: _instructorController.text.trim(),
      date: _selectedDate,
      tags: tags,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('棋譜ライブラリ'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSearchSection(),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const Text('該当する棋譜がありません')
          else
            ...records.map((record) => _buildRecordCard(context, record)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('棋譜登録'),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('検索', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _keywordController,
          decoration: const InputDecoration(
            labelText: '戦型/戦法・タイトル検索',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _instructorController,
          decoration: const InputDecoration(
            labelText: '指導者名',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _tagController,
          decoration: const InputDecoration(
            labelText: 'タグ (カンマ区切り)',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            setState(() => _selectedDate = picked);
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(
            _selectedDate == null
                ? '日付で絞り込む'
                : '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}',
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(BuildContext context, KifRecord record) {
    final service = context.read<KifLibraryService>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (record.isCloudSynced)
                  const Icon(Icons.cloud_done, color: Colors.green),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${record.instructorName} / ${record.date.year}-${record.date.month}-${record.date.day}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children:
                  record.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showKifDetail(context, record),
                  icon: const Icon(Icons.description),
                  label: const Text('棋譜を見る'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    service.syncToCloud(record.id);
                  },
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('クラウド保存'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final url = service.createShareUrl(record.id);
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('共有URLをコピーしました')),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('共有URL'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showKifDetail(BuildContext context, KifRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(record.kif)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final instructorController = TextEditingController();
    final tagController = TextEditingController();
    final kifController = TextEditingController();
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('棋譜を登録'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                  ),
                  TextField(
                    controller: instructorController,
                    decoration: const InputDecoration(labelText: '指導者名'),
                  ),
                  TextField(
                    controller: tagController,
                    decoration: const InputDecoration(labelText: 'タグ (カンマ区切り)'),
                  ),
                  TextField(
                    controller: kifController,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'KIF本文'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        date = picked;
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('対局日付'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final instructor = instructorController.text.trim();
                final kif = kifController.text.trim();
                if (title.isEmpty || instructor.isEmpty || kif.isEmpty) {
                  return;
                }
                final tags = tagController.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                context.read<KifLibraryService>().addRecord(
                      title: title,
                      instructorName: instructor,
                      date: date,
                      tags: tags,
                      kif: kif,
                    );
                Navigator.of(context).pop();
              },
              child: const Text('登録'),
            ),
          ],
        );
      },
    );
  }
}
