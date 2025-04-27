//importing all the necessary packages.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

//importing all the dart files.
import 'firebase_options.dart';
import 'auth_service.dart';
import 'chat_screen.dart';
import 'downloads_page.dart';
import 'login_screen.dart';
import 'market_page.dart';

// Main entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  Hive.registerAdapter(MarketDataAdapter());
  await Hive.openBox<MarketData>('marketData');

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>.value(
          value: AuthService().authStateChanges,
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with TickerProviderStateMixin {
  bool isDarkTheme = false;
  bool _isSearching = false;
  late TabController tabController;
  final List<String> categories = [
    'For You', 'Sports', 'Entertainment', 'Business', 'Technology', 'Health', 'Science'
  ];
  final String apiKey = 'your_news_api_key_here'; // Replace with your actual API key
  final Map<String, Future<List<Article>>> categoryFutures = {};
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: categories.length, vsync: this)
      ..addListener(_handleTabSelection);
    _loadInitialData();
  }

  @override
  void dispose() {
    tabController.removeListener(_handleTabSelection);
    tabController.dispose();
    searchController.dispose();
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
    final apiCategory = category == 'For You' ? 'general' : category.toLowerCase();
    final response = await http.get(Uri.parse(
      'https://newsapi.org/v2/top-headlines?country=us&category=$apiCategory&apiKey=$apiKey',
    ));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return (jsonData['articles'] as List)
          .where((item) => item['title'] != null && item['description'] != null)
          .map((item) => Article(
                title: item['title'],
                description: item['description'],
                content: item['content'] ?? 'No content available',
                urlToImage: item['urlToImage'] ?? '',
                publishedAt: DateTime.parse(item['publishedAt']),
                author: item['author'] ?? 'Unknown',
                source: item['source']['name'] ?? 'Unknown source',
                url: item['url'] ?? '',
              ))
          .toList();
    }
    return [];
  }

  List<Article> _filterArticles(List<Article> articles) {
    if (searchQuery.isEmpty) return articles;
    final query = searchQuery.toLowerCase();
    return articles.where((article) {
      return article.title.toLowerCase().contains(query) ||
          article.description.toLowerCase().contains(query) ||
          article.content.toLowerCase().contains(query) ||
          article.source.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: _buildAppBar(context),
          drawer: _buildDrawer(context),
          body: TabBarView(
            controller: tabController,
            children: categories.map((category) {
              return FutureBuilder<List<Article>>(
                future: categoryFutures[category],
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading articles'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No articles found'));
                  }
                  final filteredArticles = _filterArticles(snapshot.data!);
                  return ListView.builder(
                    itemCount: filteredArticles.length,
                    itemBuilder: (context, index) {
                      final article = filteredArticles[index];
                      return NewsCard(
                        article: article,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleDetailPage(article: article),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search articles...',
                border: InputBorder.none,
              ),
              style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
              onChanged: (value) => setState(() => searchQuery = value),
              onSubmitted: (value) => setState(() {
                searchQuery = value;
                _isSearching = false;
              }),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  child: Image.asset(
                    isDarkTheme ? 'lib/Icons/whitelogo.png' : 'lib/Icons/blacklogo.png',
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 5),
                const Text('NewzBot'),
              ],
            ),
      centerTitle: true,
      bottom: TabBar(
        controller: tabController,
        isScrollable: true,
        tabs: categories.map((category) => Tab(text: category)).toList(),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () => setState(() {
            if (_isSearching) {
              _isSearching = false;
              searchQuery = '';
              searchController.clear();
            } else {
              _isSearching = true;
            }
          }),
        ),
        IconButton(
          icon: Image.asset(
            'lib/Icons/bot.png',
            width: 25,
            height: 25,
            color: isDarkTheme
                ? const Color.fromARGB(226, 222, 221, 221)
                : const Color.fromARGB(223, 46, 46, 46),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = Provider.of<User?>(context);
    final avatarUrl = user != null
        ? 'https://api.dicebear.com/7.x/personas/png?seed=${Uri.encodeComponent(user.uid)}'
        : '';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.displayName ?? user?.email ?? 'Guest User',
              style: const TextStyle(fontSize: 18),
            ),
            accountEmail: user != null
                ? Text(user.email!)
                : const Text('Not logged in'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: isDarkTheme ? Colors.blueGrey[800] : Colors.blue[100],
              child: ClipOval(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.person,
                    size: 48,
                    color: isDarkTheme ? Colors.white : Colors.blue[800],
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return CircularProgressIndicator(
                      value: loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1),
                    );
                  },
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: isDarkTheme ? Colors.blueGrey : Colors.blue,
            ),
          ),
          if (user == null)
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Login'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await Provider.of<AuthService>(context, listen: false).signOut();
                  Navigator.pop(context);
                }
              },
            ),
          ..._buildDrawerOptions(context),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerOptions(BuildContext context) {
    return [
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
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DownloadsPage()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.brightness_medium),
        title: const Text('App Theme'),
        trailing: _ThemeSwitch(
          value: isDarkTheme,
          onChanged: (value) => setState(() => isDarkTheme = value),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.exit_to_app),
        title: const Text('Exit'),
        onTap: () => SystemNavigator.pop(),
      ),
    ];
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
    final user = Provider.of<User?>(context); // Get the current user

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              if (user == null) {
                // Show dialog if user is not logged in
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Login Required'),
                      content: const Text('Login to download this article.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(), // Close dialog
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                // Handle download logic here if user is logged in
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download started!')),
                );
              }
            },
          ),
        ],
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
    const apiKey = 'your_rapidapi_key_here'; // Replace with your actual API key
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