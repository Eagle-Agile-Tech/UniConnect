import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/ui/core/common/widgets/post_card/post_card.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/search/viewmodels/search_viewmodel_provider.dart';

enum SearchTab {
  users,
  posts,
  hashtags,
  jobs,
  hackathons,
  scholarships,
}

extension SearchTabExtension on SearchTab {
  String get title {
    switch (this) {
      case SearchTab.users:
        return 'Users';
      case SearchTab.posts:
        return 'Posts';
      case SearchTab.hashtags:
        return 'Hashtags';
      case SearchTab.jobs:
        return 'Jobs';
      case SearchTab.hackathons:
        return 'Hackathons';
      case SearchTab.scholarships:
        return 'Scholarships';
    }
  }

  IconData get icon {
    switch (this) {
      case SearchTab.users:
        return Icons.people;
      case SearchTab.posts:
        return Icons.article;
      case SearchTab.hashtags:
        return Icons.tag;
      case SearchTab.jobs:
        return Icons.work;
      case SearchTab.hackathons:
        return Icons.code;
      case SearchTab.scholarships:
        return Icons.school;
    }
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? debounce;
  SearchTab _selectedTab = SearchTab.users;

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    debounce?.cancel();
  }

  void _onSearchChanged(String value) {
    if (debounce?.isActive ?? false) {
      debounce!.cancel();
    }
    debounce = Timer(const Duration(milliseconds: 700), () {
      _performSearch(value);
    });
  }

  void _performSearch(String value) {
    switch (_selectedTab) {
      case SearchTab.users:
        ref.read(userSearchProvider.notifier).searchUser(value);
        break;
      case SearchTab.posts:
        ref.read(postSearchProvider.notifier).searchPost(value);
        break;
      case SearchTab.hashtags:
        ref.read(userSearchProvider.notifier).searchUser(value);
        break;
      case SearchTab.jobs:
        ref.read(userSearchProvider.notifier).searchUser(value);
        break;
      case SearchTab.hackathons:
        ref.read(userSearchProvider.notifier).searchUser(value);
        break;
      case SearchTab.scholarships:
        ref.read(userSearchProvider.notifier).searchUser(value);
        break;
    }
  }

  void _onTabChanged(SearchTab tab) {
    setState(() {
      _selectedTab = tab;
    });
    if (_controller.text.trim().isNotEmpty) {
      _performSearch(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        titleSpacing: 0,
        title: SizedBox(
          width: MediaQuery.of(context).size.width - 80,
          child: SearchBar(
            controller: _controller,
            backgroundColor: WidgetStatePropertyAll(Colors.grey[300]),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            autoFocus: true,
            constraints: const BoxConstraints(minHeight: 32.0, maxHeight: 32.0),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            hintText: "Search ${_selectedTab.title.toLowerCase()}...",
            textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 14)),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Dimens.md),
              child: Row(
                children: SearchTab.values.map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildTabButton(tab, isSelected),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimens.md),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(SearchTab tab, bool isSelected) {
    return GestureDetector(
      onTap: () => _onTabChanged(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tab.title,
              style: TextStyle(
                fontSize: Dimens.fontMd,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case SearchTab.users:
        return _buildUsersContent();
      case SearchTab.posts:
        return _buildPostsContent();
      case SearchTab.hashtags:
        return _buildHashtagsContent();
      case SearchTab.jobs:
        return _buildJobsContent();
      case SearchTab.hackathons:
        return _buildHackathonsContent();
      case SearchTab.scholarships:
        return _buildScholarshipsContent();
    }
  }

  Widget _buildUsersContent() {
    final searchedUser = ref.watch(userSearchProvider);

    return searchedUser.when(
      data: (data) {
        if (data.isEmpty && _controller.text.trim().isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(fontSize: Dimens.fontLg, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        return ListView(
          children: data.map((user) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: Dimens.avatarXs,
                    backgroundImage: user.$3 != null
                        ? NetworkImage(user.$3!)
                        : AssetImage(Assets.defaultAvatar) as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.$2,
                          style: TextStyle(
                            fontSize: Dimens.fontLg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user.$1,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text(err.toString())),
    );
  }

  Widget _buildPostsContent() {
    final searchedPost = ref.watch(postSearchProvider);

    return searchedPost.when(
      data: (data) {
        if (data.isEmpty && _controller.text.trim().isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.art_track, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No posts found',
                  style: TextStyle(fontSize: Dimens.fontLg, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        return ListView(
          children: data.map((post) {
            return UCPostCard(post: post);
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text(err.toString())),
    );
  }

  Widget _buildHashtagsContent() {
    final searchedHashtags = ref.read(userSearchProvider);

    return searchedHashtags.when(
      data: (data) {
        if (data.isEmpty && _controller.text.trim().isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tag, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No hashtags found',
                  style: TextStyle(fontSize: Dimens.fontLg, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        return ListView(
          children: data.map((hashtag) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.tag, color: Theme.of(context).primaryColor),
                ),
                title: Text("hashtag.name"),
                subtitle: Text('${"hashtag.postCount"} posts'),
                trailing: Chip(
                  label: Text('${"hashtag.followers"} followers'),
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text(err.toString())),
    );
  }

  Widget _buildJobsContent() {
    final searchedJobs =  ref.watch(userSearchProvider);
    ;

    return searchedJobs.when(
      data: (data) {
        if (data.isEmpty && _controller.text.trim().isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No jobs found',
                  style: TextStyle(fontSize: Dimens.fontLg, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        return ListView(
          children: data.map((job) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.work, color: Theme.of(context).primaryColor),
                ),
                title: Text("job.title"),
                subtitle: Text('job.company'),
                trailing: Chip(
                  label: Text("job.type"),
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text(err.toString())),
    );
  }

  Widget _buildHackathonsContent() {
    final searchedHackathons = ref.watch(userSearchProvider);

    return searchedHackathons.when(
      data: (data) {
        if (data.isEmpty && _controller.text.trim().isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.code_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No hackathons found',
                  style: TextStyle(fontSize: Dimens.fontLg, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        return ListView(
          children: data.map((hackathon) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.code, color: Theme.of(context).primaryColor),
                ),
                title: Text("hackathon.name"),
                subtitle: Text("hackathon.organizer"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "hackathon.date",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text("hackathon.mode"),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text(err.toString())),
    );
  }

  Widget _buildScholarshipsContent() {
    final searchedScholarships = ref.read(userSearchProvider);;
    return searchedScholarships.when(
      data: (data) {
        if (data.isEmpty && _controller.text.trim().isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No scholarships found',
                  style: TextStyle(fontSize: Dimens.fontLg, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        return ListView(
          children: data.map((scholarship) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.school, color: Theme.of(context).primaryColor),
                ),
                title: Text("scholarship.name"),
                subtitle: Text("scholarship.provider"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "amount",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text("scholarship.deadline"),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text(err.toString())),
    );
  }
}