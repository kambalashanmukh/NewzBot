# NewzBot - Article Summarizer and News Chatbot


<img src="lib/Icons/whitelogo.png" alt="NewzBot Logo" width="200" height="200">


NewzBot is a Flutter-based application designed to deliver the latest news updates and provide article summarization in a user-friendly and visually appealing interface. This project serves as a foundation for building a robust news application with advanced chatbot capabilities.

It provides real-time news updates, AI-powered chat summaries, and financial market tracking. Supports user authentication, dark theme, and offline caching.

## Features

- **Firebase Authentication**  
  Email/Password & Google Sign-In
- **Multi-Category News**  
  Browse 7+ categories with images and summaries
- **AI News Chat Bot**  
  Get 2-3 line summarized news updates via chat interface
- **Market Tracking**  
  Real-time stocks, crypto, and forex data with interactive charts
- **Theme Switching**  
  Light/Dark mode support
- **Offline Caching**  
  Hive-based local caching for news and market data
- **WebView Articles**  
  Full article reading within app
- **Smart Search**  
  Search across news titles, content, and sources

## Getting Started

To get started with NewzBot, follow these steps:

1. **Clone the Repository**:
    ```bash
    git clone https://github.com/your-username/newzbot.git
    cd newzbot
    ```

2. **Install Dependencies**:
    Ensure you have Flutter installed. Then, run:
    ```bash
    flutter pub get
    ```

3. **Firebase Setup**:
    create Firebase project at [https://console.firebase.google.com/]
    Enable Authentication (Email/Password & Google)
    Replace "firebase_options.dart" with your credentials

4. **Run the Application**:
    Use the following command to run the app on an emulator or connected device:
    ```bash
    flutter run
    ```

## Prerequisites

- Flutter SDK: [Install Flutter](https://docs.flutter.dev/get-started/install)
- Dart SDK (comes with Flutter)
- Android Studio or Visual Studio Code (with Flutter and Dart plugins)

## API Keys

To use NewzBot, you will need to obtain API keys for the following services:

1. **News API**  
    Used for fetching real-time news updates.  
    [Get your API key here](https://newsapi.org/).

2. **Article Extractor and Summarizer**  
    Used for extracting text from news URLs and summarizing them.  
    [Get your API key here](https://rapidapi.com/restyler/api/article-extractor-and-summarizer).

3. **Groq API**  
    Powers the AI-based news summarization chatbot.  
    [Get your API key here](https://console.groq.com/keys).

4. **Financial Data API**  
    Provides real-time stock, cryptocurrency, and forex market data.  
    Example: [Alpha Vantage](https://rapidapi.com/alphavantage/api/alpha-vantage) 

5. **Firebase**  
    Used for authentication and backend services.  
    [Set up Firebase for your project](https://firebase.google.com/).

Make sure to add these keys to your environment configuration securely.

## Folder Structure

```
newzbot/
├── lib/
│   ├── main.dart         # Entry point of the application
│   ├── screens/          # UI screens
│   ├── models/           # Data models
│   ├── services/         # API and data fetching logic
│   └── widgets/          # Reusable UI components
├── assets/               # Images, fonts, and other assets
├── pubspec.yaml          # Project dependencies
└── README.md             # Project documentation
```

## Resources

Here are some helpful resources to guide you through Flutter development:

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Dart Language Tour](https://dart.dev/guides/language)
- [Firebase](https://firebase.google.com/docs)

## Contributing

Contributions are welcome! If you'd like to contribute to NewzBot, please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For any inquiries or feedback, feel free to reach out:

- Email: kambalashannu123@gmail.com
- GitHub: [kambalashanmukh](https://github.com/kambalashanmukh)

Happy coding!
