import { Card, CardTitle, CardContent } from '@/components/ui';
import { LayoutDashboard } from 'lucide-react';

export function DashboardPage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-foreground">Dashboard</h1>
      </div>

      <Card className="border-dashed border-2 py-12">
        <CardContent className="flex flex-col items-center justify-center space-y-4">
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
            <LayoutDashboard className="h-8 w-8 text-primary" />
          </div>
          <div className="text-center space-y-2">
            <CardTitle className="text-xl">Tính năng thống kê (Dashboard)</CardTitle>
            <p className="text-sm text-muted-foreground max-w-sm">
              Backend chưa hỗ trợ. Các API thống kê báo cáo doanh thu, sản phẩm bán chạy, và tăng trưởng người dùng chưa được triển khai ở backend.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
