import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:todo/ui/pages/home_page.dart';
import 'package:todo/ui/theme.dart';

import 'db/db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Initializing database...');
    await DBHelper.initDb();
    print('Database initialized successfully');
    
    print('Initializing GetStorage...');
    await GetStorage.init();
    print('GetStorage initialized successfully');
    
    // Force dark mode
    Get.changeThemeMode(ThemeMode.dark);
    
    runApp(const MyApp());
  } catch (e) {
    print('Error during app initialization: $e');
    // Still run the app, but it will handle the error state
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: Themes.dark, // Set both theme and darkTheme to dark
      darkTheme: Themes.dark,
      themeMode: ThemeMode.dark,
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
