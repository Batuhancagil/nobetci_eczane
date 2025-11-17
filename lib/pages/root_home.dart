import 'package:flutter/material.dart';
import 'duty_pharmacy_page.dart';
import 'medicine_search_page.dart';
import 'medicine_reminder_page.dart';

class RootHome extends StatefulWidget {
  const RootHome({super.key});

  @override
  State<RootHome> createState() => _RootHomeState();
}

class _RootHomeState extends State<RootHome> {
  int _currentIndex = 0;

  final _pages = const [
    DutyPharmacyPage(),
    MedicineSearchPage(),
    MedicineReminderPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_pharmacy_outlined),
            selectedIcon: Icon(Icons.local_pharmacy),
            label: 'Nöbetçi',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'İlaç Sorgu',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm),
            selectedIcon: Icon(Icons.alarm_on),
            label: 'Hatırlatma',
          ),
        ],
      ),
    );
  }
}
