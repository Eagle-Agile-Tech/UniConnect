import 'package:flutter/material.dart';
import 'package:uniconnect/config/dummy_data.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/app_bar.dart';

import '../../../core/theme/dimens.dart';

class AcademicProfile extends StatelessWidget {
  const AcademicProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UCAppBar('Academic Profile'),
      body: SingleChildScrollView(
        child: Padding(
          padding: UCSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              Form(
                child: Column(
                  children: [
                    DropdownMenu(
                      menuStyle: MenuStyle(
                        minimumSize: WidgetStateProperty.all(
                          Size(MediaQuery.of(context).size.width - 32, 0),
                        ),
                      ),
                      enableFilter: true,
                      label: const Text('University'),
                      dropdownMenuEntries: UCDummyData.universityEntries,
                    ),
                    const SizedBox(height: Dimens.defaultSpace),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Degree Program',
                      ),
                    ),
                    const SizedBox(height: Dimens.defaultSpace),
                    Row(
                      children: [
                        Flexible(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Year of Study',
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimens.spaceBtwItems),
                        Flexible(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Expected Graduation Year',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimens.spaceBtwSections),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
