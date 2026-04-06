import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uniconnect/config/dummy_data.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/app_bar.dart';
import 'package:uniconnect/utils/validator.dart';

import '../../../core/theme/dimens.dart';
import '../view_models/onboarding_viewmodel_provider.dart';

class AcademicProfile extends ConsumerStatefulWidget {
  const AcademicProfile({super.key});

  @override
  ConsumerState<AcademicProfile> createState() => _AcademicProfileState();
}

class _AcademicProfileState extends ConsumerState<AcademicProfile> {
  final GlobalKey<FormState> _academicProfileFormKey = GlobalKey<FormState>();

  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _degreeProgramController =
      TextEditingController();
  final TextEditingController _yearOfStudyController = TextEditingController();
  final TextEditingController _expectedGraduationYearController =
      TextEditingController();
  DateTime? _selectedGraduationDate;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(onboardingProvider);

    if (initialState.university.isNotEmpty &&
        initialState.university.toLowerCase() != 'general') {
      _universityController.text = initialState.university;
    }
  }

  @override
  void dispose() {
    _universityController.dispose();
    _degreeProgramController.dispose();
    _yearOfStudyController.dispose();
    _expectedGraduationYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.read(onboardingProvider.notifier);
    final onBoardingState = ref.watch(onboardingProvider);
    return Scaffold(
      appBar: UCAppBar('Academic Profile', showBack: false, centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(Dimens.defaultSpace),
          child: Column(
            children: [
              Form(
                key: _academicProfileFormKey,
                child: Column(
                  children: [
                    DropdownMenuFormField(
                      controller: _universityController,
                      enabled:
                          onBoardingState.university.isNotEmpty &&
                              onBoardingState.university !=
                                  'general'
                          ? false
                          : true,
                      validator: (value) => UCValidator.validateEmptyText(
                        'University',
                        _universityController.text.trim(),
                      ),
                      menuStyle: MenuStyle(
                        minimumSize: WidgetStateProperty.all(
                          Size(MediaQuery.of(context).size.width - 32, 0),
                        ),
                      ),
                      enableFilter: true,
                      requestFocusOnTap: true,
                      enableSearch: true,
                      label: const Text('University'),
                      dropdownMenuEntries: UCDummyData.universityEntries,
                    ),
                    const SizedBox(height: Dimens.defaultSpace),
                    DropdownMenuFormField(
                      validator: (value) =>
                          UCValidator.validateEmptyText('Major', value),
                      width: MediaQuery.of(context).size.width - 32,
                      controller: _degreeProgramController,
                      menuStyle: MenuStyle(
                        minimumSize: WidgetStateProperty.all(
                          Size(MediaQuery.of(context).size.width - 32, 0),
                        ),
                      ),
                      enableFilter: true,
                      requestFocusOnTap: true,
                      enableSearch: true,
                      label: const Text('Degree Program'),
                      dropdownMenuEntries: UCDummyData.degreeEntries,
                    ),
                    const SizedBox(height: Dimens.defaultSpace),
                    Row(
                      children: [
                        Flexible(
                          child: TextFormField(
                            validator: (value) => UCValidator.validateEmptyText(
                              'Year of Study',
                              value,
                            ),
                            controller: _yearOfStudyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                              FilteringTextInputFormatter.deny(RegExp(r'^0')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Year of Study',
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimens.spaceBtwItems),
                        Flexible(
                          child: TextFormField(
                            validator: (value) => UCValidator.validateEmptyText(
                              'Graduation Date',
                              value,
                            ),
                            readOnly: true,
                            showCursor: false,
                            onTap: null,
                            enableInteractiveSelection: false,
                            controller: _expectedGraduationYearController,
                            decoration: InputDecoration(
                              labelText: 'Expected Graduation Year',
                              prefixIcon: IconButton(
                                onPressed: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2017),
                                    lastDate: DateTime(2040),
                                    initialDate: DateTime(2021),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      _selectedGraduationDate = pickedDate;
                                      _expectedGraduationYearController.text =
                                          DateFormat.yMMMd().format(pickedDate);
                                    });
                                  }
                                },
                                icon: Icon(Icons.calendar_month_sharp),
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimens.spaceBtwSections),
                    ElevatedButton(
                      onPressed: () {
                        if (!_academicProfileFormKey.currentState!.validate()) {
                          return;
                        }
                        onboarding.updateAcademic(
                          _universityController.text.trim(),
                          _degreeProgramController.text.trim(),
                          _yearOfStudyController.text.trim(),
                          _selectedGraduationDate!,
                        );
                        context.push(Routes.onBoardingProfile);
                      },
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
