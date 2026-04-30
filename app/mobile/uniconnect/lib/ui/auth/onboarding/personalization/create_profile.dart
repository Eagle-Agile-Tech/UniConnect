import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';
import 'package:uniconnect/config/dummy_data.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';
import 'package:uniconnect/ui/auth/onboarding/view_models/onboarding_viewmodel_provider.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/app_bar.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/utils/helper_functions.dart';
import 'package:uniconnect/utils/validator.dart';

class CreateProfile extends ConsumerStatefulWidget {
  const CreateProfile({super.key});

  @override
  ConsumerState<CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends ConsumerState<CreateProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;

  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  List<InterestRecord> _selectedInterests = [];

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
    _bioController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboard = ref.watch(onboardingProvider);
    final onboarding = ref.watch(onboardingProvider.notifier);
    final authState = ref.watch(authNotifierProvider.notifier);
    return Scaffold(
      appBar: UCAppBar('Create Profile'),
      body: SingleChildScrollView(
        child: Padding(
          padding: UCSpacingStyle.paddingWithAppBarHeight,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: Dimens.avatarLg,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    backgroundImage: _profileImage != null
                        ? FileImage(File(_profileImage!.path))
                        : null,
                    child: _profileImage == null
                        ? Icon(
                            Icons.person,
                            size: Dimens.avatarLg,
                            color: Colors.grey,
                          )
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
                          .watch(onboardingProvider.notifier)
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
                MultiSelectDialogField<InterestRecord>(
                  validator: (value) => UCValidator.validateInterest(value),
                  items: UCDummyData.interestEntries,
                  title: const Text('Select Interests'),
                  listType: MultiSelectListType.CHIP,
                  separateSelectedItems: true,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  buttonIcon: Icon(
                    Icons.interests,
                    color: Theme.of(context).primaryColor,
                  ),
                  buttonText: Text(
                    "Interests",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                    ),
                  ),
                  onConfirm: (selected) {
                    setState(() {
                      _selectedInterests = selected;
                    });
                  },
                  chipDisplay: MultiSelectChipDisplay(
                    items: _selectedInterests
                        .map((e) => MultiSelectItem(e, e.interest))
                        .toList(),
                    scroll: true,
                    chipColor: Colors.white,
                    textStyle: TextStyle(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimens.radiusLg),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    onTap: (value) {
                      setState(() {
                        _selectedInterests.remove(value);
                      });
                    },
                  ),
                ),
                const SizedBox(height: Dimens.spaceBtwSections),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                ElevatedButton(
                  onPressed: (onboard.isLoading)
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          if(isUsernameAvailable != true) return;

                          final bioText = _bioController.text.trim();
                          final bioToSend = bioText.isEmpty ? null : bioText;

                          final interestsToSend = _selectedInterests.isEmpty
                              ? null
                              : _selectedInterests;

                          File? profileImageFile = _profileImage != null
                              ? File(_profileImage!.path)
                              : null;

                          ref
                              .read(onboardingProvider.notifier)
                              .updateProfile(
                                _usernameController.text.trim(),
                                bioToSend,
                                interestsToSend,
                                profileImageFile,
                              );

                          final result = await ref
                              .read(authNotifierProvider.notifier)
                              .registerStudent();

                          if (result == null) {
                            context.go(Routes.home);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  UCHelperFunctions.getErrorMessage(result),
                                ),
                              ),
                            );
                          }
                        },
                  child: onboard.isLoading
                      ? CircularProgressIndicator()
                      : const Text('Create Profile'),
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
