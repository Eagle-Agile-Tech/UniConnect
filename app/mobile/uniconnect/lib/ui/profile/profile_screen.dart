import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/home/view_models/home_viewmodel_provider.dart';
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
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Auth Error: $err'))),
      data: (auth) {
        final currentUser = auth.user;

        if (currentUser == null) {
          return const Scaffold(body: Center(child: Text('User not found')));
        }

        final String activeId = userId ?? currentUser.id;
        final bool isMe = userId == null;

        final AsyncValue<User> userAsync = isMe
            ? AsyncValue.data(currentUser)
            : ref.watch(userProvider(activeId));

        return userAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, stack) => Scaffold(body: Center(child: Text('Error loading profile: $err'))),
          data: (user) {
            final postsAsync = ref.watch(homeViewModelProvider(activeId));
            final postsNotifier = ref.watch(homeViewModelProvider(activeId).notifier);
            final courseAsync = ref.watch(courseProvider(activeId));

            return DefaultTabController(
              length: user.isExpert ? 2 : 1,
              child: Scaffold(
                body: RefreshIndicator(
                  onRefresh: () => ref.refresh(profileViewModelProvider(activeId).future),
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: Dimens.sm),
                            child: ProfileHeader(user: user, isMe: isMe),
                          ),
                        ),
                        if (user.isExpert)
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _HeaderDelegate(
                              TabBar(
                                labelPadding: EdgeInsets.zero,
                                indicatorSize: TabBarIndicatorSize.tab,
                                tabs: const [
                                  Tab(text: 'Posts'),
                                  Tab(text: 'Courses'),
                                ],
                              ),
                            ),
                          ),
                      ];
                    },
                    body: user.isExpert
                        ? TabBarView(
                      children: [
                        _buildPostList(postsAsync,postsNotifier),
                        _buildCourseGrid(courseAsync),
                      ],
                    )
                        : _buildPostList(postsAsync, postsNotifier),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostList(AsyncValue<List<dynamic>> postAsync, HomeViewmodelProvider postsNotifier) {
    return postAsync.when(
      data: (posts) => posts.isEmpty
          ? const Center(child: Text('No posts available'))
          :  ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) => UCPostCard(post: posts[index], onLike: () => postsNotifier.toggleLike(postId: posts[index].id,), onBookmark: () => postsNotifier.bookmarkPost(postId: posts[index].id), onDelete: () => postsNotifier.removePost(posts[index].id),),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading posts: $err')),
    );
  }

  Widget _buildCourseGrid(AsyncValue<Result<List<Course>>> courseAsync) {
    return courseAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading courses: $err')),
      data: (result) => result.fold(
            (courses) => GridView.builder(
          padding: EdgeInsets.all(Dimens.sm),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: Dimens.sm,
            mainAxisSpacing: Dimens.sm,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) => _CourseCard(course: courses[index]),
        ),
            (error, _) => Center(child: Text('Course Error: $error')),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(course.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("\$${course.price}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Text("👥 ${course.enrolled}", style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate(this._tabBar);
  final TabBar _tabBar;

  @override double get maxExtent => _tabBar.preferredSize.height;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }
}