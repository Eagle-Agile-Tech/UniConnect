import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/config/dummy_data.dart';
import 'package:uniconnect/ui/core/common/widgets/post_card/post_card.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/search/viewmodels/search_viewmodel_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? debounce;
  bool showSearchTile = true;

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchedPost = ref.watch(postSearchProvider);
    final searchedUser = ref.watch(userSearchProvider);
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
            hintText: "Search...",
            textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 14)),
            onChanged: (value) {
              if (debounce?.isActive ?? false) {
                debounce!.cancel();
              }
              debounce = Timer(const Duration(milliseconds: 500), () {
                ref.read(userSearchProvider.notifier).searchUser(value);
              });
            },
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimens.md),
        child: Column(
          children: [
            // When this is tapped it leads to search posts
            Expanded(
              child: ListView(
                children: [
                  if (_controller.text.trim().isNotEmpty && showSearchTile)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              ref
                                  .watch(postSearchProvider.notifier)
                                  .searchPost(_controller.text.trim());
                              setState(() => showSearchTile = false);
                            },
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(29),
                              ),
                              child: const Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(width: Dimens.sm),
                          Text(
                            _controller.text,
                            style: TextStyle(
                              fontSize: Dimens.fontLg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Users Section
                  searchedUser.when(
                    data: (data) => Column(
                      children: data.map((user) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 15,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: Dimens.avatarXs,
                                backgroundImage: user.profilePicture != null
                                    ? NetworkImage(user.profilePicture!)
                                    : AssetImage(Assets.defaultAvatar)
                                          as ImageProvider,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.username,
                                    style: TextStyle(
                                      fontSize: Dimens.fontLg,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    user.fullName,
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, st) => Center(child: Text(err.toString())),
                  ),
                  // Posts Section
                  if(!showSearchTile)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Posts',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if(!showSearchTile)
                  Divider(thickness: 1),
                  searchedPost.when(
                    data: (data) => Column(
                      children: data.map((post) {
                        return UCPostCard( post: post);
                      }).toList(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, st) => Center(child: Text(err.toString())),
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
