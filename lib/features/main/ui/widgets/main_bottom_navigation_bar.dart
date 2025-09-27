import 'package:base/shared/widgets/icon_handler.dart';
import 'package:base/utils/assets/app_icons_keys.dart';
import 'package:flutter/material.dart';
import '../../../../utils/style/app_colors.dart';

class MainBottomNavigationBar extends StatefulWidget {
  const MainBottomNavigationBar({super.key, required this.onTap});

  final Function(int index) onTap;

  @override
  State<MainBottomNavigationBar> createState() =>
      _MainBottomNavigationBarState();
}

class _MainBottomNavigationBarState extends State<MainBottomNavigationBar> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: AppColors.secondaryColor,
      unselectedItemColor: Color(0xff8E8E8E),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      onTap: (value) {
        setState(() {
          _currentIndex = value;
          widget.onTap(value);
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: drawSvgIcon(AppIcons.logo,
              iconColor: _currentIndex == 0
                  ? AppColors.secondaryColor
                  : const Color(0xff8E8E8E)),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: drawSvgIcon(AppIcons.search,
              iconColor: _currentIndex == 1
                  ? AppColors.secondaryColor
                  : const Color(0xff8E8E8E)),
          label: "Tours",
        ),
        BottomNavigationBarItem(
          icon: drawSvgIcon(AppIcons.outlinedTrophy,
              iconColor: _currentIndex == 2
                  ? AppColors.secondaryColor
                  : const Color(0xff8E8E8E)),
          label: "Agenda",
        ),
        BottomNavigationBarItem(
          icon: drawSvgIcon(AppIcons.outlinedDocument,
              iconColor: _currentIndex == 3
                  ? AppColors.secondaryColor
                  : const Color(0xff8E8E8E)),
          label: "News",
        ),
        BottomNavigationBarItem(
          icon: drawSvgIcon(
            _currentIndex == 4 ? "avatar_colored_ex" : "avatar_ex",
          ),
          label: "Profile",
        ),
      ],
    );
  }
}
