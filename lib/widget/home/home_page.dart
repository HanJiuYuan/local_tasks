import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

enum _ComposerMode { none, tag, reminder }

class _TaskItem {
  const _TaskItem({
    required this.id,
    required this.title,
    this.tag,
    this.reminder,
    this.completed = false,
  });

  final int id;
  final String title;
  final String? tag;
  final String? reminder;
  final bool completed;

  _TaskItem copyWith({
    String? title,
    String? tag,
    String? reminder,
    bool? completed,
  }) {
    return _TaskItem(
      id: id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      reminder: reminder ?? this.reminder,
      completed: completed ?? this.completed,
    );
  }

  factory _TaskItem.fromDatabase(Map<String, Object?> row) {
    return _TaskItem(
      id: (row['id'] as int?) ?? 0,
      title: row['title'] as String? ?? '',
      tag: row['tag'] as String?,
      reminder: row['reminder'] as String?,
      completed: ((row['completed'] as int?) ?? 0) == 1,
    );
  }

  Map<String, Object?> toDatabase({required int sortOrder}) {
    final now = DateTime.now().millisecondsSinceEpoch;

    return {
      'id': id,
      'title': title,
      'tag': tag,
      'reminder': reminder,
      'completed': completed ? 1 : 0,
      'sort_order': sortOrder,
      'updated_at': now,
    };
  }
}

class _LocalTaskStore {
  static const _databaseName = 'local_tasks.db';
  static const _tableName = 'tasks';
  static List<_TaskItem>? _sessionCache;

  Database? _database;

  Future<List<_TaskItem>?> loadTasks() async {
    final cached = _sessionCache;
    if (cached != null) {
      return [...cached];
    }

    final database = await _open();
    await _deleteSeedTasks(database);

    final rows = await database.query(
      _tableName,
      orderBy: 'sort_order ASC, id DESC',
    );

    if (rows.isEmpty) {
      return null;
    }

    final tasks =
        rows
            .map(_TaskItem.fromDatabase)
            .where((task) => task.id > 0 && task.title.trim().isNotEmpty)
            .toList();
    _sessionCache = [...tasks];
    return tasks;
  }

  Future<void> saveTasks(List<_TaskItem> tasks) async {
    _sessionCache = [...tasks];
    final database = await _open();

    await database.transaction((txn) async {
      await txn.delete(_tableName);

      for (final indexedTask in tasks.indexed) {
        await txn.insert(
          _tableName,
          indexedTask.$2.toDatabase(sortOrder: indexedTask.$1),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<Database> _open() async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databasePath = path.join(documentsDirectory.path, _databaseName);

    _database = await openDatabase(
      databasePath,
      version: 2,
      onCreate: (database, version) async {
        await database.execute('''
CREATE TABLE $_tableName (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  tag TEXT,
  reminder TEXT,
  completed INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
)
''');
        await database.execute(
          'CREATE INDEX idx_tasks_sort_order ON $_tableName(sort_order)',
        );
        await database.execute(
          'CREATE INDEX idx_tasks_completed ON $_tableName(completed)',
        );
        await database.execute('''
CREATE TABLE check_items (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  emoji TEXT,
  completed INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
)
''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
CREATE TABLE IF NOT EXISTS check_items (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  emoji TEXT,
  completed INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
)
''');
        }
      },
    );

    return _database!;
  }

  Future<void> _deleteSeedTasks(Database database) async {
    await database.delete(
      _tableName,
      where:
          "(title = '21' AND tag IS NULL AND reminder IS NULL) OR "
          "(title = '22' AND tag IS NULL AND reminder IS NULL) OR "
          "(title = '111' AND tag IS NULL AND reminder = '今天 10:39')",
    );
  }
}

class _NotificationService {
  _NotificationService._();

  static final instance = _NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    timezone_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(localTimezone));
    } catch (_) {
      timezone.setLocalLocation(timezone.getLocation('Asia/Shanghai'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _plugin.initialize(settings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> scheduleTask(_TaskItem task) async {
    await initialize();

    final scheduledAt = _parseReminder(task.reminder);
    if (scheduledAt == null || !scheduledAt.isAfter(DateTime.now())) {
      await cancelTask(task.id);
      return;
    }

    await _plugin.zonedSchedule(
      task.id,
      'LocalTasks',
      task.title,
      timezone.TZDateTime.from(scheduledAt, timezone.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          '任务提醒',
          channelDescription: 'LocalTasks 本地任务提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelTask(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }

  Future<void> rescheduleActiveTasks(List<_TaskItem> tasks) async {
    await initialize();

    for (final task in tasks) {
      if (task.completed) {
        await cancelTask(task.id);
      } else {
        await scheduleTask(task);
      }
    }
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  DateTime? _parseReminder(String? reminder) {
    if (reminder == null || reminder.trim().isEmpty) {
      return null;
    }

    final text = reminder.trim();
    final now = DateTime.now();

    final fullDateMatch = RegExp(
      r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})\s+(\d{1,2}):(\d{2})$',
    ).firstMatch(text);
    if (fullDateMatch != null) {
      return DateTime(
        int.parse(fullDateMatch.group(1)!),
        int.parse(fullDateMatch.group(2)!),
        int.parse(fullDateMatch.group(3)!),
        int.parse(fullDateMatch.group(4)!),
        int.parse(fullDateMatch.group(5)!),
      );
    }

    final shortDateMatch = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})\s+(\d{1,2}):(\d{2})$',
    ).firstMatch(text);
    if (shortDateMatch != null) {
      var date = DateTime(
        now.year,
        int.parse(shortDateMatch.group(1)!),
        int.parse(shortDateMatch.group(2)!),
        int.parse(shortDateMatch.group(3)!),
        int.parse(shortDateMatch.group(4)!),
      );
      if (!date.isAfter(now)) {
        date = DateTime(
          now.year + 1,
          int.parse(shortDateMatch.group(1)!),
          int.parse(shortDateMatch.group(2)!),
          int.parse(shortDateMatch.group(3)!),
          int.parse(shortDateMatch.group(4)!),
        );
      }
      return date;
    }

    final relativeMatch = RegExp(
      r'^(今天|明天)\s+(\d{1,2}):(\d{2})$',
    ).firstMatch(text);
    if (relativeMatch != null) {
      final dayOffset = relativeMatch.group(1) == '明天' ? 1 : 0;
      return DateTime(
        now.year,
        now.month,
        now.day + dayOffset,
        int.parse(relativeMatch.group(2)!),
        int.parse(relativeMatch.group(3)!),
      );
    }

    return null;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const pageBackground = Color(0xFFF8F9FB);
  static const panelBackground = Color(0xFFF8F9FB);
  static const primaryBlue = Color(0xFF2F79FF);
  static const softBlue = Color(0xFF9CB7FF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF5F6B7A);
  static const textMuted = Color(0xFF9AA3B2);
  static const border = Color(0xFFE4E8EF);
  static const reminderRed = Color(0xFFFF1F32);
  static const reminderOrange = Color(0xFFFF6B1A);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _taskController = TextEditingController();
  final _tagController = TextEditingController();
  final _reminderController = TextEditingController();
  final _scrollController = ScrollController();
  final _taskStore = _LocalTaskStore();
  final _notificationService = _NotificationService.instance;

  var _mode = _ComposerMode.none;
  var _nextId = 1;
  final _removingTaskIds = <int>{};
  var _tasks = const <_TaskItem>[];

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    _loadLocalTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _tagController.dispose();
    _reminderController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setMode(_ComposerMode mode) {
    setState(() {
      _mode = _mode == mode ? _ComposerMode.none : mode;
    });
  }

  Future<void> _loadLocalTasks() async {
    final tasks = await _taskStore.loadTasks();
    if (!mounted) {
      return;
    }

    if (tasks == null) {
      await _taskStore.saveTasks(_tasks);
      return;
    }

    setState(() {
      _tasks = tasks;
      _nextId = _calculateNextId(tasks);
    });
    _notificationService.rescheduleActiveTasks(tasks);
  }

  int _calculateNextId(List<_TaskItem> tasks) {
    if (tasks.isEmpty) {
      return 1;
    }

    return tasks.map((task) => task.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  void _persistTasks() {
    _taskStore.saveTasks(_tasks);
  }

  void _addTask() {
    final title = _taskController.text.trim();
    if (title.isEmpty) {
      return;
    }

    final task = _TaskItem(
      id: _nextId++,
      title: title,
      tag:
          _tagController.text.trim().isEmpty
              ? null
              : _tagController.text.trim(),
      reminder:
          _reminderController.text.trim().isEmpty
              ? null
              : _reminderController.text.trim(),
    );

    setState(() {
      _tasks = [task, ..._tasks];
      _taskController.clear();
      _tagController.clear();
      _reminderController.clear();
      _mode = _ComposerMode.none;
    });
    _persistTasks();
    _notificationService.scheduleTask(task);
  }

  void _toggleCompleted(int id) {
    if (_removingTaskIds.contains(id)) {
      return;
    }

    _TaskItem? updatedTask;

    setState(() {
      _tasks = [
        for (final task in _tasks)
          if (task.id == id)
            updatedTask = task.copyWith(completed: !task.completed)
          else
            task,
      ];
    });
    _persistTasks();

    final task = updatedTask;
    if (task == null || task.completed) {
      _notificationService.cancelTask(id);
    } else {
      _notificationService.scheduleTask(task);
    }
  }

  void _deleteTask(int id) {
    _notificationService.cancelTask(id);

    setState(() {
      _removingTaskIds.add(id);
    });

    Future.delayed(const Duration(milliseconds: 230), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _removingTaskIds.remove(id);
        _tasks = _tasks.where((task) => task.id != id).toList();
      });
      _persistTasks();
    });
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (!mounted || date == null) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted || time == null) {
      return;
    }

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    setState(() {
      _reminderController.text = '${date.year}/$month/$day $hour:$minute';
    });
  }

  @override
  Widget build(BuildContext context) {
    final incompleteTasks = _tasks.where((task) => !task.completed).toList();
    final completedTasks = _tasks.where((task) => task.completed).toList();

    return Scaffold(
      backgroundColor: HomePage.pageBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              radius: const Radius.circular(16),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 28),
                children: [
                  const _Header(),
                  const SizedBox(height: 30),
                  _ComposerCard(
                    taskController: _taskController,
                    tagController: _tagController,
                    reminderController: _reminderController,
                    mode: _mode,
                    onAddTask: _addTask,
                    onModeChanged: _setMode,
                    onPickReminder: _pickReminder,
                  ),
                  const SizedBox(height: 34),
                  for (final task in incompleteTasks) ...[
                    _AnimatedTaskShell(
                      isRemoving: _removingTaskIds.contains(task.id),
                      bottomSpacing: 12,
                      child: _TaskCard(
                        task: task,
                        onToggle: () => _toggleCompleted(task.id),
                        onDelete: () => _deleteTask(task.id),
                      ),
                    ),
                  ],
                  if (completedTasks.isNotEmpty) const SizedBox(height: 18),
                  for (final task in completedTasks) ...[
                    _AnimatedTaskShell(
                      isRemoving: _removingTaskIds.contains(task.id),
                      bottomSpacing: 18,
                      child: _CompletedTask(
                        task: task,
                        onToggle: () => _toggleCompleted(task.id),
                        onDelete: () => _deleteTask(task.id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: HomePage.primaryBlue,
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
                color: HomePage.textPrimary,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        const Text(
          '保持井然有序。所有数据安全保存在您的设备上。',
          style: TextStyle(
            color: HomePage.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.taskController,
    required this.tagController,
    required this.reminderController,
    required this.mode,
    required this.onAddTask,
    required this.onModeChanged,
    required this.onPickReminder,
  });

  final TextEditingController taskController;
  final TextEditingController tagController;
  final TextEditingController reminderController;
  final _ComposerMode mode;
  final VoidCallback onAddTask;
  final ValueChanged<_ComposerMode> onModeChanged;
  final VoidCallback onPickReminder;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: HomePage.border.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withValues(alpha: 0.06),
              offset: const Offset(0, 14),
              blurRadius: 26,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _AddButton(onPressed: onAddTask),
                const SizedBox(width: 13),
                Expanded(
                  child: TextField(
                    key: const ValueKey('task-input'),
                    controller: taskController,
                    onSubmitted: (_) => onAddTask(),
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      color: HomePage.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                    decoration: const InputDecoration(
                      hintText: '需要做什么？',
                      hintStyle: TextStyle(
                        color: HomePage.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Padding(
              padding: const EdgeInsets.only(left: 58),
              child: Divider(
                color: const Color(0xFFEFF2F6).withValues(alpha: 0.85),
                height: 1,
                thickness: 1,
              ),
            ),
            const SizedBox(height: 13),
            Center(
              child: SizedBox(
                width: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ComposerAction(
                      icon: Icons.sell_outlined,
                      label: '添加标签',
                      selected: mode == _ComposerMode.tag,
                      selectedColor: HomePage.primaryBlue,
                      selectedBackground: const Color(0xFFEAF1FF),
                      onTap: () => onModeChanged(_ComposerMode.tag),
                    ),
                    _ComposerAction(
                      icon: Icons.notifications_none_rounded,
                      label: '设置提醒',
                      selected: mode == _ComposerMode.reminder,
                      selectedColor: HomePage.reminderOrange,
                      selectedBackground: const Color(0xFFFFF2E9),
                      onTap: () => onModeChanged(_ComposerMode.reminder),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 190),
              reverseDuration: const Duration(milliseconds: 140),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0, -0.08),
                  end: Offset.zero,
                ).animate(animation);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: switch (mode) {
                _ComposerMode.tag => Padding(
                  key: const ValueKey('tag-panel'),
                  padding: const EdgeInsets.only(top: 14),
                  child: _TagInput(controller: tagController),
                ),
                _ComposerMode.reminder => Padding(
                  key: const ValueKey('reminder-panel'),
                  padding: const EdgeInsets.only(top: 14),
                  child: _ReminderInput(
                    controller: reminderController,
                    onPickReminder: onPickReminder,
                  ),
                ),
                _ComposerMode.none => const SizedBox.shrink(
                  key: ValueKey('empty-panel'),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.selectedBackground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color selectedBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? selectedColor : HomePage.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: AnimatedScale(
              scale: selected ? 1.03 : 1,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: foreground, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTaskShell extends StatefulWidget {
  const _AnimatedTaskShell({
    required this.child,
    required this.isRemoving,
    required this.bottomSpacing,
  });

  final Widget child;
  final bool isRemoving;
  final double bottomSpacing;

  @override
  State<_AnimatedTaskShell> createState() => _AnimatedTaskShellState();
}

class _AnimatedTaskShellState extends State<_AnimatedTaskShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 170),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(_curve);

    if (widget.isRemoving) {
      _controller.value = 0;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedTaskShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRemoving && !oldWidget.isRemoving) {
      _controller.reverse();
    } else if (!widget.isRemoving && oldWidget.isRemoving) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _controller,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position: _slide,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(_curve),
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.bottomSpacing),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            tooltip: '添加任务',
            onPressed: widget.onPressed,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: HomePage.primaryBlue,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.add, size: 28),
          ),
        ),
      ),
    );
  }
}

class _TagInput extends StatelessWidget {
  const _TagInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 74, right: 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        key: const ValueKey('tag-input'),
        controller: controller,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          color: HomePage.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          hintText: '输入标签',
          hintStyle: const TextStyle(
            color: HomePage.textMuted,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: HomePage.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: HomePage.primaryBlue),
          ),
        ),
      ),
    );
  }
}

class _ReminderInput extends StatelessWidget {
  const _ReminderInput({
    required this.controller,
    required this.onPickReminder,
  });

  final TextEditingController controller;
  final VoidCallback onPickReminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 42, right: 10),
      child: TextField(
        key: const ValueKey('reminder-input'),
        controller: controller,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          color: Color(0xFFC2410C),
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.calendar_today_outlined,
            color: HomePage.reminderOrange,
            size: 19,
          ),
          suffixIcon: IconButton(
            tooltip: '选择提醒时间',
            onPressed: onPickReminder,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
          ),
          hintText: '年 / 月 / 日  --:--',
          hintStyle: const TextStyle(
            color: Color(0xFFC2410C),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          filled: true,
          fillColor: const Color(0xFFFFFBF7),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFFFE2C8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: HomePage.reminderOrange),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final _TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasDetails = task.tag != null || task.reminder != null;

    return Material(
      key: ValueKey('task-${task.id}-active'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: hasDetails ? 82 : 58),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomePage.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.025),
                offset: const Offset(0, 7),
                blurRadius: 14,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: _EmptyCheckCircle(),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          color: HomePage.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: 0,
                        ),
                      ),
                      if (hasDetails) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            if (task.tag != null)
                              _BadgeEntrance(child: _TagBadge(text: task.tag!)),
                            if (task.reminder != null)
                              _BadgeEntrance(
                                child: _ReminderBadge(text: task.reminder!),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _DeleteButton(onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCheckCircle extends StatelessWidget {
  const _EmptyCheckCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF9AA7BA), width: 1.7),
      ),
    );
  }
}

class _BadgeEntrance extends StatelessWidget {
  const _BadgeEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(scale: 0.92 + value * 0.08, child: child),
        );
      },
      child: child,
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sell_outlined,
            color: HomePage.primaryBlue,
            size: 13,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: HomePage.primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderBadge extends StatelessWidget {
  const _ReminderBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: HomePage.reminderRed,
            size: 13,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: HomePage.reminderRed,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        tooltip: '删除任务',
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFC9D0DC),
          size: 18,
        ),
      ),
    );
  }
}

class _CompletedTask extends StatelessWidget {
  const _CompletedTask({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final _TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('task-${task.id}-completed'),
      padding: const EdgeInsets.only(left: 18),
      child: Row(
        children: [
          GestureDetector(onTap: onToggle, child: const _CompletedCheck()),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: onToggle,
              child: Text(
                task.title,
                style: const TextStyle(
                  color: HomePage.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: HomePage.textMuted,
                  decorationThickness: 1.8,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          _DeleteButton(onPressed: onDelete),
        ],
      ),
    );
  }
}

class _CompletedCheck extends StatelessWidget {
  const _CompletedCheck();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFEAF1FF),
          border: Border.all(color: HomePage.primaryBlue, width: 1.5),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: HomePage.primaryBlue,
          size: 13,
        ),
      ),
    );
  }
}
