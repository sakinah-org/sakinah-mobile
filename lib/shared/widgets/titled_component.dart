import 'package:flutter/material.dart';

import '../../utils/style/app_colors.dart';

class TitledComponent extends StatelessWidget {
  const TitledComponent({
    super.key,
    required this.title,
    required this.child,
    this.showAll,
    this.titleStyle,
    this.titlePadding = const EdgeInsets.symmetric(horizontal: 24),
    this.childPadding = const EdgeInsets.all(0),
  });

  final Widget child;
  final String title;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry titlePadding;
  final EdgeInsetsGeometry childPadding;

  final Function()? showAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandPrimary =
        isDark ? AppColors.darkBrandPrimary : AppColors.lightBrandPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: titlePadding,
          child: Row(
            children: [
              Text(title,
                  style: titleStyle ??
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              Spacer(),
              if (showAll != null)
                InkWell(
                  onTap: showAll,
                  child: Text(
                    "View All",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: brandPrimary),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Padding(
          padding: childPadding,
          child: child,
        ),
      ],
    );
  }
}
