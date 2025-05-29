// lib/screens/product_detail.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../models/review_model.dart';
import '../provider/global_provider.dart';
import '../provider/language_provider.dart';

class ProductDetail extends StatefulWidget {
  final ProductModel product;

  const ProductDetail(this.product, {super.key});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  final _reviewTitleController = TextEditingController();
  final _reviewContentController = TextEditingController();
  double _rating = 5.0;

  @override
  void initState() {
    super.initState();
    // Fetch existing reviews for this product
    final provider = Provider.of<GlobalProvider>(context, listen: false);
    provider.fetchReviews(widget.product.id!);
  }

  @override
  void dispose() {
    _reviewTitleController.dispose();
    _reviewContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GlobalProvider, LanguageProvider>(
      builder: (context, provider, languageProvider, child) {
        final isInCart = provider.cartItems.contains(widget.product);
        final isFav = provider.favorites.contains(widget.product);
        final reviews = provider.currentProductReviews;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              languageProvider.translate('details'),
              style: const TextStyle(color: Colors.black87),
            ),
            iconTheme: const IconThemeData(color: Colors.black54),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? const Color(0xFF86385B) : Colors.grey,
                ),
                tooltip: languageProvider.translate(
                  isFav ? 'removeFromFavorites' : 'addToFavorites',
                ),
                onPressed: () {
                  try {
                    provider.toggleFavorite(widget.product);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${languageProvider.translate('error')}: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 240,
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.network(
                          widget.product.image!,
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  widget.product.title!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  widget.product.description!,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),

                // Price
                Text(
                  '\$${widget.product.price!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Reviews Display ───────────────────────────────────────────────
                Text(
                  languageProvider.translate('reviews'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (reviews.isEmpty)
                  Center(
                    child: Text(languageProvider.translate('no_reviews')),
                  )
                else
                  ...reviews.map((r) => _buildReviewTile(r, languageProvider)),

                const SizedBox(height: 24),

                // ─── Write a Review Section ────────────────────────────────────────
                Text(
                  languageProvider.translate('writeReview'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewTitleController,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('reviewTitle'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewContentController,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('reviewContent'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(languageProvider.translate('rating') + ':'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        value: _rating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _rating.toStringAsFixed(0),
                        onChanged: (val) {
                          setState(() {
                            _rating = val;
                          });
                        },
                      ),
                    ),
                    Text(_rating.toStringAsFixed(0)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.busy
                        ? null
                        : () async {
                            if (_reviewTitleController.text.isEmpty ||
                                _reviewContentController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    languageProvider.translate('fillAllFields'),
                                  ),
                                ),
                              );
                              return;
                            }
                            await provider.writeReview(
                              productId: widget.product.id!,
                              title: _reviewTitleController.text,
                              content: _reviewContentController.text,
                              rating: _rating,
                            );
                            _reviewTitleController.clear();
                            _reviewContentController.clear();
                            setState(() {
                              _rating = 5.0;
                            });
                            await provider.fetchReviews(widget.product.id!);
                          },
                    child: provider.busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(languageProvider.translate('submitReview')),
                  ),
                ),
                const SizedBox(height: 60), // give space for FAB
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              try {
                if (isInCart) {
                  provider.removeFromCart(widget.product);
                } else {
                  provider.addToCart(widget.product);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      languageProvider.translate(
                        isInCart ? 'removedFromCart' : 'addedToCart',
                      ),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${languageProvider.translate('error')}: ${e.toString()}',
                    ),
                  ),
                );
              }
            },
            backgroundColor: Colors.white,
            elevation: 0,
            icon: Icon(
              isInCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
              color: Colors.black87,
            ),
            label: Text(
              languageProvider.translate(
                isInCart ? 'removeFromCart' : 'addToCart',
              ),
              style: const TextStyle(color: Colors.black87),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildReviewTile(ReviewModel review, LanguageProvider lang) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${review.userName} (${review.rating.toStringAsFixed(0)}/5)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(review.title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(review.content),
            const SizedBox(height: 4),
            Text(
              DateTime.fromMillisecondsSinceEpoch(review.timestamp)
                  .toLocal()
                  .toString()
                  .split(' ')[0],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}