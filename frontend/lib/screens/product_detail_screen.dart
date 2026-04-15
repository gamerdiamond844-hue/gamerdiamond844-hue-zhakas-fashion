import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _imageIndex = 0;
  String? _selectedSize;
  String? _selectedColor;
  final PageController _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as Product? ??
        Product(id: 1, title: 'Royal Silk Saree', price: 12999, discount: 1200, stock: 12,
            images: ['https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80'],
            sizes: ['S', 'M', 'L', 'XL'], colors: ['Green', 'Gold', 'White'], isTrending: true,
            description: 'Handcrafted luxury saree with premium embroidery and rich gold accents.');

    final cart = Provider.of<CartProvider>(context, listen: false);
    final wishlist = Provider.of<WishlistProvider>(context);
    final auth = Provider.of<AuthService>(context, listen: false);
    final discountedPrice = product.price - product.discount;
    final discountPct = product.discount > 0 ? ((product.discount / product.price) * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: AppTheme.green,
            actions: [
              IconButton(
                icon: Icon(
                  wishlist.isWishlisted(product.id) ? Icons.favorite : Icons.favorite_border,
                  color: wishlist.isWishlisted(product.id) ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  if (auth.token != null) wishlist.toggle(product.id, auth.token!);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: product.images.length,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: product.images[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppTheme.greenDark),
                      errorWidget: (_, __, ___) => Container(color: AppTheme.background, child: const Icon(Icons.image_not_supported, size: 60, color: AppTheme.textMuted)),
                    ),
                  ),
                  if (product.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(product.images.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _imageIndex == i ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _imageIndex == i ? AppTheme.gold : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ),
                    ),
                  if (discountPct > 0)
                    Positioned(
                      top: 60,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                        child: Text('-$discountPct% OFF', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(product.title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        ),
                        if (product.isTrending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.gold)),
                            child: const Text('Trending', style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('₹${discountedPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.green)),
                        const SizedBox(width: 10),
                        if (product.discount > 0)
                          Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, color: AppTheme.textMuted, decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 10),
                        if (product.discount > 0)
                          Text('Save ₹${product.discount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text('${product.stock} in stock', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 28),
                    if (product.description != null) ...[
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                      const SizedBox(height: 8),
                      Text(product.description!, style: const TextStyle(color: AppTheme.textMuted, height: 1.6)),
                      const SizedBox(height: 20),
                    ],
                    if (product.sizes.isNotEmpty) ...[
                      const Text('Select Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: product.sizes.map((s) => GestureDetector(
                          onTap: () => setState(() => _selectedSize = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedSize == s ? AppTheme.green : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _selectedSize == s ? AppTheme.green : const Color(0xFFDDD8CC), width: 1.5),
                            ),
                            child: Text(s, style: TextStyle(color: _selectedSize == s ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w600)),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (product.colors.isNotEmpty) ...[
                      const Text('Select Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: product.colors.map((c) => GestureDetector(
                          onTap: () => setState(() => _selectedColor = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedColor == c ? AppTheme.gold.withOpacity(0.15) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _selectedColor == c ? AppTheme.gold : const Color(0xFFDDD8CC), width: 1.5),
                            ),
                            child: Text(c, style: TextStyle(color: _selectedColor == c ? AppTheme.gold : AppTheme.textDark, fontWeight: FontWeight.w600)),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 28),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              cart.addItem(product, size: _selectedSize, color: _selectedColor);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: const Text('Added to cart!'),
                                backgroundColor: AppTheme.green,
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(label: 'View Cart', textColor: AppTheme.gold, onPressed: () => Navigator.pushNamed(context, Routes.cart)),
                              ));
                            },
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Add to Cart'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.green, width: 1.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: Icon(
                              wishlist.isWishlisted(product.id) ? Icons.favorite : Icons.favorite_border,
                              color: wishlist.isWishlisted(product.id) ? Colors.red : AppTheme.green,
                            ),
                            onPressed: () {
                              if (auth.token != null) wishlist.toggle(product.id, auth.token!);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, Routes.cart),
                      icon: const Icon(Icons.flash_on, color: AppTheme.gold),
                      label: const Text('Buy Now', style: TextStyle(color: AppTheme.green)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.gold, width: 1.5)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
