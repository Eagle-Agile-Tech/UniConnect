import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniconnect/ui/auth/onboarding_experts/viewmodel/expert_onboarding_provider.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/app_bar.dart';
import 'package:uniconnect/utils/helper_functions.dart';

import '../../../config/dummy_data.dart';
import '../../../routing/routes.dart';
import '../../../utils/validator.dart';
import '../auth_state_provider.dart';
import '../../core/theme/dimens.dart';

class ExpertAcademicProfileScreen extends ConsumerStatefulWidget {
  const ExpertAcademicProfileScreen({super.key});

  @override
  ConsumerState<ExpertAcademicProfileScreen> createState() =>
      _ExpertAcademicProfileScreenState();
}

class _ExpertAcademicProfileScreenState
    extends ConsumerState<ExpertAcademicProfileScreen> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final _expertiseController = TextEditingController();
  final _honorController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _profileImage;
  Timer? debounce;
  bool? isUsernameAvailable;

  Future _pickImage(String source) async {
    try {
      final image = await _picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
      setState(() {
        _profileImage = image;
      });
    } catch (e) {
      return e;
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    _expertiseController.dispose();
    _honorController.dispose();
    _bioController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UCAppBar('Profile', showBack: false, centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: UCSpacingStyle.paddingWithAppBarHeight,
          child: Form(
            key: _key,
            child: Column(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: Dimens.avatarLg,
                    backgroundImage: _profileImage != null
                        ? FileImage(File(_profileImage!.path))
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    final selected = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        MediaQuery.of(context).size.width * 0.5,
                        20,
                        MediaQuery.of(context).size.width * 0.5,
                        40,
                      ),
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
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text(
                    'Pick Image',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: Dimens.defaultSpace),
                DropdownMenuFormField(
                  validator: (value) =>
                      UCValidator.validateEmptyText('Expertise', value),
                  width: MediaQuery.of(context).size.width - 32,
                  controller: _expertiseController,
                  menuStyle: MenuStyle(
                    minimumSize: WidgetStateProperty.all(
                      Size(MediaQuery.of(context).size.width - 32, 0),
                    ),
                  ),
                  enableFilter: true,
                  requestFocusOnTap: true,
                  enableSearch: true,
                  label: const Text('Expertise'),
                  dropdownMenuEntries: UCDummyData.degreeEntries,
                ),
                const SizedBox(height: Dimens.defaultSpace),
                DropdownMenuFormField(
                  validator: (value) =>
                      UCValidator.validateEmptyText('Honor', value),
                  width: MediaQuery.of(context).size.width - 32,
                  controller: _honorController,
                  menuStyle: MenuStyle(
                    minimumSize: WidgetStateProperty.all(
                      Size(MediaQuery.of(context).size.width - 32, 0),
                    ),
                  ),
                  enableFilter: true,
                  requestFocusOnTap: true,
                  enableSearch: true,
                  label: const Text('Honor'),
                  dropdownMenuEntries: UCDummyData.honorEntries,
                ),
                const SizedBox(height: Dimens.defaultSpace),
                TextFormField(
                  controller: _usernameController,
                  validator: (value) => UCValidator.validateUsername(value),
                  onChanged: (value) {
                    if (debounce?.isActive ?? false) {
                      debounce!.cancel();
                    }
                    setState(() => isUsernameAvailable = null);
                    debounce = Timer(Duration(milliseconds: 300), () async {
                      final isIt = await ref
                          .read(expertOnboardingProvider.notifier)
                          .isUsernameAvailable(value);
                      setState(() => isUsernameAvailable = isIt);
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Username',
                    suffixIcon: _buildSuffixIcon(),
                  ),
                ),
                const SizedBox(height: Dimens.defaultSpace),
                TextFormField(
                  controller: _bioController,
                  maxLines: 2,
                  maxLength: 70,
                  decoration: InputDecoration(
                    label: const Text('Bio'),
                    hintText: 'Write something about yourself...',
                  ),
                ),
                const SizedBox(height: Dimens.defaultSpace),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                ElevatedButton(
                  onPressed: () async {
                    if (!_key.currentState!.validate()) return;

                    if (isUsernameAvailable != true) return;

                    final status = await ref
                        .read(authNotifierProvider.notifier)
                        .registerExpert(
                      _expertiseController.text.trim(),
                      _honorController.text.trim(),
                      _usernameController.text.trim(),
                      _bioController.text.trim(),
                      _profileImage == null ? null : File(_profileImage!.path),
                    );

                    if (!context.mounted) return;

                    if (status != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(UCHelperFunctions.getErrorMessage(status)),
                        ),
                      );
                      return;
                    }

                    context.go(Routes.home);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                  child: Text('Create Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (_usernameController.text.trim().isEmpty) return null;

    if (isUsernameAvailable == null) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return isUsernameAvailable!
        ? const Icon(Icons.check_circle, color: Colors.green)
        : const Icon(Icons.cancel, color: Colors.red);
  }
}
