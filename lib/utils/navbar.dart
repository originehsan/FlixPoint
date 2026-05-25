import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/screens/booking_history_screen.dart';
import 'package:movieticket/screens/news_screen.dart';
import 'package:movieticket/screens/homescreen.dart';
import 'package:movieticket/screens/profile.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:provider/provider.dart';

class Navbar extends StatefulWidget {
  final String name;
  const Navbar({super.key, required this.name});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'icon': CupertinoIcons.home, 'label': 'Home'},
    {'icon': CupertinoIcons.ticket, 'label': 'Tickets'},
    {'icon': CupertinoIcons.video_camera, 'label': 'Events'},
    {'icon': CupertinoIcons.person, 'label': 'Profile'},
  ];

  @override
  Widget build(BuildContext context) {
    R.init(context);

    // Get name from UserProvider
    // Falls back to widget.name if provider name is empty
    final userProvider = Provider.of<UserProvider>(context);
    final name = userProvider.name.isNotEmpty ? userProvider.name : widget.name;

    // Build screens here so name is always fresh
    final screens = [
      Homescreen(name: name),
      const BookingHistoryScreen(),
      const EventsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.96,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            top: BorderSide(
              color: appthemecolor.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _tabs.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? appthemecolor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: appthemecolor.withValues(alpha: 0.2),
                  width: 0.5,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              width: isSelected ? 20 : 0,
              decoration: BoxDecoration(
                color: appthemecolor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: appthemecolor.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              _tabs[index]['icon'] as IconData,
              color: isSelected ? appthemecolor : secondaryColor,
              size: R.sp(22),
            ).animate(target: isSelected ? 1 : 0).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 200.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? appthemecolor : secondaryColor,
                fontSize: R.sp(10),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(_tabs[index]['label'] as String),
            ),
          ],
        ),
      ),
    );
  }
}
