import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/wishlist_provider.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = auth.token;
    await Provider.of<ProductProvider>(context, listen: false).fetchProducts(token: token);
    if (token != null) {
      await Provider.of<WishlistProvider>(context, listen: false).fetchWishlist(token);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.green,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(cart),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildBanner()),
            SliverToBoxAdapter(child: _buildCategoryChips()),
            _buildSection('🔥 Trending Deals', filter: 'trending'),
            _buildSection('🆕 New Launches', filter: 'featured'),
            _buildSection('👗 Saree Collections', filter: 'saree'),
            _buildSection('💃 Lehenga Collections', filter: 'lehenga'),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.gold,
        onPressed: () => Navigator.pushNamed(context, Routes.cart),
        child: Stack(
          children: [
            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 28),
            if (cart.itemCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(CartProvider cart) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: AppTheme.green,
      title: const Text('ZHAKAS FASHION', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border, color: AppTheme.gold),
          onPressed: () => Navigator.pushNamed(context, Routes.wishlist),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, Routes.profile),
        ),
      ],
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search sarees, lehengas...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.green),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: AppTheme.green, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [AppTheme.greenDark, AppTheme.greenLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: AppTheme.green.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CachedNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, __) => Container(color: AppTheme.greenDark),
              errorWidget: (_, __, ___) => Container(color: AppTheme.greenDark),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [AppTheme.greenDark.withOpacity(0.8), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(20)),
                  child: const Text('NEW SEASON', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 6),
                const Text('Royal Luxury\nCollections 2025', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Georgia', height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Sarees', 'Lehengas', 'Trending', 'New'];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => FilterChip(
          label: Text(categories[i]),
          selected: _selectedCategory == i,
          onSelected: (_) => setState(() => _selectedCategory = i),
          selectedColor: AppTheme.green,
          labelStyle: TextStyle(color: _selectedCategory == i ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDDD8CC)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _shimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _productCard(Product product) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final wishlist = Provider.of<WishlistProvider>(context);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final discountedPrice = product.price - product.discount;
    final discountPct = product.discount > 0 ? ((product.discount / product.price) * 100).round() : 0;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, Routes.productDetail, arguments: product),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        decoration: AppTheme.glassCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: product.images.isNotEmpty ? product.images.first : 'https://via.placeholder.com/300x200',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(height: 160, color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => Container(height: 160, color: AppTheme.background, child: const Icon(Icons.image_not_supported, color: AppTheme.textMuted)),
                  ),
                ),
                if (discountPct > 0)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                      child: Text('-$discountPct%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (auth.token != null) wishlist.toggle(product.id, auth.token!);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                      child: Icon(
                        wishlist.isWishlisted(product.id) ? Icons.favorite : Icons.favorite_border,
                        color: wishlist.isWishlisted(product.id) ? Colors.red : AppTheme.textMuted,
                        size: 18,
                      ),
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
                  Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('₹${discountedPrice.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 14)),
                      if (product.discount > 0) ...[
                        const SizedBox(width: 4),
                        Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      cart.addItem(product);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${product.title} added to cart'),
                        backgroundColor: AppTheme.green,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.green)),
          GestureDetector(
            onTap: () {},
            child: const Text('See All', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _sectionList(List<Product> products) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        itemBuilder: (_, i) => _productCard(products[i]),
      ),
    );
  }

  Widget _shimmerSection() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (_, __) => _shimmerCard(),
      ),
    );
  }

  Widget _searchResults(List<Product> all) {
    final results = all.where((p) => p.title.toLowerCase().contains(_searchQuery)).toList();
    if (results.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('No products found', style: TextStyle(color: AppTheme.textMuted))),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((_, i) => _productCard(results[i]), childCount: results.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 12, mainAxisSpacing: 12),
      ),
    );
  }

  Widget _buildSectionWidget(String title, List<Product> products, bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        loading ? _shimmerSection() : _sectionList(products),
      ],
    );
  }

  List<Product> _filterByCategory(List<Product> all) {
    switch (_selectedCategory) {
      case 1: return all.where((p) => p.title.toLowerCase().contains('saree')).toList();
      case 2: return all.where((p) => p.title.toLowerCase().contains('lehenga')).toList();
      case 3: return all.where((p) => p.isTrending).toList();
      case 4: return all.where((p) => p.isFeatured).toList();
      default: return all;
    }
  }

  List<Product> _filterProducts(List<Product> all, String filter) {
    final base = _filterByCategory(all);
    switch (filter) {
      case 'trending': return base.where((p) => p.isTrending).toList().isEmpty ? base.take(4).toList() : base.where((p) => p.isTrending).toList();
      case 'featured': return base.where((p) => p.isFeatured).toList().isEmpty ? base.take(4).toList() : base.where((p) => p.isFeatured).toList();
      case 'saree': return base.where((p) => p.title.toLowerCase().contains('saree')).toList();
      case 'lehenga': return base.where((p) => p.title.toLowerCase().contains('lehenga')).toList();
      default: return base;
    }
  }

  SliverToBoxAdapter _buildSection(String title, {required String filter}) {
    return SliverToBoxAdapter(
      child: Consumer<ProductProvider>(
        builder: (_, pp, __) {
          if (_searchQuery.isNotEmpty) return const SizedBox.shrink();
          final filtered = _filterProducts(pp.products, filter);
          return _buildSectionWidget(title, filtered, pp.loading);
        },
      ),
    );
  }
}
