import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/global_provider.dart';
import '../provider/language_provider.dart';
import 'bags_page.dart';
import 'shop_page.dart';
import 'favorite_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static List<Widget> pages = [
    const ShopPage(),
    BagsPage(),
    const FavoritePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<GlobalProvider, LanguageProvider>(
      builder: (context, provider, language, child) {
        return Scaffold(
          body: pages[provider.currentIdx],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: provider.currentIdx,
            onTap: provider.changeCurrentIdx,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.shop),
                label: language.translate('shopping'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.shopping_basket),
                label: language.translate('bag'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.favorite),
                label: language.translate('favorite'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: language.translate('profile'),
              ),
            ],
          ),
        );
      },
    );
  }
}