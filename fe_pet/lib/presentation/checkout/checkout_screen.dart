import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/url_helper.dart' as url_helper;
import '../../providers/cart_provider.dart';
import '../../data/models/cart_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController(text: '123 Pet Paradise Way, Hanoi');
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    final intVal = value.round();
    final chars = intVal.toString().split('').reversed.toList();
    final parts = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) parts.add('.');
      parts.add(chars[i]);
    }
    return '${parts.reversed.join()}đ';
  }

  String _getFlutterWebUrl() {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return 'pawmart://';
  }

  Future<void> _processCheckout(BuildContext context, CartProvider cartProvider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Tạo đơn hàng từ giỏ hàng
      final orderResponse = await ApiClient().dio.post(
        '/orders',
        data: {
          'ShippingAddress': _addressController.text.trim(),
        },
      );

      if (orderResponse.statusCode == 201 || orderResponse.statusCode == 200) {
        final orderData = orderResponse.data;
        final int orderId = orderData['OrderId'];

        // 2. Tạo link thanh toán PayOS
        final webUrl = _getFlutterWebUrl();
        final returnUrl = '$webUrl/#/orders';
        final cancelUrl = '$webUrl/#/cart';

        final paymentLinkResponse = await ApiClient().dio.post(
          '/payment/create-link',
          data: {
            'OrderId': orderId,
            'returnUrl': returnUrl,
            'cancelUrl': cancelUrl,
          },
        );

        if (paymentLinkResponse.statusCode == 200) {
          final checkoutUrl = paymentLinkResponse.data['checkoutUrl'] as String;

          // Làm sạch giỏ hàng ở client sau khi tạo đơn hàng thành công
          await cartProvider.fetchCart(silent: true);

          if (mounted) {
            if (kIsWeb) {
              // Redirect directly to the PayOS checkout URL on Web
              url_helper.launchBrowser(checkoutUrl);
            } else {
              // 3. Mở WebView thanh toán trên Mobile
              final bool? isPaid = await context.push<bool>(
                '/checkout/payment-webview',
                extra: {
                  'checkoutUrl': checkoutUrl,
                  'orderId': orderId,
                },
              );

              if (mounted) {
                if (isPaid == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thanh toán đơn hàng thành công! 🎉'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.go('/orders');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thanh toán đã bị hủy hoặc chưa hoàn tất.'),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.go('/orders');
                }
              }
            }
          }
        } else {
          throw Exception('Không thể tạo liên kết thanh toán PayOS');
        }
      } else {
        throw Exception('Không thể tạo đơn hàng');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thanh toán: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Lấy các sản phẩm được chọn từ giỏ hàng để hiển thị tóm tắt thanh toán
    final selectedItems = cartProvider.cart?.items
            .where((item) => cartProvider.isSelected(item.cartItemId))
            .toList() ??
        [];

    final totalAmount = cartProvider.selectedTotal;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Xác nhận thanh toán',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Đang khởi tạo giao dịch thanh toán...',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Tóm tắt sản phẩm
                        Card(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.border,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đơn hàng của bạn',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(height: 24),
                                ...selectedItems.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.product.name} x${item.quantity}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _formatCurrency(item.product.price * item.quantity),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tổng cộng',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(totalAmount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form nhập địa chỉ
                        Card(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.border,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thông tin giao hàng',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    labelText: 'Địa chỉ giao hàng',
                                    hintText: 'Nhập địa chỉ chi tiết của bạn',
                                    prefixIcon: const Icon(Icons.location_on_outlined),
                                    filled: true,
                                    fillColor: isDark
                                        ? AppColors.inputBackgroundDark
                                        : AppColors.inputBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vui lòng nhập địa chỉ giao hàng';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Thanh toán button dưới đáy
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: selectedItems.isEmpty
                              ? null
                              : () => _processCheckout(context, cartProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment_outlined),
                              SizedBox(width: 8),
                              Text(
                                'Thanh toán qua PayOS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
