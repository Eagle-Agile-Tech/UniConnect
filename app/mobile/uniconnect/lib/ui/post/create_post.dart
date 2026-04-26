import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/home/view_models/home_viewmodel_provider.dart';
import 'package:uniconnect/ui/post/view_models/create_post_viewmodel_provider.dart';
import 'package:uniconnect/utils/helper_functions.dart';

import '../auth/auth_state_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> mediaUrls = [];

  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickMultiImage(limit: 5);
    setState(() {
      mediaUrls.addAll(pickedFile.map((file) => File(file.path)).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(createPostViewModelProvider);
    final isLoading = postState is AsyncLoading;
    ref.listen(createPostViewModelProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(homeViewModelProvider(ref.read(authNotifierProvider).value!.user!.id).notifier).refreshFeed();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Post shared!')));
          context.pop();
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to share post: $error')),
          );
        },
      );
    });
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Post'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(onPressed: context.pop, icon: Icon(Icons.clear)),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              const SizedBox(height: Dimens.spaceBtwSections),
              Align(
                alignment: Alignment.topRight,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final content = _contentController.text.trim();
                          if (content.isEmpty && mediaUrls.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Add text or image before posting.'),
                              ),
                            );
                            return;
                          }

                          await ref
                              .read(createPostViewModelProvider.notifier)
                              .createPost(
                                content: content,
                                mediaUrls: mediaUrls,
                                userId: ref.read(authNotifierProvider).value!.user!.id,
                                createdAt: DateTime.now(),
                                hashtags: UCHelperFunctions.extractHashtags(
                                  content,
                                ),
                              );
                        },
                  child: Text('Post'),
                ),
              ),
              const SizedBox(height: Dimens.spaceBtwItems),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: Dimens.sm),
                  child: TextFormField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(fontSize: 18, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Bleed your ink...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Dimens.spaceBtwItems),
              if (mediaUrls.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: mediaUrls.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: Dimens.xs),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                mediaUrls[index],
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  mediaUrls.removeAt(index);
                                });
                              },
                              icon: Icon(
                                Icons.cancel,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              Divider(thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () async {
                      await _pickImage();
                    },
                    icon: Icon(Icons.image_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
