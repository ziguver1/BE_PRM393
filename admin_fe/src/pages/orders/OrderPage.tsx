import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Search } from 'lucide-react';
import { toast } from 'sonner';
import { orderService } from '@/services';
import { ORDER_STATUS, ORDER_STATUS_LABELS, ORDER_STATUS_COLORS } from '@/constants';
import { formatCurrency, formatDateTime } from '@/utils/format';
import { Button, Dialog, Select, Badge } from '@/components/ui';
import { LoadingPage, EmptyState, ErrorPage } from '@/components';
import { Order, OrderFilters } from '@/types';

export function OrderPage() {
  const queryClient = useQueryClient();
  const [filters, setFilters] = useState<OrderFilters>({});
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [newStatus, setNewStatus] = useState<Order['Status']>('PENDING');

  const { data: orders = [], isLoading, error, refetch } = useQuery({
    queryKey: ['orders', filters],
    queryFn: () => orderService.getOrders(filters, { page: 1, limit: 50 }),
  });

  const updateStatusMutation = useMutation({
    // Send data to backend as { Status: status } matching the UpdateOrderStatus interface
    mutationFn: ({ id, status }: { id: string; status: Order['Status'] }) =>
      orderService.updateOrderStatus(id, { Status: status }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      setIsDialogOpen(false);
      toast.success('Cập nhật trạng thái thành công');
    },
    onError: () => {
      toast.error('Cập nhật trạng thái thất bại');
    },
  });

  const handleUpdateStatus = () => {
    if (selectedOrder && newStatus) {
      updateStatusMutation.mutate({ id: selectedOrder.OrderId.toString(), status: newStatus });
    }
  };

  const openStatusDialog = (order: Order) => {
    setSelectedOrder(order);
    setNewStatus(order.Status);
    setIsDialogOpen(true);
  };

  // Perform client-side search since backend does not support order filters directly
  const filteredOrders = orders.filter((order) => {
    // Status Filter
    if (filters.status && order.Status !== filters.status) {
      return false;
    }

    // Search Filter
    if (filters.search) {
      const query = filters.search.toLowerCase();
      const orderIdMatch = order.OrderId.toString().includes(query);
      const customerMatch = order.User?.FullName?.toLowerCase().includes(query);
      const emailMatch = order.User?.Email?.toLowerCase().includes(query);
      const addressMatch = order.ShippingAddress?.toLowerCase().includes(query);
      
      if (!orderIdMatch && !customerMatch && !emailMatch && !addressMatch) {
        return false;
      }
    }

    // Date Filters
    if (filters.startDate) {
      const orderDate = new Date(order.CreatedAt);
      const startDate = new Date(filters.startDate);
      if (orderDate < startDate) return false;
    }
    if (filters.endDate) {
      const orderDate = new Date(order.CreatedAt);
      const endDate = new Date(filters.endDate);
      // Include the whole end day
      endDate.setHours(23, 59, 59, 999);
      if (orderDate > endDate) return false;
    }

    return true;
  });

  if (isLoading) return <LoadingPage />;
  if (error) return <ErrorPage onRetry={() => refetch()} />;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-foreground">Quản lý đơn hàng</h1>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-4 rounded-lg border bg-card p-4">
        <div className="flex-1 min-w-[200px]">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Tìm kiếm theo mã đơn, khách hàng, email, địa chỉ..."
              className="w-full rounded-lg border border-input bg-background pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
              value={filters.search || ''}
              onChange={(e) => setFilters({ ...filters, search: e.target.value })}
            />
          </div>
        </div>

        <Select
          label="Trạng thái đơn"
          options={[
            { value: '', label: 'Tất cả' },
            ...Object.entries(ORDER_STATUS).map(([key, value]) => ({
              value: value,
              label: ORDER_STATUS_LABELS[key as keyof typeof ORDER_STATUS],
            })),
          ]}
          value={filters.status || ''}
          onChange={(e) => setFilters({ ...filters, status: e.target.value as Order['Status'] || undefined })}
        />

        <input
          type="date"
          className="rounded-lg border border-input bg-background px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
          value={filters.startDate || ''}
          onChange={(e) => setFilters({ ...filters, startDate: e.target.value })}
        />
        <input
          type="date"
          className="rounded-lg border border-input bg-background px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
          value={filters.endDate || ''}
          onChange={(e) => setFilters({ ...filters, endDate: e.target.value })}
        />
      </div>

      {/* Orders Table */}
      <div className="rounded-lg border bg-card">
        {filteredOrders.length === 0 ? (
          <EmptyState
            icon="shopping"
            title="Không có đơn hàng nào"
            description="Thử thay đổi bộ lọc hoặc tìm kiếm với từ khóa khác"
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="border-b bg-muted/50">
                <tr>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Mã đơn</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Khách hàng</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Email</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Địa chỉ giao hàng</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Trạng thái</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Ngày tạo</th>
                  <th className="px-4 py-3 text-right text-sm font-semibold text-foreground">Tổng tiền</th>
                  <th className="px-4 py-3 text-center text-sm font-semibold text-foreground">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredOrders.map((order) => (
                  <tr key={order.OrderId} className="border-b hover:bg-muted/50">
                    <td className="px-4 py-3 text-sm font-medium text-foreground">#{order.OrderId}</td>
                    <td className="px-4 py-3 text-sm text-foreground">{order.User?.FullName || 'N/A'}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">{order.User?.Email || 'N/A'}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground max-w-[200px] truncate">
                      {order.ShippingAddress}
                    </td>
                    <td className="px-4 py-3">
                      <Badge className={ORDER_STATUS_COLORS[order.Status]}>
                        {ORDER_STATUS_LABELS[order.Status]}
                      </Badge>
                    </td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">{formatDateTime(order.CreatedAt)}</td>
                    <td className="px-4 py-3 text-right text-sm font-medium text-foreground">
                      {formatCurrency(order.TotalAmount)}
                    </td>
                    <td className="px-4 py-3 text-center">
                      {order.Status === 'PAID' ? (
                        <Button
                          variant="primary"
                          size="sm"
                          onClick={() => {
                            setSelectedOrder(order);
                            updateStatusMutation.mutate({ id: order.OrderId.toString(), status: 'SHIPPING' });
                          }}
                          isLoading={updateStatusMutation.isPending && selectedOrder?.OrderId === order.OrderId}
                        >
                          Bắt đầu giao hàng
                        </Button>
                      ) : (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => openStatusDialog(order)}
                          disabled={order.Status === 'DELIVERED' || order.Status === 'CANCELLED' || order.Status === 'RECEIVED'}
                        >
                          Cập nhật
                        </Button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Update Status Dialog */}
      <Dialog isOpen={isDialogOpen} onClose={() => setIsDialogOpen(false)} title="Cập nhật trạng thái đơn hàng">
        <div className="space-y-4">
          <div>
            <label className="mb-2 block text-sm font-medium text-foreground">Trạng thái mới</label>
            <Select
              options={Object.entries(ORDER_STATUS).map(([key, value]) => ({
                value: value,
                label: ORDER_STATUS_LABELS[key as keyof typeof ORDER_STATUS],
              }))}
              value={newStatus}
              onChange={(e) => setNewStatus(e.target.value as Order['Status'])}
            />
          </div>
          <div className="flex justify-end gap-3">
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              Hủy
            </Button>
            <Button
              onClick={handleUpdateStatus}
              isLoading={updateStatusMutation.isPending}
            >
              Cập nhật
            </Button>
          </div>
        </div>
      </Dialog>
    </div>
  );
}
