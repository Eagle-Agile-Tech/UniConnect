import 'package:flutter/material.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Post'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.clear),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              const SizedBox(height: Dimens.spaceBtwSections),
              Align(
                alignment: Alignment.topRight,
                child: ElevatedButton(onPressed: () {}, child: Text('Post')),
              ),
              const SizedBox(height: Dimens.spaceBtwItems),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: Dimens.sm),
                  child: TextFormField(
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(fontSize: 18, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Bleed your ink...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Dimens.spaceBtwItems),
              Divider(thickness: 1,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(onPressed: () {}, icon: Icon(Icons.image_outlined)),
                  IconButton(onPressed: () {}, icon: Icon(Icons.pin_drop_outlined)),
                  IconButton(onPressed: () {}, icon: Icon(Icons.tag_faces_outlined)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
