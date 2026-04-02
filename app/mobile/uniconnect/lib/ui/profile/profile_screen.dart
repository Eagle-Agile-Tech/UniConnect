import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/profile/view_models/course_viewmodel_provider.dart';
import 'package:uniconnect/ui/profile/view_models/profile_viewmodel_provider.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';
import 'package:uniconnect/ui/profile/widgets/profile_header.dart';

import '../../domain/models/course/course.dart';
import '../../domain/models/user/user.dart';
import '../../utils/result.dart';
import '../auth/auth_state_provider.dart';
import '../core/common/widgets/post_card/post_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authNotifierProvider);
    return authState.when(
      data: (auth) {
        final currentUser = auth.user;

        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final String activeId = userId ?? currentUser.id;
        final bool isMe = userId == null;

        final AsyncValue<User> user = userId == null
            ? AsyncValue.data(currentUser)
            : ref.watch(userProvider(userId!));

        final postAsync = userId == null
            ? ref.watch(profileViewModelProvider(currentUser.id))
            : ref.watch(profileViewModelProvider(userId!));
        final courseAsync = ref.read(courseProvider(currentUser.id));

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            body: RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(profileViewModelProvider(activeId).future),
              child: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: Dimens.sm),
                            child: isMe
                                ? ProfileHeader(user: currentUser, isMe: true)
                                : user.when(
                                    data: (User data) =>
                                        ProfileHeader(user: data, isMe: false),
                                    error:
                                        (Object error, StackTrace stackTrace) =>
                                            Center(
                                              child: Text('Error: $error'),
                                            ),
                                    loading: () => Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                          ),
                        ),
                        if (currentUser.isExpert)
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _HeaderDelegate(
                              TabBar(
                                labelPadding: EdgeInsets.symmetric(vertical: 0),
                                overlayColor: WidgetStatePropertyAll(
                                  Colors.transparent,
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: UnderlineTabIndicator(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(width: 3),
                                  insets: EdgeInsetsGeometry.symmetric(
                                    horizontal: 48,
                                  ),
                                ),
                                tabs: [
                                  Tab(text: 'Posts'),
                                  Tab(text: 'Courses'),
                                ],
                              ),
                            ),
                          ),
                      ];
                    },
                body: currentUser.isExpert
                    ? TabBarView(
                        children: [
                          postAsync.when(
                            data: (posts) => ListView.builder(
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                return UCPostCard(post: posts[index]);
                              },
                            ),
                            error: (err, stack) =>
                                Center(child: Text('Error: $err')),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          courseAsync.when(
                            data: (Result<List<Course>> data) {
                              return data.fold(
                                (courses) => GridView.builder(
                                  padding: EdgeInsets.all(Dimens.sm),
                                  itemCount: courses.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            courses[index].title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          Text(
                                            courses[index].description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),

                                          const Spacer(),

                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "\$${courses[index].price}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.people,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "${courses[index].enrolled}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: Dimens.sm,
                                        mainAxisSpacing: Dimens.sm,
                                      ),
                                ),
                                (error, _) =>
                                    Center(child: Text('Error: $error')),
                              );
                            },
                            error: (err, stack) =>
                                Center(child: Text('Error: $err')),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ],
                      )
                    : postAsync.when(
                        data: (posts) => ListView.builder(
                          itemCount: posts.length,
                          itemBuilder: (context, index) =>
                              UCPostCard(post: posts[index]),
                        ),
                        error: (err, stack) =>
                            Center(child: Text('Error: $err')),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                      ),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }
}
