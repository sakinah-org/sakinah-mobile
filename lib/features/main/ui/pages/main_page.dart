import 'package:flutter/material.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../quran/presentation/pages/quran_page.dart';
import '../widgets/main_bottom_navigation_bar.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const HomePage(),
          const QuranPage(),
          Container(),
        ],
      ),
      bottomNavigationBar: MainBottomNavigationBar(
        onTap: (index) {
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}
