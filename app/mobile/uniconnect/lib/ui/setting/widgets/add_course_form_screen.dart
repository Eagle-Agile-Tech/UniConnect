import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../../utils/helper_functions.dart';
import '../../../utils/validator.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('Add Course'),
      ),
      body: Form(
        key: _key,
        child: Padding(
          padding: const EdgeInsets.all(Dimens.defaultSpace),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                validator: (value) =>
                    UCValidator.validateEmptyText('Title', value),
                decoration: InputDecoration(label: Text('Title')),
              ),
              const SizedBox(height: Dimens.spaceBtwItems),
              TextFormField(
                controller: _descriptionController,
                validator: (value) =>
                    UCValidator.validateEmptyText('Description', value),
                maxLines: 4,
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
                decoration: InputDecoration(label: Text('Description')),
              ),
              const SizedBox(height: Dimens.spaceBtwItems),
              TextFormField(
                controller: _linkController,
                validator: (value) => UCValidator.validateLink(value),
                decoration: InputDecoration(
                  label: Text('Link'),
                  hintText: 'Provide a link to the landing page of the course!',
                ),
              ),
              const SizedBox(height: Dimens.spaceBtwItems),
              TextFormField(
                controller: _feeController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(label: Text('Fee')),
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
                        if (_key.currentState!.validate()) {
                          final isWorking = await UCHelperFunctions.doesUrlWork(
                            _linkController.text.trim(),
                          );
                          if (!isWorking) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Provide a working link!"),
                              ),
                            );
                            return;
                          }
                        }
                      },
                      child: Text('Create Course'),
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
