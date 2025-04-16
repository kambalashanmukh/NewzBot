import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with TickerProviderStateMixin {
  bool isDarkTheme = false;
  int selectedIndex = 0;
  late TabController tabController;
  final List<String> categories = [
    'For You', 'Sports', 'Entertainment', 'Technology', 'Health', 'Science'
  ];

  final String apiKey = 'b21b107a4bb0432497f5586be3a482ce';
  final Map<String, Future<List<Article>>> categoryFutures = {};

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: categories.length, vsync: this);
    for (var category in categories) {
      categoryFutures[category] = fetchArticles(category);
    }
  }

  Future<List<Article>> fetchArticles(String category) async {
    String apiCategory = category == 'For You' 
        ? 'general' 
        : category == 'Science' 
            ? 'science' 
            : category.toLowerCase();
    
    final response = await http.get(Uri.parse(
      'https://newsapi.org/v2/top-headlines?country=us&category=$apiCategory&apiKey=$apiKey'
    ));

    if (response.statusCode == 200) {
      List<Article> articles = [];
      var jsonData = jsonDecode(response.body);
      for (var item in jsonData['articles']) {
        if (item['title'] != null && item['description'] != null) {
          articles.add(Article(
            title: item['title'],
            description: item['description'],
            content: item['content'] ?? 'No content available',
            urlToImage: item['urlToImage'] ?? '',
            publishedAt: DateTime.parse(item['publishedAt']),
            author: item['author'] ?? 'Unknown',
            source: item['source']['name'] ?? 'Unknown source',
            url: item['url'] ?? '',
          ));
        }
      }
      return articles;
    } else {
      throw Exception('Failed to load articles');
    }
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
            IconButton(
              icon: Image.asset('lib/Icons/bot.png', 
                width: 25, 
                height: 25, 
                color: isDarkTheme 
                    ? Color.fromARGB(226, 222, 221, 221) 
                    : const Color.fromARGB(223, 46, 46, 46)),
              onPressed: () {},
            )
          ],
        ),
        drawer: buildDrawer(context),
        body: TabBarView(
          controller: tabController,
          children: categories.map((category) => 
            RefreshIndicator(
              onRefresh: () async {
                final newFuture = fetchArticles(category);
                setState(() => categoryFutures[category] = newFuture);
                await newFuture;
              },
              child: FutureBuilder<List<Article>>(
                future: categoryFutures[category],
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading articles'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No articles found'));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final article = snapshot.data![index];
                      return NewsCard(
                        article: article,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArticleDetailPage(article: article),
                          ));
                        },
                      );
                    },
                  );
                },
              ),
            )).toList(),
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
            leading: Icon(Icons.newspaper),
            title: Text('News'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.stacked_line_chart_outlined),
            title: Text('Market'),
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

class Article {
  final String title;
  final String description;
  final String content;
  final String urlToImage;
  final DateTime publishedAt;
  final String author;
  final String source;
  final String url;

  Article({
    required this.title,
    required this.description,
    required this.content,
    required this.urlToImage,
    required this.publishedAt,
    required this.author,
    required this.source,
    required this.url,
  });
}

class NewsCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const NewsCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.urlToImage.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(article.urlToImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              SizedBox(height: 12),
              Text(
                article.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                article.description,
                style: TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16),
                  SizedBox(width: 4),
                  Text(
                    timeAgo(article.publishedAt),
                    style: TextStyle(fontSize: 12),
                  ),
                  Spacer(),
                  Text(
                    article.source,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return DateFormat('MMM d, y').format(date);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class ArticleDetailPage extends StatelessWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Article Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.urlToImage.isNotEmpty)
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(article.urlToImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            SizedBox(height: 16),
            Text(
              article.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16),
                SizedBox(width: 4),
                Text(
                  article.author,
                  style: TextStyle(fontSize: 14),
                ),
                Spacer(),
                Icon(Icons.source, size: 16),
                SizedBox(width: 4),
                Text(
                  article.source,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16),
                SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, y - h:mm a').format(article.publishedAt),
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              article.content,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleWebView(url: article.url),
                  ),
                );
              },
              child: Text('Read Full Article'),
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleWebView extends StatefulWidget {
  final String url;

  const ArticleWebView({super.key, required this.url});

  @override
  State<ArticleWebView> createState() => _ArticleWebViewState();
}

class _ArticleWebViewState extends State<ArticleWebView> {
  late final WebViewController _controller;
  var loadingPercentage = 0;

  @override
  void initState() {
    super.initState();
    
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              loadingPercentage = progress;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              loadingPercentage = 0;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              loadingPercentage = 100;
            });
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Article'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (loadingPercentage < 100)
            LinearProgressIndicator(
              value: loadingPercentage / 100.0,
              backgroundColor: Colors.white,
              color: Colors.blue,
            ),
        ],
      ),
    );
  }
}

class _ThemeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ThemeSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 60,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? Colors.grey[800] : Colors.grey[300],
        ),
        child: Stack(
          children: [
            Positioned(
              left: value ? 30 : 0,
              right: value ? 0 : 30,
              child: Container(
                width: 30,
                height: 30,
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