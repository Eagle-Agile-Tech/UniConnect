import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/explore/widgets/explore_item.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late CarouselController _controller;
  int _currentIndex = 0;
  final _totalItems = 5;

  double get _itemWidth =>
      MediaQuery.of(context).size.width - Dimens.defaultSpace;

  @override
  void initState() {
    super.initState();
    _controller = CarouselController(initialItem: 0);
    _controller.addListener(() {
      int next = (_controller.offset / (_itemWidth)).round();
      next = next.clamp(0, _totalItems - 1);
      if (next != _currentIndex) {
        setState(() {
          _currentIndex = next;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Explore',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.sm),
          child: Column(
            children: [
              const SizedBox(height: Dimens.sm),
              SearchBar(
                hintText: 'What are you looking for?',
                hintStyle: WidgetStatePropertyAll(
                  TextStyle(fontWeight: FontWeight.w600),
                ),
                elevation: WidgetStateProperty.all(0),
                leading: Icon(Icons.search, size: Dimens.iconLg),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(Dimens.radiusLg),
                  ),
                ),
                onTap: (){
                  context.push(Routes.search);
                },
              ),
              const SizedBox(height: Dimens.spaceBtwItems),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                mainAxisSpacing: Dimens.sm,
                crossAxisSpacing: Dimens.sm,
                children: [
                  ExploreItem(
                    color: Color(0xFF00786A),
                    title: 'Communities',
                    image: Assets.event,
                  ),
                  ExploreItem(
                    color: Colors.deepOrange,
                    title: 'Events',
                    image: Assets.event,
                  ),
                  ExploreItem(
                    color: Colors.deepPurpleAccent,
                    title: 'Hackathon',
                    image: Assets.jobBoard,
                  ),
                  ExploreItem(
                    color: Color(0xFF10B981),
                    title: 'Job Boards',
                    image: Assets.jobBoard,
                  ),
                  ExploreItem(
                    color: Color(0xFF744B93),
                    title: 'Tips & Tricks',
                    image: Assets.event,
                  ),
                  ExploreItem(
                    color: Color(0xFF315E59),
                    title: 'Support',
                    image: Assets.event,
                  ),
                  ExploreItem(
                    color: Color(0xFFA5CB24),
                    title: 'Mentorship',
                    image: Assets.tips,
                  ),
                  ExploreItem(
                    color: Color(0xFFF9D704),
                    title: 'Universities',
                    image: Assets.tips,
                  ),
                ],
              ),
              const SizedBox(height: Dimens.spaceBtwItems),
              SizedBox(
                height: Dimens.carouselImageHeight,
                child: CarouselView(
                  controller: _controller,
                  itemExtent: _itemWidth,
                  shrinkExtent: _itemWidth,
                  itemSnapping: true,
                  elevation: 5,
                  padding: EdgeInsets.all(Dimens.sm),
                  children: [
                    ...List.generate(_totalItems, (index) {
                      return Container(
                        color: Colors.grey,
                        child: Image.asset(Assets.post2, fit: BoxFit.cover),
                      );
                    }),
                  ],
                ),
              ),
        
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalItems, (index) {
                  bool isActive = index == _currentIndex;
                  return InkWell(
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      _controller.animateTo(
                        index * _itemWidth,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: isActive ? 24 : 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: Dimens.xs),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(Dimens.radiusSm),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
