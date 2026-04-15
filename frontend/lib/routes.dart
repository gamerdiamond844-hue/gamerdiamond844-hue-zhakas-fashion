import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/place_order_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_products_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/admin_coupons_screen.dart';
import 'screens/admin_users_screen.dart';

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const productDetail = '/product';
  static const cart = '/cart';
  static const placeOrder = '/place-order';
  static const wishlist = '/wishlist';
  static const profile = '/profile';
  static const adminLogin = '/admin/login';
  static const adminDashboard = '/admin/dashboard';
  static const adminProducts = '/admin/products';
  static const adminOrders = '/admin/orders';
  static const adminCoupons = '/admin/coupons';
  static const adminUsers = '/admin/users';

  static final routes = <String, WidgetBuilder>{
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    signup: (_) => const SignupScreen(),
    home: (_) => const HomeScreen(),
    productDetail: (_) => const ProductDetailScreen(),
    cart: (_) => const CartScreen(),
    placeOrder: (_) => const PlaceOrderScreen(),
    wishlist: (_) => const WishlistScreen(),
    profile: (_) => const ProfileScreen(),
    adminLogin: (_) => const AdminLoginScreen(),
    adminDashboard: (_) => const AdminDashboardScreen(),
    adminProducts: (_) => const AdminProductsScreen(),
    adminOrders: (_) => const AdminOrdersScreen(),
    adminCoupons: (_) => const AdminCouponsScreen(),
    adminUsers: (_) => const AdminUsersScreen(),
  };
}
