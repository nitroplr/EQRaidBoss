import 'package:flutter/material.dart';

class EmptyIconButton extends StatelessWidget {
  const EmptyIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    Color transparent = Colors.transparent;
    return IconButton(
        highlightColor: transparent,
        color: transparent,
        focusColor: transparent,
        splashColor: transparent,
        mouseCursor: SystemMouseCursors.basic,
        hoverColor: transparent,
        onPressed: () {},
        icon: Icon(
          Icons.ice_skating,
          color: transparent,
        ));
  }
}
