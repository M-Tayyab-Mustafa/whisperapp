import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../settings/app_settings.dart';
import 'calls_page.dart';
import 'chats_page.dart';
import 'map.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  AuthController authController = Get.put(AuthController());

  double iconSize = 22;
  int currentIndex = 0;

  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  List<Widget> pages = [
    const ChatsPage(),
    const CallsPage(),
    MapScreen(),
    AppSettingsPage(),
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    // Check the app's lifecycle state and update user status accordingly
    if (state == AppLifecycleState.paused) {
      await authController.updateUserStatus("${DateTime.now()}");
    } else if (state == AppLifecycleState.resumed) {
      await authController.updateUserStatus("online");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E7895);
    return Platform.isAndroid
        ? Scaffold(
            backgroundColor: Colors.grey.shade300,
            body: pages[currentIndex],
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.only(top: 0.8),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                selectedLabelStyle: GoogleFonts.lato(),
                unselectedLabelStyle: GoogleFonts.lato(),
                selectedItemColor: primaryColor,
                currentIndex: currentIndex,
                backgroundColor: Colors.white,
                elevation: 2,
                onTap: (index) {
                  changePage(index);
                },
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_outline_outlined),
                    label: "Chats",
                  ),
                  //Satuses chaning to Calls
                  BottomNavigationBarItem(
                    icon: Icon(Icons.call),
                    label: "Calls",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.location_on),
                    label: "Map",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: "Settings",
                  ),
                ],
              ),
            ),
          )
        : CupertinoTabScaffold(
            backgroundColor: AppTheme.scaffoldBackgroundColor,
            tabBar: CupertinoTabBar(
              items: [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.chat_bubble, size: iconSize),
                  label: "Chats",
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.phone, size: iconSize),
                  label: "Calls",
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person_2, size: iconSize),
                  label: "Map",
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.gear, size: iconSize),
                  label: "Settings",
                ),
              ],
              currentIndex: currentIndex,
              onTap: (index) {
                changePage(index);
              },
              activeColor: AppTheme.mainColor,
            ),
            tabBuilder: (context, index) {
              return CupertinoTabView(builder: (context) {
                return pages[index];
              });
            },
          );
  }
}
