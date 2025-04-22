import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'chat_screen.dart';
import 'market_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with TickerProviderStateMixin {
  bool isDarkTheme = false;
  late TabController tabController;
  final List<String> categories = [
    'For You', 'Sports', 'Entertainment','business', 'Technology', 'Health', 'Science'
  ];

  final String apiKey = '51169299e55d4ef18f1f15d4b147a3c4';
  final Map<String, Future<List<Article>>> categoryFutures = {};

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: categories.length, vsync: this);
    tabController.addListener(_handleTabSelection);
    _loadInitialData();
  }

  @override
  void dispose() {
    tabController.removeListener(_handleTabSelection);
    tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (tabController.indexIsChanging) {
      final currentCategory = categories[tabController.index];
      setState(() {
        categoryFutures[currentCategory] = fetchArticles(currentCategory);
      });
    }
  }

  void _loadInitialData() {
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
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
      ));

  ThemeData get darkTheme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
      ));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkTheme ? darkTheme : lightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('NewzBot'),
            centerTitle: true,
            bottom: TabBar(
              controller: tabController,
              isScrollable: true,
              tabs: categories.map((category) => Tab(text: category)).toList(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
              IconButton(
                icon: Image.asset('lib/Icons/bot.png', 
                  width: 25, 
                  height: 25, 
                  color: isDarkTheme 
                      ? const Color.fromARGB(226, 222, 221, 221) 
                      : const Color.fromARGB(223, 46, 46, 46)),
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
              )
            ],
          ),
          drawer: buildDrawer(context),
          body: TabBarView(
            controller: tabController,
            children: categories.map((category) => 
              FutureBuilder<List<Article>>(
                future: categoryFutures[category],
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading articles'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No articles found'));
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
            ).toList(),
          ),
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
                const Text('Version 0.0.1',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
                const Spacer(),
                const Icon(Icons.account_circle, size: 60, color: Colors.white),
                const Text('Hello User!',
                    style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.newspaper),
            title: const Text('News'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.stacked_line_chart_outlined),
            title: const Text('Market'),
            onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                  MaterialPageRoute(builder: (context) => const MarketPage()),
                  );
                },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Downloads'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_medium),
            title: const Text('App Theme'),
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
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Exit'),
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
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
              const SizedBox(height: 12),
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                article.description,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo(article.publishedAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    article.source,
                    style: const TextStyle(fontSize: 12),
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

class ArticleDetailPage extends StatefulWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late Future<String?> summaryFuture;

  @override
  void initState() {
    super.initState();
    summaryFuture = SummaryService.fetchSummary(widget.article.url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.article.urlToImage.isNotEmpty)
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(widget.article.urlToImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.article.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.article.author,
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.source, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.article.source,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, y - h:mm a').format(widget.article.publishedAt),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<String?>(
              future: summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    children: [
                      LinearProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating summary...'),
                    ],
                  );
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.data ?? 'No summary available',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleWebView(url: widget.article.url),
                  ),
                );
              },
              child: const Text('Read Full Article'),
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
        title: const Text('Full Article'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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

class SummaryService {
  static Future<String?> fetchSummary(String articleUrl) async {
    const apiKey = 'ef87df33cbmsh310a583bffffb57p1cb9d7jsn4f235f7908af';
    const apiHost = 'article-extractor-and-summarizer.p.rapidapi.com';

    try {
      final encodedUrl = Uri.encodeComponent(articleUrl);
      final response = await http.get(
        Uri.parse(
          'https://article-extractor-and-summarizer.p.rapidapi.com/summarize?url=$encodedUrl&lang=en&engine=2'
        ),
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': apiHost,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['summary'] ?? jsonData['message'] ?? 'No summary available';
      }
      return 'Failed to load summary (${response.statusCode})';
    } catch (e) {
      return 'Error: $e';
    }
  }
}