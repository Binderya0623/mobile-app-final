import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/global_provider.dart';
import '../provider/language_provider.dart';

class BagsPage extends StatelessWidget {
  BagsPage({super.key});

  static const Color accentColor = Color(0xFF92434F);

  @override
  Widget build(BuildContext context) {
    return Consumer2<GlobalProvider, LanguageProvider>(
      builder: (context, provider, languageProvider, child) {
        final total = provider.totalPrice;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              languageProvider.translate('my_bag'),
              style: const TextStyle(color: Colors.black87),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: accentColor),
            actions: [
              if (provider.cartItems.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep,
                    color: accentColor,
                  ),
                  tooltip: languageProvider.translate('clear_cart'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        content: Text(
                          languageProvider.translate('confirm_clear_cart'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              languageProvider.translate('cancel'),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.clearCart();
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              languageProvider.translate('clear'),
                              style: const TextStyle(color: accentColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: provider.cartItems.isEmpty
              ? Center(
                  child: Text(
                    languageProvider.translate('cart_empty'),
                    style: const TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: provider.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = provider.cartItems[index];
                    return Card(
                      color: Colors.white,
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(item.image!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${item.price!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              color: Colors.grey,
                                              icon: const Icon(Icons.remove),
                                              onPressed: () {
                                                provider.decreaseQuantity(item);
                                              },
                                              constraints: const BoxConstraints(
                                                  minWidth: 20, minHeight: 20),
                                              padding: EdgeInsets.zero,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8),
                                              child: Text(
                                                '${provider.getQuantity(item)}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              color: Colors.grey,
                                              icon: const Icon(Icons.add),
                                              onPressed: () {
                                                provider.increaseQuantity(item);
                                              },
                                              constraints: const BoxConstraints(
                                                  minWidth: 20, minHeight: 20),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: accentColor,
                                        ),
                                        onPressed: () {
                                          provider.removeFromCart(item);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageProvider.translate('total_price'),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: provider.cartItems.isEmpty ? null : () {
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    languageProvider.translate('buy_all'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}