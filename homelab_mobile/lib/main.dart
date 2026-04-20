import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelab_mobile/core/theme/app_theme.dart';
import 'package:homelab_mobile/features/gallery/presentation/screens/gallery_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar style — dark background, light icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      
    ),
  );

  // Preferred portrait orientations (allow landscape in viewer if needed)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    // ProviderScope is the Riverpod root — must wrap the entire app
    const ProviderScope(child: HomelabApp()),
  );
}

/// Root application widget.
class HomelabApp extends StatelessWidget {
  const HomelabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homelab Photos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Start directly on the gallery
      home: const GalleryScreen(),
    );
  }
}
