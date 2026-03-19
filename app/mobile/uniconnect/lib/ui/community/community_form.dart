import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import 'community_screen.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _pickedImage;

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create New Community',
          style: TextStyle().copyWith(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: true,
      ),
      body: Form(
        key: _key,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.tealAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      image: _pickedImage != null
                          ? DecorationImage(
                              image:
                                  FileImage(File(_pickedImage!.path))
                                      as ImageProvider,
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
              TextFormField(controller: _nameController),
              const SizedBox(height: Dimens.spaceBtwItems),
              //todo: add university name
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
                maxLines: 5,
                maxLength: 250,
              ),
              const SizedBox(height: Dimens.spaceBtwItems),
              //todo: handle this
              SearchBar(
                hintText: 'Include at least 5 members to continue',
                elevation: WidgetStateProperty.all(5),
                onTap: () {},
              ),

              const SizedBox(height: Dimens.spaceBtwSections),
              ElevatedButton(
                onPressed: () {
                  if (!_key.currentState!.validate()) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CommunityScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Text('Create Community'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
