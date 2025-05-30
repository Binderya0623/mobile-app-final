import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../provider/global_provider.dart';
import '../provider/language_provider.dart';
import '../widgets/ProductView.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  static const Color accentPink = Color(0xFFea9ab2);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late Future<List<ProductModel>> _dataFuture;
  bool _showPopularOnly = false;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchAndCache();
  }

  Future<List<ProductModel>> _fetchAndCache() async {
    final provider = Provider.of<GlobalProvider>(context, listen: false);
    if (provider.products.isEmpty) {
      await provider.fetchAllProducts();
    }
    return provider.products;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GlobalProvider, LanguageProvider>(
      builder: (context, provider, languageProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              languageProvider.translate('shop'),
              style: const TextStyle(color: Colors.black87),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF3D2B4B)),
            actions: [
              IconButton(
                icon: Icon(
                  _showPopularOnly ? Icons.star : Icons.star_border,
                  color: ShopPage.accentPink,
                ),
                tooltip: _showPopularOnly
                    ? languageProvider.translate('show_all')
                    : languageProvider.translate('show_popular_only'),
                onPressed: () {
                  setState(() {
                    _showPopularOnly = !_showPopularOnly;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  color: ShopPage.accentPink,
                ),
                tooltip: _isGridView
                    ? languageProvider.translate('list_view')
                    : languageProvider.translate('grid_view'),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),
          body: SafeArea(
            child: FutureBuilder<List<ProductModel>>(
              future: _dataFuture,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${languageProvider.translate('error')}: ${snapshot.error}',
                    ),
                  );
                }

                final products = snapshot.data!;
                final filteredProducts = _showPopularOnly
                    ? products.where((p) => (p.rating?.rate ?? 0) >= 4.0).toList()
                    : products;

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Text(languageProvider.translate('no_products_found')),
                  );
                }

                return _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.55,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (ctx, i) =>
                            ProductViewShop(filteredProducts[i]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ProductViewShop(filteredProducts[i]),
                        ),
                      );
              },
            ),
          ),
        );
      },
    );
  }
}