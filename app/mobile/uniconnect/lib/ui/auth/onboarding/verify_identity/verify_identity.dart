import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/core/common/widgets/app_bar.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import 'package:uniconnect/utils/helper_functions.dart';

import '../view_models/onboarding_viewmodel_provider.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _frontImage;
  XFile? _backImage;

  final GlobalKey _cameraKey = GlobalKey();
  final GlobalKey _cameraKeyBack = GlobalKey();

  void _pickFrontImage(String source) async {
    final XFile? picked = await _picker.pickImage(
      source: source == "camera" ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked != null && mounted) {
      setState(() => _frontImage = picked);
    }
  }

  void _pickBackImage(String source) async {
    final XFile? picked = await _picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked != null && mounted) {
      setState(() => _backImage = picked);
    }
  }

  Future<void> _showPickerMenu(
    GlobalKey key,
    Function(String) onSelected,
  ) async {
    final context = key.currentContext;
    if (context == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy,
      offset.dx + renderBox.size.width,
      offset.dy + renderBox.size.height,
    );

    final selected = await showMenu<String>(
      context: this.context,
      position: position,
      items: const [
        PopupMenuItem(value: 'camera', child: Text('Camera')),
        PopupMenuItem(value: 'gallery', child: Text('Gallery')),
      ],
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboard = ref.watch(onboardingProvider);
    return Scaffold(
      appBar: UCAppBar(
        'Identity Verification',
        showBack: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(Dimens.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Your Identity',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              SizedBox(height: Dimens.spaceBtwItems),
              const Text(
                'Please provide clear photos of your institution issued ID. Ensure all details are legible and within the frame.',
              ),
              SizedBox(height: Dimens.spaceBtwItems),

              Text(
                'Front of ID',
                style: TextStyle(
                  fontSize: Dimens.fontMd,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Dimens.spaceBtwItems),

              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(Dimens.md),
                  image: _frontImage != null
                      ? DecorationImage(
                          image: FileImage(File(_frontImage!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              SizedBox(height: Dimens.spaceBtwItems),

              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    key: _cameraKey,
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        _showPickerMenu(_cameraKey, _pickFrontImage),
                    child: const Text('Upload Front Photo'),
                  ),
                ),
              ),

              SizedBox(height: Dimens.spaceBtwSections),

              Text(
                'Back of ID',
                style: TextStyle(
                  fontSize: Dimens.fontMd,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Dimens.spaceBtwItems),

              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(Dimens.md),
                  image: _backImage != null
                      ? DecorationImage(
                          image: FileImage(File(_backImage!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              SizedBox(height: Dimens.spaceBtwItems),

              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    key: _cameraKeyBack,
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        _showPickerMenu(_cameraKeyBack, _pickBackImage),
                    child: const Text('Upload Back Photo'),
                  ),
                ),
              ),

              SizedBox(height: Dimens.spaceBtwSections),

              ElevatedButton(
                onPressed: onboard.isLoading ? null : () async {
                  if (_frontImage == null || _backImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please upload both front and back images',
                        ),
                      ),
                    );
                    return;
                  }
                  final status = await ref
                      .read(onboardingProvider.notifier)
                      .verifyId(
                        File(_frontImage!.path),
                        File(_backImage!.path),
                      );
                  if (status != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(UCHelperFunctions.getErrorMessage(status))));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Your Id is uploaded for admin verification. We\'ll notify you soon .',
                        ),
                      ),
                    );
                    context.go(Routes.onboardingAcademic);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(color: onboard.isLoading ? Colors.grey : Theme.of(context).primaryColor),
                ),
                child: onboard.isLoading ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                ) : const Text('Verify ID'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
