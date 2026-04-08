class ApiConstants {
  ApiConstants._();
  static const String baseUrl = 'https://kapda-junction-api.onrender.com/api';

  // Auth
  static const String login    = '/auth/login';
  static const String me       = '/auth/me';

  // Products
  static const String products         = '/products';
  static const String featuredProducts = '/products/featured';

  // Categories
  static const String categories     = '/categories';
  static const String categoriesTree = '/categories/tree';

  // Colors & Sizes
  static const String colors = '/colors';
  static const String sizes  = '/sizes';

  // Orders
  static const String orders = '/orders';

  // Banners
  static const String banners       = '/banners';
  static const String activeBanners = '/banners/active';

  // Upload
  static const String uploadImage  = '/upload/image';
  static const String uploadImages = '/upload/images';
  static const String uploadBanner = '/upload/banner';

  // Coupons (admin CRUD + customer validate at /coupons/validate)
  static const String coupons = '/coupons';

  // Returns / exchanges (admin manages; customer uses same API base)
  static const String returns = '/returns';

  static const String reviews = '/reviews';

  // Settings
  static const String settings = '/settings';

  // Inventory
  static const String inventory = '/products/inventory';
  static String productStock(String id) => '/products/$id/stock';

  // Notifications (admin)
  static const String notificationAudience = '/admin/notifications/audience';
  static const String sendNotification = '/admin/notifications/send';
  static const String sendUserNotification = '/admin/notifications/send-user';
}

class AppConstants {
  AppConstants._();
  static const String tokenKey = 'admin_token';
  static const String userKey  = 'admin_user';
  static const int defaultPageSize = 20;
}
