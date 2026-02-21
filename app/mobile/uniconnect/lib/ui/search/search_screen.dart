import 'package:flutter/material.dart';

import '../core/theme/dimens.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        titleSpacing: 0,
        title: SearchBar(
          padding: WidgetStateProperty.all(EdgeInsets.all(0)),
          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(Colors.transparent),
          autoFocus: true,
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.zero
            )
          ),
        ),
      ),
    );
  }
}
