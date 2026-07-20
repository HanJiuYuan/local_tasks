import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class _CheckItem {
  const _CheckItem({
    required this.id,
    required this.title,
    this.emoji,
    this.done = false,
  });
  final int id;
  final String title;
  final String? emoji;
  final bool done;
  _CheckItem copyWith({bool? done}) =>
      _CheckItem(id: id, title: title, emoji: emoji, done: done ?? this.done);
}

class _CheckStore {
  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      path.join(dir.path, 'local_tasks.db'),
      version: 2,
      onCreate: (db, _) async {
        await db.execute('''CREATE TABLE IF NOT EXISTS tasks (
  id INTEGER PRIMARY KEY, title TEXT NOT NULL, tag TEXT, reminder TEXT,
  completed INTEGER NOT NULL DEFAULT 0, sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000))''');
        await db.execute('''
CREATE TABLE IF NOT EXISTS check_items (
  id INTEGER PRIMARY KEY, title TEXT NOT NULL, emoji TEXT,
  completed INTEGER NOT NULL DEFAULT 0, sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000))''');
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute('''CREATE TABLE IF NOT EXISTS check_items (
  id INTEGER PRIMARY KEY, title TEXT NOT NULL, emoji TEXT,
  completed INTEGER NOT NULL DEFAULT 0, sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000))''');
        }
      },
    );
    return _db!;
  }

  Future<List<_CheckItem>> load() async {
    final db = await database;
    var rows = await db.query('check_items', orderBy: 'sort_order ASC, id ASC');
    if (rows.isEmpty) {
      const defaults = [
        ('带牙刷', '🗝️'),
        ('带手机', '📱'),
        ('带钱包/身份证', '💳'),
        ('关好门窗', '🚪'),
        ('关好电源和燃气', '🔌'),
        ('顺手带走垃圾', '🗑️'),
      ];
      await db.transaction((txn) async {
        for (var i = 0; i < defaults.length; i++) {
          await txn.insert('check_items', {
            'title': defaults[i].$1,
            'emoji': defaults[i].$2,
            'sort_order': i,
          });
        }
      });
      rows = await db.query('check_items', orderBy: 'sort_order ASC, id ASC');
    }
    return rows
        .map(
          (r) => _CheckItem(
            id: r['id'] as int,
            title: r['title'] as String,
            emoji: r['emoji'] as String?,
            done: (r['completed'] as int? ?? 0) == 1,
          ),
        )
        .toList();
  }

  Future<void> save(List<_CheckItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var i = 0; i < items.length; i++) {
        await txn.update(
          'check_items',
          {'completed': items[i].done ? 1 : 0, 'sort_order': i},
          where: 'id = ?',
          whereArgs: [items[i].id],
        );
      }
    });
  }

  Future<int> add(String title, String emoji) async {
    final db = await database;
    return db.insert('check_items', {
      'title': title,
      'emoji': emoji.isEmpty ? null : emoji,
      'sort_order': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> delete(int id) async =>
      (await database).delete('check_items', where: 'id = ?', whereArgs: [id]);
}

class DepartureCheckPage extends StatefulWidget {
  const DepartureCheckPage({super.key});
  @override
  State<DepartureCheckPage> createState() => _DepartureCheckPageState();
}

class _DepartureCheckPageState extends State<DepartureCheckPage> {
  final _store = _CheckStore();
  final _title = TextEditingController();
  final _emoji = TextEditingController();
  var _items = const <_CheckItem>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _emoji.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _store.load();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _add() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final id = await _store.add(title, '');
    if (!mounted) return;
    setState(() {
      _items = [..._items, _CheckItem(id: id, title: title)];
      _title.clear();
      _emoji.clear();
    });
  }

  Future<void> _toggle(int index) async {
    final updated = [..._items];
    updated[index] = updated[index].copyWith(done: !updated[index].done);
    setState(() => _items = updated);
    await _store.save(updated);
  }

  Future<void> _delete(_CheckItem item) async {
    await _store.delete(item.id);
    if (mounted) {
      setState(() => _items = _items.where((e) => e.id != item.id).toList());
    }
  }

  Future<void> _reset() async {
    final reset = [for (final item in _items) item.copyWith(done: false)];
    setState(() => _items = reset);
    await _store.save(reset);
  }

  @override
  Widget build(BuildContext context) {
    final done = _items.where((e) => e.done).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 28),
              children: [
                _topBar(),
                const SizedBox(height: 22),
                _progress(done),
                const SizedBox(height: 22),
                _addField(),
                const SizedBox(height: 22),
                for (final item in _items) _itemCard(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: const Color(0xFF2F79FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'LocalTasks',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
      const SizedBox(height: 13),
      const Text(
        '保持井然有序。所有数据安全保存在您的设备上。',
        style: TextStyle(
          color: Color(0xFF5F6B7A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
  Widget _progress(int done) => Container(
    height: 88,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF3E6BFF), Color(0xFF5538F5)],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '离家前安全检查',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '确保随身物品备齐，水电气及门窗安全。',
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '检查进度',
              style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 11),
            ),
            Text(
              '$done / ${_items.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.refresh_rounded, size: 15),
          label: const Text('重置'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white24,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    ),
  );

  Widget _addField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _title,
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              hintText: '添加自定义检查项（如：带防晒霜、关空调）',
              hintStyle: const TextStyle(
                color: Color(0xFF9AA3B2),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE1E5EC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE1E5EC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF2F79FF),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          height: 48,
          child: FilledButton(
            onPressed: _add,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF989BA4),
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('+ 添加', softWrap: false),
          ),
        ),
      ],
    );
  }

  Widget _itemCard(_CheckItem item) {
    return InkWell(
      onTap: () => _toggle(_items.indexOf(item)),
      child: Container(
        height: 62,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1E5EC)),
        ),
        child: Row(
          children: [
            Icon(
              item.done ? Icons.check_circle : Icons.radio_button_unchecked,
              color:
                  item.done ? const Color(0xFF3E6BFF) : const Color(0xFF9AA7BA),
              size: 23,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  decoration: item.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (item.emoji != null)
              Text(item.emoji!, style: const TextStyle(fontSize: 18)),
            IconButton(
              onPressed: () => _delete(item),
              icon: const Icon(Icons.close, size: 17, color: Color(0xFF9AA3B2)),
            ),
          ],
        ),
      ),
    );
  }
}
