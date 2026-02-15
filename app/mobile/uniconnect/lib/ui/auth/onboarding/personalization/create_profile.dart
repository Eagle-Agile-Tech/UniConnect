import 'package:flutter/material.dart';
import 'package:uniconnect/config/dummy_data.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/app_bar.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

class CreateProfile extends StatelessWidget {
  const CreateProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UCAppBar('Create Profile'),
      body: SingleChildScrollView(
        child: Padding(
          padding: UCSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              Center(child: CircleAvatar(radius: Dimens.avatarLg)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {},
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
                maxLines: 2,
                maxLength: 70,
                decoration: InputDecoration(
                  label: const Text('Bio'),
                  hintText: 'Write something about yourself...',
                ),
              ),
              const SizedBox(height: Dimens.defaultSpace),
              DropdownMenu(
                dropdownMenuEntries: UCDummyData.interestEntries,
                enableFilter: true,
                label: const Text('Interests'),
                menuStyle: MenuStyle(
                  maximumSize: WidgetStateProperty.all(
                    const Size.fromHeight(300),
                  ),
                ),
              ),
              const SizedBox(height: Dimens.spaceBtwSections),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Text('Create Profile')
              ),
            ],
          ),
        ),
      ),
    );
  }
}
