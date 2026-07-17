import React from 'react';
import { FileQuestion } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { useNavigate } from 'react-router-dom';

export function NotFound() {
  const navigate = useNavigate();

  return (
    <div className="flex h-screen flex-col items-center justify-center p-8 text-center">
      <div className="mb-4 rounded-full bg-muted p-4">
        <FileQuestion className="h-16 w-16 text-muted-foreground" />
      </div>
      <h1 className="mb-2 text-4xl font-bold text-foreground">404</h1>
      <h2 className="mb-4 text-xl font-semibold text-foreground">Trang không tìm thấy</h2>
      <p className="mb-8 max-w-sm text-muted-foreground">
        Trang bạn đang tìm kiếm không tồn tại hoặc đã bị di chuyển.
      </p>
      <Button onClick={() => navigate('/dashboard')}>Về trang chủ</Button>
    </div>
  );
}
