import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/wishlist_provider.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = Provider.of<WishlistProvider>(context);
    final products = Provider.of<ProductProvider>(context);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    final wishlisted = products.products.where((p) => wishlist.isWishlisted(p.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: wishlisted.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: AppTheme.textMuted.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('No items in wishlist', style: TextStyle(fontSize: 18, color: AppTheme.textMuted)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, Routes.home),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
                    child: const Text('Explore Collections'),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: wishlisted.length,
              itemBuilder: (_, i) {
                final p = wishlisted[i];
                final discounted = p.price - p.discount;
                return Container(
                  decoration: AppTheme.glassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, Routes.productDetail, arguments: p),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: CachedNetworkImage(
                                imageUrl: p.images.isNotEmpty ? p.images.first : '',
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(height: 150, color: AppTheme.background, child: const Icon(Icons.image_not_supported, color: AppTheme.textMuted)),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => wishlist.toggle(p.id, auth.token!),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                                child: const Icon(Icons.favorite, color: Colors.red, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('₹${discounted.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                cart.addItem(p);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Added to cart!'),
                                  backgroundColor: AppTheme.green,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 1),
                                ));
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.green, AppTheme.greenLight]), borderRadius: BorderRadius.circular(10)),
                                child: const Center(child: Text('Add to Cart', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
