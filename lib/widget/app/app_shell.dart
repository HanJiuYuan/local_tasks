import 'package:flutter/material.dart';
import 'package:local_tasks/widget/departure/departure_check_page.dart';
import 'package:local_tasks/widget/home/home_page.dart';
import 'package:local_tasks/widget/nutrition/nutrition_page.dart';
import 'package:local_tasks/widget/workout/workout_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final List<Widget?> _pages;
  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pages = [const HomePage(), null, null, null];
  }

  Widget _createPage(int index) {
    return switch (index) {
      0 => const HomePage(),
      1 => const NutritionPage(),
      2 => const DepartureCheckPage(),
      _ => const WorkoutAssistantPage(),
    };
  }

  void _selectPage(int index) {
    setState(() {
      _pages[index] ??= _createPage(index);
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: IndexedStack(
        index: _selectedIndex,
        children: [for (final page in _pages) page ?? const SizedBox.shrink()],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDDF7EE),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              color: const Color(0xFF5F6B7A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color:
                  states.contains(WidgetState.selected)
                      ? const Color(0xFF00B981)
                      : const Color(0xFF7B8798),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectPage,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.task_alt_outlined),
              selectedIcon: Icon(Icons.task_alt_rounded),
              label: '日常待办',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant_rounded),
              label: '饮食记录',
            ),
            NavigationDestination(
              icon: Icon(Icons.verified_user_outlined),
              selectedIcon: Icon(Icons.verified_user_rounded),
              label: '出发检查',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center_rounded),
              label: '健身助手',
            ),
          ],
        ),
      ),
    );
  }
}
