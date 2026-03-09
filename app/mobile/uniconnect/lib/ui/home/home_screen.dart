import 'package:flutter/material.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/config/dummy_data.dart';
import 'package:uniconnect/ui/core/common/widgets/post_card.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/home/widgets/drawer_content.dart';
import 'package:uniconnect/ui/post/create_post.dart';

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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen())),
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
      drawer: Drawer(
        child: DrawerContent(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: Dimens.spaceBtwItems),
            UCPostCard(name: 'Iman Yilma', avatar: Assets.avatar1, caption: UCDummyData.postCaption1, image: Assets.post2,),
            const SizedBox(height: Dimens.spaceBtwItems,),
            UCPostCard(name: 'Feysel Teshome', avatar: Assets.avatar2, caption: UCDummyData.postCaption2, image: Assets.post3,),
            const SizedBox(height: Dimens.spaceBtwItems,),
          ],
        ),
      ),
    );
  }
}
