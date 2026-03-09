import 'package:flutter/material.dart';

class DrawerContent extends StatelessWidget {
  const DrawerContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(title: Text('Create a community'), trailing: Icon(Icons.add)),
        Divider(),
        ListTile(title: Text('Recently Visited'), trailing: Icon(Icons.keyboard_arrow_right),),
        ListTile(title: Text('Your Communities'), trailing: Icon(Icons.keyboard_arrow_right),),
        Spacer(),
        Divider(thickness: 1,),
        ListTile(title: Text('UniConnect Rules'), leading: Icon(Icons.rule),),
        ListTile(title: Text('Privacy Policy'), leading: Icon(Icons.privacy_tip),),
      ],
    );
  }
}