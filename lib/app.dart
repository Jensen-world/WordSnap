import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/colors.dart';
import 'core/theme/radius.dart';
import 'core/router/app_router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Preload the logo image, then dismiss splash after a brief delay.
    // Using the same MaterialApp (via builder overlay) avoids the
    // separate-MaterialApp asset loading issue on some Android OEMs.
    Future.microtask(() async {
      await precacheImage(const AssetImage('assets/logo/splash-logo.png'), context);
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: '见词 WordSnap',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.signalBlue,
            primary: AppColors.signalBlue,
            surface: AppColors.canvasWhite,
          ),
          scaffoldBackgroundColor: AppColors.canvasWhite,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            backgroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            color: AppColors.cardFill,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.card,
              side: const BorderSide(color: AppColors.border, width: 1),
            ),
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.subtleFill,
            border: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        routerConfig: appRouter,
        builder: (context, child) {
          if (_showSplash) {
            return Stack(
              children: [
                if (child != null) child,
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.signalBlue,
                    child: Center(
                      child: Image(
                        image: const AssetImage('assets/logo/splash-logo.png'),
                        width: 120,
                        height: 120,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return child!;
        },
      ),
    );
  }
}
