import 'package:sakinah/shared/widgets/icon_handler.dart';
import 'package:sakinah/utils/assets/app_icons_keys.dart';
import 'package:flutter/material.dart';
import '../../../../configurations/app_translation_keys.dart';
import '../../../../handlers/translation_handler.dart';
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
      selectedItemColor: AppColors.lightBrandPrimary,
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
          icon: drawSvgIcon(AppIcons.home,
              iconColor: _currentIndex == 0
                  ? AppColors.lightBrandPrimary
                  : const Color(0xff8E8E8E)),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: drawSvgIcon(
            AppIcons.quran,
            iconColor: _currentIndex == 1
                ? AppColors.lightBrandPrimary
                : const Color(0xff8E8E8E),
          ),
          label: translator.word(TranslationKeys.quranTabLabel),
        ),
        BottomNavigationBarItem(
          icon: drawSvgIcon(
            AppIcons.settingsIcon,
            iconColor: _currentIndex == 2
                ? AppColors.lightBrandPrimary
                : const Color(0xff8E8E8E),
          ),
          label: "Settings",
        ),
      ],
    );
  }
}
