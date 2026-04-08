class ApiConstants {
  ApiConstants._();

  // Change to your backend URL
  static const String baseUrl = 'https://kapda-junction-api.onrender.com/api';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String addresses = '/auth/addresses';

  static const String products = '/products';
  static const String featuredProducts = '/products/featured';
  static const String landingProducts = '/products/landing';
  static const String aiSearch = '/products/ai-search';

  static const String categories = '/categories';
  static const String categoriesTree = '/categories/tree';

  static const String cart = '/cart';

  static const String orders = '/orders';
  static const String createPayment = '/orders/create-payment';
  static const String verifyPayment = '/orders/verify-payment';
  static const String couponValidate = '/coupons/validate';
  static const String returns = '/returns';

  static const String activeBanners = '/banners/active';

  static const String colors = '/colors';
  static const String sizes = '/sizes';

  static const String settings = '/settings';

  /// Public: GET /reviews/product/:id — approved only. POST /reviews (auth) create.
  static const String reviews = '/reviews';
  static const String upload = '/upload';
  static const String health = '/health';

  // Wishlist
  static const String wishlist    = '/wishlist';
  static const String wishlistIds = '/wishlist/ids';

  // Activity
  static const String activitySearch  = '/activity/search';
  static const String activityView    = '/activity/view';
  static const String recentSearches  = '/activity/searches';
  static const String recentViews     = '/activity/views';

  // Search suggestions
  static const String suggestions = '/products/suggestions';

  // FCM
  static const String fcmToken = '/auth/fcm-token';
  static const String deviceRegisterToken = '/devices/register-token';

  // Public share page (OG + redirect)
  static const String shareBaseUrl = 'https://kapda-junction-api.onrender.com/share/product';

  static String shareProductUrl(String productId) => '$shareBaseUrl/$productId';
}

class AppConstants {
  AppConstants._();

  static const String razorpayKeyId = 'rzp_test_SSz3vblfNvzVbY';
  static const String currencyCode = 'INR';
  static const String currencySymbol = '₹';

  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
  static const String cartItemsKey = 'cart_items';

  static const int defaultPageSize = 20;
  static const int maxCartQuantity = 10;
}
