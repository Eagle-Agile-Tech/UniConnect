import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[200]?.withValues(alpha: 0.6),
        leading: IconButton(
          onPressed: context.pop,
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        titleSpacing: 0,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(Assets.avatar1),
          ),
          title: Text(
            'Iman Yilma',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text('Online'),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert),
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: Dimens.spaceBtwSections),
          Expanded(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.only(right: 70, left: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'So where the hell is my Gucci bag, bruh? I am dead serious',
                          style: TextStyle(fontSize: 16),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '12:45 PM',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600]?.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Dimens.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.only(left: 70, right: 10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent[400]?.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'It\'s all outsold. let me get you Chanel bag instead',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '12:46 PM',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.emoji_emotions_outlined),
                  color: Colors.grey[600],
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration().copyWith(
                      hintText: 'Type a message',
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // TODO: change to send icon when text is entered
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.mic),
                  color: Colors.deepPurple[600]?.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
