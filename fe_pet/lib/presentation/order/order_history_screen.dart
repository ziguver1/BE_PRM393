import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/url_helper.dart' as url_helper;
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final int? initialTab;
  const OrderHistoryScreen({super.key, this.initialTab});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    final index = widget.initialTab ?? 0;
    _tabController = TabController(length: 5, vsync: this, initialIndex: index.clamp(0, 4));
    _fetchOrders(showLoading: true);
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchOrders(showLoading: false);
    });
  }

  Future<void> _fetchOrders({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ApiClient().dio.get('/orders');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _allOrders = response.data as List<dynamic>;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Không thể tải danh sách đơn hàng');
      }
    } catch (e) {
      if (mounted && showLoading) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
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

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PAID':
      case 'PROCESSING':
        return Colors.amber;
      case 'SHIPPING':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.purple;
      case 'RECEIVED':
        return Colors.green;
      case 'CANCELLED':
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'PROCESSING':
        return 'Đang chuẩn bị';
      case 'SHIPPING':
        return 'Đang giao hàng';
      case 'DELIVERED':
        return 'Đã giao hàng';
      case 'RECEIVED':
        return 'Đã nhận hàng';
      case 'PAID':
        return 'Đã thanh toán';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  List<dynamic> _getFilteredOrders(int tabIndex) {
    if (tabIndex == 0) return _allOrders; // Tất cả

    if (tabIndex == 1) {
      return _allOrders.where((o) => o['Status'].toUpperCase() == 'PENDING').toList();
    }
    if (tabIndex == 2) {
      return _allOrders.where((o) {
        final status = (o['Status'] as String).toUpperCase();
        return status == 'PAID' || status == 'SHIPPING' || status == 'DELIVERED';
      }).toList();
    }
    if (tabIndex == 3) {
      return _allOrders.where((o) => o['Status'].toUpperCase() == 'RECEIVED').toList();
    }
    if (tabIndex == 4) {
      return _allOrders.where((o) => o['Status'].toUpperCase() == 'CANCELLED').toList();
    }
    return [];
  }

  Future<void> _confirmReceived(int orderId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiClient().dio.patch(
        '/orders/$orderId/status',
        data: {'Status': 'RECEIVED'},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xác nhận đã nhận hàng thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchOrders(showLoading: false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xác nhận: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _payOrder(int orderId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang khởi tạo lại cổng thanh toán...')),
    );

    try {
      final webUrl = kIsWeb ? Uri.base.origin : 'pawmart://';
      final returnUrl = '$webUrl/#/orders';
      final cancelUrl = '$webUrl/#/cart';

      final response = await ApiClient().dio.post(
        '/payment/create-link',
        data: {
          'OrderId': orderId,
          'returnUrl': returnUrl,
          'cancelUrl': cancelUrl,
        },
      );

      if (response.statusCode == 200 && mounted) {
        final checkoutUrl = response.data['checkoutUrl'] as String;

        if (kIsWeb) {
          url_helper.launchBrowser(checkoutUrl);
        } else {
          final bool? isPaid = await context.push<bool>(
            '/checkout/payment-webview',
            extra: {
              'checkoutUrl': checkoutUrl,
              'orderId': orderId,
            },
          );

          if (mounted && isPaid == true) {
            _fetchOrders(showLoading: false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khởi tạo thanh toán: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allCount = _allOrders.length;
    final pendingCount = _allOrders.where((o) => o['Status'].toUpperCase() == 'PENDING').length;
    final deliveryCount = _allOrders.where((o) => ['PAID', 'SHIPPING', 'DELIVERED'].contains(o['Status'].toUpperCase())).length;
    final receivedCount = _allOrders.where((o) => o['Status'].toUpperCase() == 'RECEIVED').length;
    final cancelledCount = _allOrders.where((o) => o['Status'].toUpperCase() == 'CANCELLED').length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            context.canPop()
                ? Icons.arrow_back_ios_new_rounded
                : Icons.home_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Đơn hàng của tôi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Tất cả ($allCount)'),
                Tab(text: 'Chờ thanh toán ($pendingCount)'),
                Tab(text: 'Đang giao ($deliveryCount)'),
                Tab(text: 'Đã nhận ($receivedCount)'),
                Tab(text: 'Đã hủy ($cancelledCount)'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(5, (index) => _buildOrderList(index, isDark)),
      ),
    );
  }

  Widget _buildOrderList(int tabIndex, bool isDark) {
    if (_isLoading && _allOrders.isEmpty) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchOrders(showLoading: true),
              child: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    final filteredOrders = _getFilteredOrders(tabIndex);

    if (filteredOrders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Không có đơn hàng nào!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn chưa có đơn hàng nào ở trạng thái này.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Khám phá sản phẩm'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchOrders(showLoading: false),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return _buildOrderCard(order, isDark);
        },
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, bool isDark) {
    final status = order['Status'] as String;
    final details = order['OrderDetails'] as List<dynamic>? ?? [];
    final orderCode = order['OrderCode'];

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
        // Refresh on returning
        _fetchOrders(showLoading: false);
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
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
              // Order ID & Status Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn hàng #${order['OrderId']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (orderCode != null)
                          Text(
                            'Mã PayOS: $orderCode',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Order Items Summary
              if (details.isEmpty)
                const Text(
                  'Không có thông tin sản phẩm',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                )
              else
                ...details.map((detail) {
                  final product = detail['Product'];
                  final productName = product != null ? product['Name'] as String : 'Sản phẩm đã xóa';
                  final unitPrice = detail['UnitPrice'] as num;
                  final quantity = detail['Quantity'] as int;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$productName x$quantity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          _formatCurrency((unitPrice * quantity).toDouble()),
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }),
              const Divider(height: 24),

              // Time & Total Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thời gian đặt:',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        Text(
                          _formatDate(order['CreatedAt'] as String),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Tổng số tiền:',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      Text(
                        _formatCurrency(order['TotalAmount'] as double),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Notice & Interactive Actions on the Card
              if (status.toUpperCase() == 'DELIVERED') ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đơn hàng đã được giao.',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmReceived(order['OrderId'] as int),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Xác nhận đã nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ] else if (status.toUpperCase() == 'SHIPPING') ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đơn hàng đang trên đường giao đến bạn.',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (status.toUpperCase() == 'PENDING') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () => _payOrder(order['OrderId'] as int),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Thanh toán ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            height: 180,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }
}