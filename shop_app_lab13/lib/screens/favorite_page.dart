import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/global_provider.dart';
import '../provider/language_provider.dart';
import '../widgets/ProductView.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});
  static const Color accentPink = Color(0xFFea9ab2);

  @override
  Widget build(BuildContext context) {
    return Consumer2<GlobalProvider, LanguageProvider>(
      builder: (context, provider, languageProvider, child) {
        final favorites = provider.favorites;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              languageProvider.translate('favorites'),
              style: const TextStyle(color: Colors.black87),
            ),
            iconTheme: const IconThemeData(color: Colors.black54),
          ),
          body: SafeArea(
            child: favorites.isEmpty
                ? Center(
                    child: Text(
                      provider.isLoggedIn
                          ? languageProvider.translate('noFavoritesYet')
                          : languageProvider.translate('pleaseLoginToViewFavorites'),
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      itemCount: favorites.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.55,
                      ),
                      itemBuilder: (_, i) => ProductViewShop(favorites[i]),
                    ),
                  ),
          ),
        );
      },
    );
  }
}