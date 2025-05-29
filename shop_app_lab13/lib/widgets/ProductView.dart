// lib/widgets/ProductView.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../provider/global_provider.dart';
import '../screens/product_detail.dart';

class ProductViewShop extends StatelessWidget {
  final ProductModel data;
  const ProductViewShop(this.data, {super.key});

  void _onTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetail(data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalProvider>(
      builder: (context, provider, child) {
        final isFavorite = data.isFavorite;
        return InkWell(
          onTap: () => _onTap(context),
          child: Card(
            elevation: 4.0,
            margin: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 150.0,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(data.image!),
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            '\$${data.price!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Color.fromARGB(255, 78, 50, 68),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          if (data.rating?.rate != null)
                            Row(
                              children: [
                                StarRating(rating: data.rating!.rate!),
                                const SizedBox(width: 6),
                                Text(
                                  '(${data.rating!.count ?? 0})',
                                  style: const TextStyle(
                                      fontSize: 12.0, color: Colors.grey),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // favorite button (exact same look)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? const Color(0xFF86385B)
                            : const Color(0xFFB3B1B1),
                      ),
                      onPressed: () {
                        try {
                          provider.toggleFavorite(data);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                    ),
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

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = const Color(0xFFFFB700),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final icon = index < rating.floor()
            ? Icons.star
            : (index < rating ? Icons.star_half : Icons.star_border);
        return Icon(icon, size: size, color: color);
      }),
    );
  }
}