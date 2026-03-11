import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import 'home/home_screen.dart';
import 'todo/todo_screen.dart';
import 'habits/habits_screen.dart';
import 'pomodoro/pomodoro_screen.dart';
import 'more/more_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    TodoScreen(),
    HabitsScreen(),
    PomodoroScreen(),
    MoreScreen(),
  ];

  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Tasks'),
    BottomNavigationBarItem(icon: Icon(Icons.loop_outlined), activeIcon: Icon(Icons.loop), label: 'Habits'),
    BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), activeIcon: Icon(Icons.timer), label: 'Focus'),
    BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: ThemeManager.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          items: _navItems,
        ),
      ),
    );
  }
}
