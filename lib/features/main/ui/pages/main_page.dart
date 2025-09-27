import 'package:flutter/material.dart';
import '../widgets/main_bottom_navigation_bar.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          Container(),
          Container(),
          Container(),
          Container(),
          Container()
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