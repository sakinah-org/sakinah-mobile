import 'package:flutter/material.dart';

class CancelKeyboardGesture extends StatelessWidget {
  const CancelKeyboardGesture({super.key, required this.child,this.withoutSafeArea = true});
  final Widget child;
  final bool withoutSafeArea;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: SafeArea(child: child,top: false,bottom: withoutSafeArea),
    );
  }
}
