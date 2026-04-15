import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final data = await ApiService.get('/products/', token: auth.token);
      final list = data is List ? data : (data['data'] as List? ?? []);
      setState(() {
        _products = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.delete('/products/$id', token: auth.token);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  void _showProductForm({Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(product: product, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.gold,
        onPressed: () => _showProductForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.green,
              child: _products.isEmpty
                  ? const Center(child: Text('No products yet', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _products.length,
                      itemBuilder: (_, i) {
                        final p = _products[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: AppTheme.glassCard(radius: 16),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: p.images.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: p.images.first, width: 56, height: 56, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(width: 56, height: 56, color: AppTheme.background))
                                  : Container(width: 56, height: 56, color: AppTheme.background, child: const Icon(Icons.image_not_supported, color: AppTheme.textMuted)),
                            ),
                            title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('₹${(p.price - p.discount).toStringAsFixed(0)} · Stock: ${p.stock}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                Row(
                                  children: [
                                    if (p.isTrending) _badge('Trending', Colors.orange),
                                    if (p.isFeatured) _badge('Featured', AppTheme.green),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.green, size: 20), onPressed: () => _showProductForm(product: p)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _delete(p.id)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _ProductFormSheet extends StatefulWidget {
  final Product? product;
  final VoidCallback onSaved;
  const _ProductFormSheet({this.product, required this.onSaved});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(text: widget.product?.title ?? '');
  late final TextEditingController _desc = TextEditingController(text: widget.product?.description ?? '');
  late final TextEditingController _price = TextEditingController(text: widget.product?.price.toString() ?? '');
  late final TextEditingController _discount = TextEditingController(text: widget.product?.discount.toString() ?? '0');
  late final TextEditingController _stock = TextEditingController(text: widget.product?.stock.toString() ?? '0');
  late final TextEditingController _catId = TextEditingController(text: widget.product != null ? '1' : '1');
  late bool _trending = widget.product?.isTrending ?? false;
  late bool _featured = widget.product?.isFeatured ?? false;
  List<String> _images = List.from(widget.product?.images ?? []);
  bool _saving = false;
  bool _uploading = false;

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final bytes = await file.readAsBytes();
      final result = await ApiService.uploadFile('/products/upload-media', bytes, file.name, token: auth.token);
      setState(() => _images.add(result['url'] as String));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final body = {
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'price': double.tryParse(_price.text) ?? 0,
      'discount': double.tryParse(_discount.text) ?? 0,
      'stock': int.tryParse(_stock.text) ?? 0,
      'category_id': int.tryParse(_catId.text) ?? 1,
      'images': _images,
      'sizes': ['S', 'M', 'L', 'XL'],
      'colors': ['Green', 'Gold', 'White'],
      'is_trending': _trending,
      'is_featured': _featured,
    };
    try {
      if (widget.product != null) {
        await ApiService.put('/products/${widget.product!.id}', body: body, token: auth.token);
      } else {
        await ApiService.post('/products/', body: body, token: auth.token);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.product != null ? 'Edit Product' : 'Add Product', style: const TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.green)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Product Title'), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 14),
                      TextFormField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true)),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: TextFormField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _discount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount (₹)'))),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: TextFormField(controller: _stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _catId, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Category ID'))),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: SwitchListTile(value: _trending, onChanged: (v) => setState(() => _trending = v), title: const Text('Trending'), activeColor: AppTheme.green, contentPadding: EdgeInsets.zero)),
                        Expanded(child: SwitchListTile(value: _featured, onChanged: (v) => setState(() => _featured = v), title: const Text('Featured'), activeColor: AppTheme.green, contentPadding: EdgeInsets.zero)),
                      ]),
                      const SizedBox(height: 14),
                      const Text('Product Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 90,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._images.map((url) => Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)),
                                ),
                                Positioned(top: 0, right: 10, child: GestureDetector(
                                  onTap: () => setState(() => _images.remove(url)),
                                  child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)),
                                )),
                              ],
                            )),
                            GestureDetector(
                              onTap: _uploading ? null : _uploadImage,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDDD8CC), style: BorderStyle.solid)),
                                child: _uploading
                                    ? const Center(child: CircularProgressIndicator(color: AppTheme.green, strokeWidth: 2))
                                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, color: AppTheme.green), Text('Add', style: TextStyle(fontSize: 11, color: AppTheme.textMuted))]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(widget.product != null ? 'Update Product' : 'Add Product'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
