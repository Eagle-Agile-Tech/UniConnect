import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';

import '../../../routing/routes.dart';
import '../../../utils/validator.dart';
import '../../core/theme/dimens.dart';

class ManageProfile extends ConsumerStatefulWidget {
  const ManageProfile({super.key});

  @override
  ConsumerState<ManageProfile> createState() => _ManageProfileState();
}

class _ManageProfileState extends ConsumerState<ManageProfile> {
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final GlobalKey _cameraKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  void _pickImage(String source) async {
    final picked = await _picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
    setState(() {
      _pickedImage = picked;
    });
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).value?.user;
    if (user != null) {
      _usernameController.text = user.username;
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value!.user!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('Manage your profile'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'logout') {
                final status = await ref
                    .read(authNotifierProvider.notifier)
                    .logout();
                if (status) {
                  context.go(Routes.loginOrSignup);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Log out failed! Please try again later'),
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('Log Out')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(Dimens.defaultSpace),
        child: Form(
          child: Column(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: Dimens.avatarMd,
                      backgroundImage: _pickedImage != null
                          ? FileImage(File(_pickedImage!.path))
                          : user.profilePicture != null
                          ? NetworkImage(user.profilePicture!)
                          : null,
                    ),
                    IconButton(
                      key: _cameraKey,
                      onPressed: () async {
                        final RenderBox renderBox =
                            _cameraKey.currentContext!.findRenderObject()
                                as RenderBox;
                        final Offset offset = renderBox.localToGlobal(
                          Offset.zero,
                        );
                        final RelativeRect position = RelativeRect.fromLTRB(
                          offset.dx,
                          offset.dy,
                          offset.dx + renderBox.size.width,
                          offset.dy + renderBox.size.height,
                        );

                        final selected = await showMenu<String>(
                          context: context,
                          position: position,
                          items: [
                            PopupMenuItem(
                              value: 'camera',
                              child: ListTile(
                                leading: Icon(Icons.camera_alt),
                                title: Text('Camera'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'gallery',
                              child: ListTile(
                                leading: Icon(Icons.photo_library),
                                title: Text('Gallery'),
                              ),
                            ),
                          ],
                        );

                        if (selected != null) {
                          _pickImage(selected);
                        }
                      },
                      icon: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.grey[300],
                        size: 56,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimens.defaultSpace),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextFormField(
                      controller: _firstNameController,
                      validator: (value) =>
                          UCValidator.validateEmptyText('First Name', value),
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimens.spaceBtwItems),
                  Flexible(
                    child: TextFormField(
                      controller: _lastNameController,
                      validator: (value) =>
                          UCValidator.validateEmptyText('Last Name', value),
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimens.defaultSpace),
              TextFormField(
                controller: _usernameController,
                validator: (value) => UCValidator.validateUsername(value),
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: Dimens.defaultSpace),
              TextFormField(
                controller: _bioController,
                maxLines: 2,
                maxLength: 70,
                decoration: InputDecoration(label: const Text('Bio')),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () => context.pop(),
                      child: Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: Dimens.spaceBtwItems),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () async {
                        final res = await ref
                            .watch(authNotifierProvider.notifier)
                            .updateProfile(
                              lastName:
                                  user.lastName !=
                                      _lastNameController.text.trim()
                                  ? _lastNameController.text.trim()
                                  : null,
                              firstName:
                                  user.firstName !=
                                      _firstNameController.text.trim()
                                  ? _firstNameController.text.trim()
                                  : null,
                              username:
                                  user.username !=
                                      _usernameController.text.trim()
                                  ? _usernameController.text.trim()
                                  : null,
                              bio: user.bio != _bioController.text.trim()
                                  ? _bioController.text.trim()
                                  : null,
                              profilePic: _pickedImage != null
                                  ? File(_pickedImage!.path)
                                  : null,
                            );
                        res.fold(
                          (data) => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Profile updated successfully!'),
                            ),
                          ),
                          (error, stackTrace) =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              ),
                        );
                      },
                      child: Text('Save Changes'),
                    ),
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
