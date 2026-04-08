# Kapda Junction — Flutter Mobile App

## What this is
Flutter e-commerce mobile app for Kapda Junction (men's fashion). Mirrors the Angular web app at `../web_kapda_junction`, backed by the Node.js/Express API at `../backend_kapda_junction`.

## Tech Stack
- **Flutter** 3.38.7 / Dart 3.10.7
- **State:** flutter_bloc (BLoC pattern)
- **Navigation:** go_router (shell routes + deep links)
- **HTTP:** dio with JWT interceptor
- **Storage:** shared_preferences (token, user, cart)
- **DI:** get_it singleton registry
- **Payment:** razorpay_flutter
- **Images:** cached_network_image

## Architecture — Clean Architecture
```
lib/
├── core/
│   ├── constants/      # AppColors, AppTypography, ApiConstants, AppConstants
│   ├── di/             # GetIt injection.dart — register all deps here
│   ├── error/          # Failure classes
│   ├── network/        # ApiClient (Dio + JWT interceptor)
│   ├── router/         # app_router.dart (GoRouter + auth redirect)
│   ├── storage/        # LocalStorage (SharedPreferences wrapper)
│   ├── theme/          # AppTheme.light
│   └── utils/          # PriceFormatter (₹ INR)
├── data/
│   ├── datasources/remote/   # *_remote_datasource.dart — raw API calls
│   ├── models/               # *_model.dart — JSON ↔ Entity mappers
│   └── repositories/         # *_repository_impl.dart
├── domain/
│   ├── entities/       # Product, Category, CartItem, Order, User, AppBanner
│   ├── repositories/   # Abstract interfaces
│   └── usecases/       # (add use cases here as needed)
└── presentation/
    ├── bloc/           # auth/, cart/, home/, products/, orders/
    ├── pages/          # splash, auth, home, products, search, cart, checkout, orders, profile
    └── widgets/        # common/main_shell.dart, product/product_card.dart
```

## Backend API
- **Dev:** `http://localhost:3000/api`
- **Prod:** update `ApiConstants.baseUrl`
- **Auth:** `Authorization: Bearer <JWT>` (7-day expiry)
- **Payment:** Razorpay — update `AppConstants.razorpayKeyId`

## Key Data Notes
- Products have **variants** (color + size), each with its own stock
- Cart items carry: product + selectedColor + selectedSize + quantity
- `Order` clashes with dartz's `Order` → use `import 'package:dartz/dartz.dart' hide Order;`
- Payment flow: `POST /orders/create-payment` → open Razorpay → webhook updates order on backend

## Running
```bash
cd flutter_kapda_junction
flutter pub get
flutter run
```

## Before first run — update these
1. `lib/core/constants/api_constants.dart` → `baseUrl` to your backend
2. `lib/core/constants/api_constants.dart` → `razorpayKeyId` to your Razorpay test key

## Brand Colors
- Primary: `#0F172A` (dark navy)
- Accent: `#F59E0B` (amber) — buttons, CTAs
- Success: `#059669`, Error: `#DC2626`
- Background: `#F8FAFC`
