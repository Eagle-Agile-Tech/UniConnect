import 'package:flutter/material.dart';

import '../../config/assets.dart';
import '../../config/dummy_data.dart';
import '../core/common/widgets/post_card/post_card.dart';
import '../core/theme/dimens.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: const Text('Community', style: TextStyle(fontWeight: FontWeight.bold)),
                pinned: true,
                floating: true,
                actions: [
                  IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderImage(),
                    const SizedBox(height: Dimens.spaceBtwItems),
                    _buildCommunityInfo(context),
                  ],
                ),
              ),

              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.purple,
                    tabs: [
                      Tab(text: 'Feed'),
                      Tab(text: 'Members'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: 10,
                itemBuilder: (context, index) => UCPostCard(
                  author: UCDummyData.user,
                  post: UCDummyData.post,
                ),
              ),
              ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) => const ListTile(
                  leading: CircleAvatar(),
                  title: Text("Member Name"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeaderImage() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage(Assets.event), fit: BoxFit.cover),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(15, 35, 0, 0),
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.tealAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(image: AssetImage(Assets.event), fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          right: 15, bottom: 0,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {},
            child: const Text('Join', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Software Engineering 2026',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Text('12,240 members'),
          const SizedBox(height: Dimens.spaceBtwItems),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
