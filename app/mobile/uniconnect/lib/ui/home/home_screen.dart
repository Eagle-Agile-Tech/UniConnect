import 'package:flutter/material.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/config/dummy_data.dart';
import 'package:uniconnect/ui/core/common/widgets/post_card.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          'Uni',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.add_circle_outline_outlined,
              size: Dimens.iconLg,
            ),
          ),
        ],
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Icon(Icons.sort, size: Dimens.iconSize),
          ),
        ),
      ),
      drawer: Drawer(child: Center(child: Text('Drawer'))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: Dimens.spaceBtwItems),
            UCPostCard(name: 'Iman Yilma', avatar: Assets.avatar1, caption: UCDummyData.postCaption, image: Assets.post2,),
          ],
        ),
      ),
    );
  }
}
