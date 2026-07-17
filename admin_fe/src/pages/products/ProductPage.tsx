import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Search, Plus, Edit, Trash2, Upload } from 'lucide-react';
import { toast } from 'sonner';
import { productService, categoryService } from '@/services';
import { apiClient } from '@/api/axios';
import { PRODUCT_STATUS_LABELS, PRODUCT_STATUS_COLORS } from '@/constants';
import { formatCurrency, formatDate } from '@/utils/format';
import { Button, Dialog, Badge } from '@/components/ui';
import { LoadingPage, EmptyState, ErrorPage } from '@/components';
import { Product, ProductFilters, CreateProduct, UpdateProduct } from '@/types';

export function ProductPage() {
  const queryClient = useQueryClient();
  const [filters, setFilters] = useState<ProductFilters>({});
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [dialogType, setDialogType] = useState<'create' | 'edit' | 'delete' | 'stock'>('create');
  
  // Use capitalized keys for bindings to match backend model
  const [formData, setFormData] = useState<Partial<CreateProduct>>({});
  const [uploadingImage, setUploadingImage] = useState(false);

  const { data: productsData, isLoading, error, refetch } = useQuery({
    queryKey: ['products', filters],
    queryFn: () => productService.getProducts(filters, { page: 1, limit: 50 }),
  });

  // Query categories to populate dropdown selectors
  const { data: categories = [] } = useQuery({
    queryKey: ['categories'],
    queryFn: () => categoryService.getCategories(),
  });

  // Handle both possible pagination property keys from backend (items vs data)
  const products = productsData?.items || productsData?.data || [];

  const createMutation = useMutation({
    mutationFn: (data: CreateProduct) => productService.createProduct(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      setIsDialogOpen(false);
      setFormData({});
      toast.success('Tạo sản phẩm thành công');
    },
    onError: () => {
      toast.error('Tạo sản phẩm thất bại');
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateProduct }) =>
      productService.updateProduct(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      setIsDialogOpen(false);
      setSelectedProduct(null);
      setFormData({});
      toast.success('Cập nhật sản phẩm thành công');
    },
    onError: () => {
      toast.error('Cập nhật sản phẩm thất bại');
    },
  });

  const updateStockMutation = useMutation({
    mutationFn: ({ id, Stock }: { id: string; Stock: number }) =>
      productService.updateProduct(id, { Stock }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      setIsDialogOpen(false);
      setSelectedProduct(null);
      setFormData({});
      toast.success('Cập nhật tồn kho thành công');
    },
    onError: () => {
      toast.error('Cập nhật tồn kho thất bại');
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => productService.deleteProduct(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      setIsDialogOpen(false);
      setSelectedProduct(null);
      toast.success('Xóa sản phẩm thành công');
    },
    onError: () => {
      toast.error('Xóa sản phẩm thất bại');
    },
  });

  const openCreateDialog = () => {
    setDialogType('create');
    setFormData({
      Name: '',
      Price: 0,
      CategoryId: categories[0]?.CategoryId || 0,
      Description: '',
      ImageUrl: '',
      Stock: 0,
    });
    setIsDialogOpen(true);
  };

  const openEditDialog = (product: Product) => {
    setSelectedProduct(product);
    setDialogType('edit');
    setFormData({
      Name: product.Name,
      Price: product.Price,
      CategoryId: product.CategoryId,
      Description: product.Description,
      ImageUrl: product.ImageUrl,
      Stock: product.Stock,
    });
    setIsDialogOpen(true);
  };

  const openDeleteDialog = (product: Product) => {
    setSelectedProduct(product);
    setDialogType('delete');
    setIsDialogOpen(true);
  };

  const openStockDialog = (product: Product) => {
    setSelectedProduct(product);
    setDialogType('stock');
    setFormData({ Stock: product.Stock });
    setIsDialogOpen(true);
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadingImage(true);
    const uploadData = new FormData();
    uploadData.append('file', file);

    try {
      const response = await apiClient.post<{ url: string; imageUrl: string }>('/upload', uploadData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      // Backend returns url / imageUrl
      const uploadedUrl = response.data.imageUrl || response.data.url;
      setFormData((prev) => ({ ...prev, ImageUrl: uploadedUrl }));
      toast.success('Tải ảnh lên thành công');
    } catch (error) {
      toast.error('Tải ảnh lên thất bại');
    } finally {
      setUploadingImage(false);
    }
  };

  const handleSubmit = () => {
    if (dialogType === 'create') {
      createMutation.mutate(formData as CreateProduct);
    } else if (dialogType === 'edit' && selectedProduct) {
      updateMutation.mutate({
        id: selectedProduct.ProductId.toString(),
        data: formData as UpdateProduct,
      });
    } else if (dialogType === 'delete' && selectedProduct) {
      deleteMutation.mutate(selectedProduct.ProductId.toString());
    } else if (dialogType === 'stock' && selectedProduct) {
      updateStockMutation.mutate({
        id: selectedProduct.ProductId.toString(),
        Stock: formData.Stock || 0,
      });
    }
  };

  if (isLoading) return <LoadingPage />;
  if (error) return <ErrorPage onRetry={() => refetch()} />;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-foreground">Quản lý sản phẩm</h1>
        <Button onClick={openCreateDialog}>
          <Plus className="mr-2 h-4 w-4" />
          Thêm sản phẩm
        </Button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-4 rounded-lg border bg-card p-4">
        <div className="flex-1 min-w-[200px]">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Tìm kiếm theo tên..."
              className="w-full rounded-lg border border-input bg-background pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
              value={filters.search || ''}
              onChange={(e) => setFilters({ ...filters, search: e.target.value })}
            />
          </div>
        </div>

        <select
          className="rounded-lg border border-input bg-background px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
          value={filters.category || ''}
          onChange={(e) => setFilters({ ...filters, category: e.target.value || undefined })}
        >
          <option value="">Tất cả danh mục</option>
          {categories.map((cat) => (
            <option key={cat.CategoryId} value={cat.CategoryId.toString()}>
              {cat.Name}
            </option>
          ))}
        </select>
      </div>

      {/* Products Table */}
      <div className="rounded-lg border bg-card">
        {products.length === 0 ? (
          <EmptyState
            icon="package"
            title="Không có sản phẩm nào"
            description="Thử thay đổi bộ lọc hoặc tạo sản phẩm mới"
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="border-b bg-muted/50">
                <tr>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Ảnh</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Tên</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Danh mục</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Giá</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Tồn kho</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Trạng thái</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-foreground">Ngày tạo</th>
                  <th className="px-4 py-3 text-center text-sm font-semibold text-foreground">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {products.map((product) => {
                  const productStatus = product.Stock > 0 ? 'ACTIVE' : 'OUT_OF_STOCK';
                  return (
                    <tr key={product.ProductId} className="border-b hover:bg-muted/50">
                      <td className="px-4 py-3">
                        {product.ImageUrl ? (
                          <img
                            src={product.ImageUrl}
                            alt={product.Name}
                            className="h-10 w-10 rounded-lg object-cover"
                          />
                        ) : (
                          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-muted">
                            <span className="text-xs text-muted-foreground">No img</span>
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-3 text-sm font-medium text-foreground">{product.Name}</td>
                      <td className="px-4 py-3 text-sm text-muted-foreground">
                        {product.Category?.Name || 'N/A'}
                      </td>
                      <td className="px-4 py-3 text-sm font-medium text-foreground">
                        {formatCurrency(product.Price)}
                      </td>
                      <td className="px-4 py-3 text-sm text-muted-foreground">{product.Stock}</td>
                      <td className="px-4 py-3">
                        <Badge className={PRODUCT_STATUS_COLORS[productStatus]}>
                          {PRODUCT_STATUS_LABELS[productStatus]}
                        </Badge>
                      </td>
                      <td className="px-4 py-3 text-sm text-muted-foreground">{formatDate(product.CreatedAt)}</td>
                      <td className="px-4 py-3 text-center">
                        <div className="flex justify-center gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => openEditDialog(product)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => openStockDialog(product)}
                          >
                            📦
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => openDeleteDialog(product)}
                          >
                            <Trash2 className="h-4 w-4 text-destructive" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Product Dialog */}
      <Dialog
        isOpen={isDialogOpen}
        onClose={() => setIsDialogOpen(false)}
        title={
          dialogType === 'create'
            ? 'Thêm sản phẩm mới'
            : dialogType === 'edit'
            ? 'Cập nhật sản phẩm'
            : dialogType === 'delete'
            ? 'Xóa sản phẩm'
            : 'Cập nhật tồn kho'
        }
      >
        <div className="space-y-4">
          {dialogType === 'delete' ? (
            <div>
              <p className="text-sm text-muted-foreground">
                Bạn có chắc chắn muốn xóa sản phẩm "{selectedProduct?.Name}"? Hành động này không thể hoàn tác.
              </p>
              <div className="mt-4 flex justify-end gap-3">
                <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
                  Hủy
                </Button>
                <Button
                  variant="destructive"
                  onClick={handleSubmit}
                  isLoading={deleteMutation.isPending}
                >
                  Xóa
                </Button>
              </div>
            </div>
          ) : dialogType === 'stock' ? (
            <div>
              <label className="mb-2 block text-sm font-medium text-foreground">Số lượng tồn kho</label>
              <input
                type="number"
                className="w-full rounded-lg border border-input bg-background px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
                value={formData.Stock || 0}
                onChange={(e) => setFormData({ ...formData, Stock: parseInt(e.target.value) || 0 })}
              />
              <div className="mt-4 flex justify-end gap-3">
                <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
                  Hủy
                </Button>
                <Button
                  onClick={handleSubmit}
                  isLoading={updateStockMutation.isPending}
                >
                  Cập nhật
                </Button>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <div>
                <label className="mb-2 block text-sm font-medium text-foreground">Tên sản phẩm</label>
                <input
                  type="text"
                  className="w-full rounded-lg border border-input bg-background px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
                  value={formData.Name || ''}
                  onChange={(e) => setFormData({ ...formData, Name: e.target.value })}
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="mb-2 block text-sm font-medium text-foreground">Giá</label>
                  <input
                    type="number"
                    className="w-full rounded-lg border border-input bg-background px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
                    value={formData.Price || 0}
                    onChange={(e) => setFormData({ ...formData, Price: parseFloat(e.target.value) || 0 })}
                  />
                </div>
                <div>
                  <label className="mb-2 block text-sm font-medium text-foreground">Tồn kho</label>
                  <input
                    type="number"
                    className="w-full rounded-lg border border-input bg-background px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
                    value={formData.Stock || 0}
                    disabled={dialogType === 'edit'} // Lock stock updates to specific 📦 button if desired, or allow editing
                    onChange={(e) => setFormData({ ...formData, Stock: parseInt(e.target.value) || 0 })}
                  />
                </div>
              </div>
              <div>
                <label className="mb-2 block text-sm font-medium text-foreground">Danh mục</label>
                <select
                  className="w-full rounded-lg border border-input bg-background px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
                  value={formData.CategoryId || ''}
                  onChange={(e) => setFormData({ ...formData, CategoryId: parseInt(e.target.value) || 0 })}
                >
                  {categories.map((cat) => (
                    <option key={cat.CategoryId} value={cat.CategoryId}>
                      {cat.Name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-2 block text-sm font-medium text-foreground">Mô tả</label>
                <textarea
                  className="w-full rounded-lg border border-input bg-background px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring min-h-[100px]"
                  value={formData.Description || ''}
                  onChange={(e) => setFormData({ ...formData, Description: e.target.value })}
                />
              </div>
              <div>
                <label className="mb-2 block text-sm font-medium text-foreground">Hình ảnh sản phẩm</label>
                <div className="flex gap-2 items-center">
                  <input
                    type="text"
                    placeholder="URL hình ảnh..."
                    className="flex-1 rounded-lg border border-input bg-background px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
                    value={formData.ImageUrl || ''}
                    onChange={(e) => setFormData({ ...formData, ImageUrl: e.target.value })}
                  />
                  <div className="relative">
                    <input
                      type="file"
                      id="upload-image-input"
                      className="hidden"
                      accept="image/*"
                      onChange={handleImageUpload}
                      disabled={uploadingImage}
                    />
                    <label
                      htmlFor="upload-image-input"
                      className={`flex items-center gap-1 rounded-lg border px-4 py-2 text-sm font-medium cursor-pointer hover:bg-muted transition-colors ${
                        uploadingImage ? 'opacity-50 pointer-events-none' : ''
                      }`}
                    >
                      <Upload className="h-4 w-4" />
                      Tải lên
                    </label>
                  </div>
                </div>
                {formData.ImageUrl && (
                  <div className="mt-2 relative inline-block">
                    <img
                      src={formData.ImageUrl}
                      alt="Xem trước"
                      className="h-20 w-20 rounded-lg object-cover border"
                    />
                  </div>
                )}
              </div>
              <div className="flex justify-end gap-3">
                <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
                  Hủy
                </Button>
                <Button
                  onClick={handleSubmit}
                  isLoading={createMutation.isPending || updateMutation.isPending}
                  disabled={uploadingImage}
                >
                  {dialogType === 'create' ? 'Tạo' : 'Cập nhật'}
                </Button>
              </div>
            </div>
          )}
        </div>
      </Dialog>
    </div>
  );
}
