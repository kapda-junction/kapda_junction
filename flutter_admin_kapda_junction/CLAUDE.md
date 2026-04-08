# Kapda Junction — Flutter Admin App

Mobile admin dashboard for Kapda Junction (men's fashion e-commerce).  
Mirrors the Angular web-admin at `web_admin_kapda_junction/`.

## Quick Start

```bash
cd flutter_admin_kapda_junction
flutter pub get
flutter run                          # pick emulator / device
```

## Backend

```
Base URL : https://kapda-junction-api.onrender.com/api
Auth     : Bearer <JWT>   (header added by DioInterceptor)
Role     : Only users with role = "admin" can access admin APIs
```

## Architecture — Clean + BLoC

```
lib/
├── core/
│   ├── constants/      api_constants.dart · app_colors.dart · app_typography.dart
│   ├── network/        api_client.dart (Dio + JWT interceptor + PrettyDioLogger)
│   ├── theme/          app_theme.dart (light + dark, system-driven)
│   ├── router/         app_router.dart (GoRouter, admin-guard)
│   ├── di/             injection.dart  (get_it singletons + factories)
│   ├── storage/        local_storage.dart (SharedPreferences wrapper)
│   └── utils/          price_formatter.dart · date_formatter.dart
├── data/
│   ├── models/         *_model.dart  (fromJson / toJson)
│   └── datasources/remote/  *_remote_datasource.dart
├── domain/
│   └── entities/       Pure Dart classes (Equatable)
└── presentation/
    ├── bloc/           *_bloc / *_event / *_state  (one BLoC per feature)
    ├── pages/          login · dashboard · products · categories
    │                   orders · banners · colors · sizes · settings
    └── widgets/        common/ (admin_shell, stat_card, confirm_dialog …)
```

## Features

| Page        | What admin can do                                              |
|-------------|----------------------------------------------------------------|
| Dashboard   | Stats: total products / orders / revenue / pending orders      |
| Products    | List · search · create · edit (with variant matrix) · delete   |
| Categories  | Tree view · create · edit · toggle active · delete             |
| Orders      | List · filter by status · update status · cancel + refund      |
| Banners     | List · create · edit (image upload + attach products) · delete |
| Colors      | Simple CRUD for product-variant color options                  |
| Sizes       | Simple CRUD for product-variant size options                   |
| Settings    | WhatsApp inquiry number                                        |

## Key Packages

| Package             | Purpose                        |
|---------------------|--------------------------------|
| flutter_bloc ^9.x   | BLoC state management          |
| go_router ^14.x     | Declarative routing            |
| dio ^5.x            | HTTP client                    |
| pretty_dio_logger   | Request/response logging       |
| get_it              | Service locator / DI           |
| shared_preferences  | Token + user persistence       |
| cached_network_image| Cloudinary image display       |
| image_picker        | Pick images for upload         |
| equatable           | Value equality for entities    |
| intl                | Date / currency formatting     |

## API Response Conventions

```
Products list   → { products: [...], total, page, pages }
Single product  → { product: {...} }  OR  {...}  (handle both)
Categories tree → [...]  (direct array, NOT wrapped)
Orders          → [...]  (direct array)
Auth login      → { user: {...}, token: "..." }
Upload image    → { url: "https://res.cloudinary.com/..." }
```

## Color Palette

Primary  `#0F172A`  (dark navy)  
Accent   `#F59E0B`  (amber)  
Success  `#059669`  (green)  
Error    `#DC2626`  (red)  
Dark mode driven by `ThemeMode.system`

## Common Patterns

### Admin guard — redirect non-admin to /login
```dart
// In GoRouter redirect:
if (!authBloc.state.isAuthenticated) return '/login';
if (authBloc.state.user?.role != 'admin') return '/login';
```

### Image upload flow
```dart
final file  = await ImagePicker().pickImage(source: ImageSource.gallery);
final url   = await uploadDs.uploadImage(file!.path, type: 'product');
// url is Cloudinary URL — store in product.images[]
```

### Variant matrix (color × size)
Product variants are stored as `List<ProductVariant>` where each variant
has `color`, `size`, and `stock`. The product form renders a grid where
every (color, size) pair gets a stock input field.

## Do NOT

- Never store admin credentials in code
- Never skip the admin role check
- Do not use `flutter pub add` — edit pubspec.yaml manually
- Do not create new files unless necessary — prefer editing existing ones
