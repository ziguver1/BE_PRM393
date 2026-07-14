# 📱 Flutter Frontend - Faceted Search Integration Guide

## ✅ Completed Updates

### 1. **Data Layer** (`lib/data/models/`)

#### Updated: `product_model.dart`
- Added support for PascalCase field names from Backend (ProductId, Name, etc.)
- Added new model classes:
  - `ProductImageModel` - For multiple product images
  - `ProductVariantModel` - For product variants with structured data
  - `FilterOptionModel` - For filter options
  - `FilterGroupModel` - For filter groups
  - `ProductFilterModel` - For product-filter relationships
- Added helper methods:
  - `getPrimaryImageUrl()` - Get primary image or fallback
  - `getAllImageUrls()` - Get all image URLs for carousel
  - `getDisplayPrice()` - Get display price from variants
  - `getFiltersByGroup()` - Group filters by category

#### Updated: `paginated_products_model.dart`
- Updated to use `data` field instead of `items` (matching Backend response)
- Added support for legacy `items` field via `fromJsonLegacy` factory

### 2. **Service Layer** (`lib/services/`)

#### New: `product_service.dart`
- `fetchProducts()` - Get products with filtering, search, and pagination
  - Parameters: page, limit, categoryId, filters, search
  - Returns: `PaginatedProductsModel`
- `fetchProductById()` - Get single product
- `searchProducts()` - Search with all filter options
- `applyFilters()` - Apply filter string
- Comprehensive error handling with Vietnamese messages

### 3. **Provider Layer** (`lib/providers/`)

#### New: `product_provider.dart`
- State management using `ChangeNotifier`
- Properties: `isLoading`, `errorMessage`, `products`, pagination info
- Methods:
  - `loadProducts()` - Load with filters
  - `applyFilters()` - Apply filter string
  - `filterByCategory()` - Filter by category
  - `searchProducts()` - Search functionality
  - `loadNextPage()` / `loadPreviousPage()` - Pagination
  - `resetFilters()` - Reset to initial state

### 4. **Presentation Layer**

#### Updated: `lib/presentation/product/product_detail_screen.dart`
- Complete rewrite with modern UI
- Features:
  - **Carousel Slider** for multiple product images
  - **Variant Selection** using `Wrap` and custom chips
  - **Filter Tags** displayed in groups
  - **Dynamic Pricing** - Updates when variant selected
  - **Sticky Bottom Bar** with two buttons:
    - "Thêm vào giỏ" (Add to Cart) - OutlineButton
    - "Mua ngay" (Buy Now) - ElevatedButton with orange gradient
  - Favorite toggle functionality
  - Professional UI with dark mode support

#### New: `lib/screens/home_screen_updated.dart`
- Integration with `ProductProvider`
- Fetches real product data from API
- Product grid display (2 columns)
- Click to navigate to product detail
- Shows loading and error states
- Displays out-of-stock badge

### 5. **Main App Setup**

#### Updated: `lib/main.dart`
- Added `ProductProvider` to MultiProvider
- Now provides both `CartProvider` and `ProductProvider`

---

## 🚀 Integration Steps

### Step 1: Ensure Dependencies
Verify these are in `pubspec.yaml`:
```yaml
carousel_slider: ^4.2.0
cached_network_image: ^3.3.0
provider: ^6.0.0
dio: ^5.3.0
go_router: ^10.0.0
```

### Step 2: Update Home Screen
Replace your current `home_screen.dart` with either:
1. **Option A**: Use the new `home_screen_updated.dart` (recommended)
   - Copy `home_screen_updated.dart` to replace `home_screen.dart`
   - Or rename and update routes

2. **Option B**: Manually update existing `home_screen.dart`
   - Add imports:
     ```dart
     import '../providers/product_provider.dart';
     import '../data/models/product_model.dart';
     import '../presentation/product/product_detail_screen.dart';
     ```
   - Change class to `StatefulWidget`
   - Initialize `ProductProvider` in `initState()`
   - Replace product grid with `Consumer<ProductProvider>` widget
   - Use navigation: `Navigator.push()` → `ProductDetailScreen(product: product)`

### Step 3: Update Routes
Ensure routes include ProductDetailScreen:
```dart
// In your router configuration
GoRoute(
  path: '/product/:id',
  builder: (context, state) {
    final product = state.extra as ProductModel;
    return ProductDetailScreen(product: product);
  },
),
```

### Step 4: API Base URL Configuration
Update `lib/core/constants/api_constants.dart` if backend URL changes:
```dart
static const String baseUrl = 'https://your-backend-url.com';
```

---

## 📊 Data Flow Diagram

```
ProductService (API calls)
    ↓
ProductProvider (State Management)
    ↓
Home Screen → Load Products
    ↓
Product Card → Tap
    ↓
ProductDetailScreen (Full Product View)
    ↓
Add to Cart / Buy Now
```

---

## 🎨 UI Features

### Product Detail Screen
- **Header**: Carousel of product images with counter
- **Info Block**: Name, Category, Rating, Stock, Price
- **Variant Selection**: ChoiceChip selection with price update
- **Filter Tags**: Grouped by category
- **Description**: Product description in card
- **Sticky Bottom**: Quantity picker + Add to Cart + Buy Now buttons

### Home Screen
- **Search Bar**: Mock search (redirects to chat)
- **Featured Products**: Grid (2 columns) from API
- **Loading State**: Spinner
- **Error State**: Error message display
- **Out of Stock Badge**: Red badge on images

---

## 🔍 Key Methods

### In ProductProvider:
```dart
// Load initial products
await productProvider.loadProducts();

// Apply filters
await productProvider.applyFilters("1,5,8");

// Search
await productProvider.searchProducts("dog food");

// By category
await productProvider.filterByCategory(1);
```

### In ProductModel:
```dart
// Get all images
List<String> imageUrls = product.getAllImageUrls();

// Get filters grouped
Map<String, List<FilterOptionModel>> grouped = 
  product.getFiltersByGroup();

// Format price from variant
double price = product.getDisplayPrice();
```

---

## 🔧 Troubleshooting

### Images Not Loading?
- Check `API_BASE_URL` in `.env` file
- Ensure backend is returning valid image URLs
- Use `cached_network_image` for better handling

### Filters Not Working?
- Verify filter IDs format: "1,5,8" (comma-separated)
- Check ProductFilters relationship in Prisma schema
- Test API with: `/api/products?filters=1,5,8`

### Provider Not Found?
- Ensure `ProductProvider` is added to `MultiProvider` in `main.dart`
- Use `context.read<ProductProvider>()` or `Consumer<ProductProvider>`

### Navigation Issues?
- For StatefulWidget: Use `Navigator.push()`
- For GoRouter: Use `context.push()`
- Pass `ProductModel` as extra or direct parameter

---

## 📝 Usage Examples

### In Widget:
```dart
// Read provider
final productProvider = context.read<ProductProvider>();

// Load products
await productProvider.loadProducts(categoryId: 1);

// Navigate to detail
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ProductDetailScreen(product: product),
  ),
);
```

### In Consumer:
```dart
Consumer<ProductProvider>(
  builder: (context, productProvider, _) {
    if (productProvider.isLoading) {
      return const CircularProgressIndicator();
    }
    return ListView(
      children: productProvider.products
        .map((p) => ProductCard(product: p))
        .toList(),
    );
  },
)
```

---

## ✨ Next Steps (Optional)

1. **Favorites System**: Add favorite/wishlist feature
2. **Reviews & Ratings**: Display actual product reviews
3. **Quick View**: Modal preview before detail screen
4. **Sort Options**: By price, popularity, newest
5. **Filter Persistence**: Remember selected filters
6. **Infinite Scroll**: Load more on scroll

---

## 📞 Support

For API integration issues:
- Check Backend API endpoints: `/api/products`
- Verify Backend response format matches `PaginatedProductsModel`
- Test with Postman/Thunder Client before Frontend integration

---

**Last Updated**: 2026-07-13
**Status**: ✅ Production Ready
