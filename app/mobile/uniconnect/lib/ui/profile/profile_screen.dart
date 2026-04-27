import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/home/view_models/home_viewmodel_provider.dart';
import 'package:uniconnect/ui/profile/view_models/course_viewmodel_provider.dart';
import 'package:uniconnect/ui/profile/view_models/profile_viewmodel_provider.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';
import 'package:uniconnect/ui/profile/widgets/profile_header.dart';

import '../../config/assets.dart';
import '../../domain/models/course/course.dart';
import '../../domain/models/user/user.dart';
import '../../routing/routes.dart';
import '../../utils/enums.dart';
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

            int tabCount = 1;
            if (user.isExpert) tabCount = 2;
            if (user.role == UserRole.INSTITUTION) tabCount = 2;

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
                        // if (user.isExpert || (user.role == UserRole.INSTITUTION && user.institution!.affiliatedExperts.isNotEmpty))
                        if (user.isExpert)
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _HeaderDelegate(
                              TabBar(
                                labelPadding: EdgeInsets.zero,
                                indicatorSize: TabBarIndicatorSize.tab,
                                tabs: [
                                  const Tab(text: 'Posts'),
                                  if (user.isExpert) const Tab(text: 'Courses'),
                                  // if (user.role == UserRole.INSTITUTION && user.institution!.affiliatedExperts.isNotEmpty) const Tab(text: 'Affiliates'),
                                ],
                              ),
                            ),
                          ),
                      ];
                    },
                    body: TabBarView(
                      children: [
                        _buildPostList(postsAsync, postsNotifier),
                        if (user.isExpert) _buildCourseGrid(courseAsync),
                        // if (user.role == UserRole.INSTITUTION && user.institution!.affiliatedExperts.isNotEmpty) _buildAffiliatesList(user.institution!.affiliatedExperts), // Placeholder for affiliates
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAffiliatesList(List<User> user) {
    return ListView.builder(
      itemCount: user.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(Dimens.md),
        child: ListTile(
          onTap: () => context.push(Routes.userProfile(user[index].id)),
          leading: CircleAvatar(
            backgroundImage: user[index].profilePicture != null
                ? NetworkImage(user[index].profilePicture!)
                : const AssetImage(Assets.defaultAvatar),
          ),
          title: Text(user[index].fullName),
          subtitle: Text('@${user[index].username}'),
        ),
      ),
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
            (courses) {
              if (courses.isEmpty) {
                return const Center(child: Text('No courses available'));
              }
              return GridView.builder(
                padding: EdgeInsets.all(Dimens.sm),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: Dimens.sm,
                  mainAxisSpacing: Dimens.sm,
                ),
                itemCount: courses.length,
                itemBuilder: (context, index) =>
                    _CourseCard(course: courses[index]),
              );
            },
            (error, _) => Center(child: Text('Course Error : Please try again later')),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            course.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),

          const Spacer(),

          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "\$${course.price}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 13,
                  ),
                ),
              ),

              // Enrolled
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "${course.enrolled}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
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