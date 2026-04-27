import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:uniconnect/ui/community/view_models/community_onboard_viewmodel.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/utils/validator.dart';

import '../../domain/models/user/user.dart';
import '../../routing/routes.dart';

class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _pickedImage;
  List<User> selectedFriends = [];

  void _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final onboard = ref.watch(onboardCommunity.notifier);
    ref.listen(onboardCommunity, (prev, next) {
      next.whenOrNull(
        data: (id) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Community Created')));
          context.go(Routes.community(id),extra: true);
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create community: $error')),
          );
        },
      );
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create New Community',
          style: TextStyle().copyWith(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: true,
      ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(friendsProvider.future),
          child: Form(
            key: _key,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimens.md),
              child: ListView(
                children: [
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          image: _pickedImage != null
                              ? DecorationImage(
                            image: FileImage(File(_pickedImage!.path)) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimens.sm),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _pickImage(),
                      label: Text('Pick Profile'),
                      icon: Icon(Icons.camera_front_sharp),
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimens.spaceBtwItems),
                  Text(
                    "Community Name",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Dimens.fontMd,
                    ),
                  ),
                  const SizedBox(height: Dimens.sm),
                  TextFormField(
                    controller: _nameController,
                    validator: (value) => UCValidator.validateEmptyText('Community Name', value),
                  ),
                  const SizedBox(height: Dimens.spaceBtwItems),
                  Text(
                    "Short Description",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Dimens.fontMd,
                    ),
                  ),
                  const SizedBox(height: Dimens.sm),
                  TextFormField(
                    controller: _descriptionController,
                    validator: (value) => UCValidator.validateEmptyText('Description', value),
                    maxLines: 5,
                    maxLength: 150,
                  ),
                  const SizedBox(height: Dimens.spaceBtwItems),
                  friendsAsync.when(
                    data: (List<User> data) {
                      return MultiSelectDialogField<User>(
                        validator: (value) => UCValidator.validateMembers(value),
                        title: const Text('Select at least 5'),
                        searchable: true,
                        items: data
                            .map((user) => MultiSelectItem(user, user.fullName))
                            .toList(),
                        onConfirm: (selected) {
                          setState(() => selectedFriends = selected);
                        },
                        separateSelectedItems: true,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(40)),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        buttonIcon: Icon(
                          Icons.people_alt_sharp,
                          color: Theme.of(context).primaryColor,
                        ),
                        buttonText: Text(
                          "Members",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                          ),
                        ),
                        chipDisplay: MultiSelectChipDisplay(
                          items: selectedFriends
                              .map((e) => MultiSelectItem(e, e.fullName))
                              .toList(),
                          scroll: true,
                          chipColor: Colors.white,
                          textStyle: const TextStyle(color: Colors.black),
                          onTap: (value) {
                            setState(() {
                              selectedFriends.remove(value);
                            });
                          },
                        ),
                      );
                    },
                    loading: () => Column(
                      children: [
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        Text('Loading Friends...'),
                      ],
                    ),
                    error: (error, stack) => const Text(
                      "Failed to load friends, try again later",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: Dimens.spaceBtwSections),
                  ElevatedButton(
                    onPressed: () {
                      if (!_key.currentState!.validate()) return;
                      onboard.registerCommunity(
                        name: _nameController.text.trim(),
                        description: _descriptionController.text.trim(),
                        members: selectedFriends.map((user) => user.id).toList(),
                        profilePic: _pickedImage != null ? File(_pickedImage!.path) : null,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text('Create Community'),
                  ),
                  const SizedBox(height: Dimens.spaceBtwItems),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
