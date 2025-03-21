import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with TickerProviderStateMixin {
  bool isDarkTheme = false;
  int selectedIndex = 0;
  int? expandedCardIndex;
  late TabController tabController;
  final List<String> categories = [
    'For You', 'Sports', 'Entertainment', 'Technology', 'Health', 'Science'
  ];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  ThemeData get lightTheme => ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
        ),
      );

  ThemeData get darkTheme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkTheme ? darkTheme : lightTheme,
      home: Scaffold(
        appBar: AppBar(
          title: Text('NewzBot'),
          centerTitle: true,
          bottom: TabBar(
            controller: tabController,
            isScrollable: true,
            tabs: categories.map((category) => Tab(text: category)).toList(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
        drawer: buildDrawer(context),
        body: TabBarView(
          controller: tabController,
          children: categories.map((category) => 
            SingleChildScrollView(
              child: Column(
                children: List.generate(10, (index) => NewsCard(
                  category: category,
                  index: index,
                  expandedIndex: expandedCardIndex,
                  onExpand: (index) => setState(() => expandedCardIndex = index),
                )),
              ),
            )).toList(),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.assistant_outlined),
              selectedIcon: Icon(Icons.assistant_rounded),
              label: 'ChatBot',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_border),
              selectedIcon: Icon(Icons.star),
              label: 'Starred',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDarkTheme ? Colors.blueGrey : Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version 0.0.1',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
                    Spacer(),
                    Icon(Icons.account_circle, size: 60, color: Colors.white),
                Text('Hello User!',
                    style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Account'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.download),
            title: Text('Downloads'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.brightness_medium),
            title: Text('App Theme'),
            trailing: _ThemeSwitch(
              value: isDarkTheme,
              onChanged: (value) {
                setState(() {
                  isDarkTheme = value;
                });
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Exit'),
            onTap: () => SystemNavigator.pop(),
          ),
        ],
      ),
    );
  }
}

class NewsCard extends StatefulWidget {
  final String category;
  final int index;
  final int? expandedIndex;
  final Function(int?) onExpand;

  const NewsCard({
    super.key,
    required this.category,
    required this.index,
    required this.expandedIndex,
    required this.onExpand,
  });

  @override
  NewsCardState createState() => NewsCardState();
}

class NewsCardState extends State<NewsCard> {
  static const double collapsedHeight = 150,expandedHeight = 300,padding = 5.0,cardElevation = 4.0;
  static const double borderRadius = 12.0,iconSize = 16.0,imageSizeCollapsed = 100.0,imageSizeExpanded = 150.0;
  static const Duration animationDuration = Duration(milliseconds: 300), imageAnimationDuration = Duration(milliseconds: 300);
  bool get isExpanded => widget.expandedIndex == widget.index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: GestureDetector(
        onTap: () {
          widget.onExpand(isExpanded ? null : widget.index);
        },
        child: AnimatedContainer(
          duration: animationDuration,
          curve: Curves.easeInOut,
          height: isExpanded ? expandedHeight : collapsedHeight,
          child: Card(
            elevation: cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HeadLine',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('article description',
                            style: TextStyle(color: Colors.grey.shade600)),
                        if (isExpanded) ...[
                          SizedBox(height: 12),
                          Text('summarized article content ...',
                              style: TextStyle(fontSize: 14)),
                        ],
                        Spacer(),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: iconSize),
                            SizedBox(width: 4),
                            Text('2h ago', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  AnimatedContainer(
                    duration: imageAnimationDuration,
                    width: isExpanded ? imageSizeExpanded : imageSizeCollapsed,
                    height: isExpanded ? imageSizeExpanded : imageSizeCollapsed,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.image,
                        size: isExpanded ? 60 : 40,
                        color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// dark and light theme switch
class _ThemeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ThemeSwitch({
    required this.value,
    required this.onChanged,
  });

  static const double switchWidth = 60,switchHeight = 30,switchBorderRadius = 15, circleSize = 30;
  static const Duration switchAnimationDuration = Duration(milliseconds: 300),circleAnimationDuration = Duration(milliseconds: 50);

  // toggle button
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: switchAnimationDuration,
        curve: Curves.easeInOut,
        width: switchWidth,
        height: switchHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(switchBorderRadius),
          color: value ? Colors.grey[800] : Colors.grey[300],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: circleAnimationDuration,
              curve: Curves.easeInOut,
              left: value ? switchWidth / 2 : 0,
              right: value ? 0 : switchWidth / 2,
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: value ? Colors.blueGrey : Colors.yellow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  value ? Icons.nightlight_round : Icons.wb_sunny,
                  color: value ? Colors.white : Colors.orange[800],
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}