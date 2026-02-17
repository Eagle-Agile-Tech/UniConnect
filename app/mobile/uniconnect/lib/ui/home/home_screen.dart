import 'package:flutter/material.dart';
import 'package:uniconnect/ui/core/theme/colors.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../config/assets.dart';

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
            Card(
              borderOnForeground: true,
              color: UCColors.background,
              elevation: 1.5,
              child: Column(
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(Assets.googleLogo),
                    ),
                    title: Text(
                      'Iman Yilma',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text('08:39 AM'),
                    trailing: IconButton(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,

                        elevation: 10,
                        useSafeArea: true,
                        builder: (context) {
                          return Wrap(
                            children: [
                              ListTile(
                                leading: Text('😞'),
                                title: Text('Not Interested'),
                              ),
                              ListTile(
                                leading: Text('🚩'),
                                title: Text('Repost post'),
                              ),
                            ],
                          );
                        },
                      ),
                      icon: Icon(Icons.more_vert_outlined),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec auctor, nisl eget ultricies lacinia, nunc nisl aliquam nisl, eget aliquam nunc nisl eget nunc.',
                        ),
                        Container(
                          padding: EdgeInsets.all(40),
                          child: FittedBox(
                            child: ClipRRect(
                              child: Image.asset(Assets.googleLogo),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.thumb_up_outlined),
                            ),
                            const Text('123'),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.comment_outlined),
                            ),
                            const Text('123'),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.share_outlined),
                            ),
                            Spacer(),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.bookmark_border_outlined),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
