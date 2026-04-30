import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniconnect/ui/community/view_models/community_viewmodel.dart';
import 'package:uniconnect/utils/helper_functions.dart';

import '../core/theme/dimens.dart';

class CreateCommunityPostScreen extends ConsumerStatefulWidget {
  const CreateCommunityPostScreen({super.key, required this.communityId});

  final String communityId;

  @override
  ConsumerState<CreateCommunityPostScreen> createState() =>
      _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState
    extends ConsumerState<CreateCommunityPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _media = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(limit: 10);
    if (picked.isEmpty) return;
    setState(() {
      _media.addAll(picked.map((x) => File(x.path)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityCreatePostProvider(widget.communityId));
    final isLoading = state is AsyncLoading;

    ref.listen(communityCreatePostProvider(widget.communityId), (prev, next) {
      next.whenOrNull(
        data: (payload) {
          final status = payload?['status'];
          final success = payload?['success'];
          final message = payload?['message'];

          if (success == false || status == 'PENDING' || status == 'REJECTED') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message?.toString() ?? 'Post was not accepted right now',
                ),
              ),
            );
            return;
          }

          ref.invalidate(communityPostsProvider(widget.communityId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Posted to community')),
          );
          context.pop();
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(UCHelperFunctions.getErrorMessage(error)),
            ),
          );
        },
      );
    });

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Community Post'),
          centerTitle: true,
          leading: IconButton(
            onPressed: isLoading ? null : context.pop,
            icon: const Icon(Icons.clear),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final content = _contentController.text.trim();
                      if (content.isEmpty && _media.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add text or image before posting.'),
                          ),
                        );
                        return;
                      }

                      await ref
                          .read(
                            communityCreatePostProvider(widget.communityId)
                                .notifier,
                          )
                          .create(
                            content: content,
                            tags: UCHelperFunctions.extractHashtags(content),
                            media: _media,
                          );
                    },
              child: const Text('Post'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              const SizedBox(height: Dimens.spaceBtwItems),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 18, height: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'Write something...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_media.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _media.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: Dimens.xs,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _media[index],
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
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _media.removeAt(index);
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
              const Divider(thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: isLoading ? null : _pickImages,
                    icon: const Icon(Icons.image_outlined),
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
