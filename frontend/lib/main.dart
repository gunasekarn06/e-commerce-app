import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_language.dart';
import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLanguageController _languageController =
      AppLanguageController.instance;
  late final Future<void> _loadSettings;

  @override
  void initState() {
    super.initState();
    _loadSettings = _languageController.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadSettings,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !_languageController.isReady) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return AnimatedBuilder(
          animation: _languageController,
          builder: (context, _) {
            final language = _languageController.current;

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: language.locale,
              supportedLocales: AppLanguages.all
                  .map((option) => option.locale)
                  .toSet()
                  .toList(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(fontFamily: language.fontFamily),
              builder: (context, child) {
                return DefaultTextStyle.merge(
                  style: TextStyle(
                    fontFamily: language.fontFamily,
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const LoginPage(),
              routes: {'/LoginPage': (context) => const LoginPage()},
            );
          },
        );
      },
    );
  }
}
