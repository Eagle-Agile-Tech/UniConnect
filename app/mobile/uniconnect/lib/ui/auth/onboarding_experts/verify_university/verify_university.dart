import 'package:flutter/material.dart';

import '../../../core/common/styles/spacing_style.dart';
import '../../../core/common/widgets/app_bar.dart';

class ExpertVerifyUni extends StatefulWidget {
  const ExpertVerifyUni({super.key});

  @override
  State<ExpertVerifyUni> createState() => _ExpertVerifyUniState();
}

class _ExpertVerifyUniState extends State<ExpertVerifyUni> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UCAppBar('Verify University', showBack: false, centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: UCSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              Text(
                'Verify Your Identity',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Divider(
                thickness: 1,
                color: Theme.of(context).primaryColor,
                indent: 100,
                endIndent: 100,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
