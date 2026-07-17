import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts';
import { Button, Input } from '@/components/ui';
import { LoadingPage } from '@/components';
import { LoginCredentials } from '@/types';

export function LoginPage() {
  const navigate = useNavigate();
  const { login, isAuthenticated, isLoading } = useAuth();
  const [credentials, setCredentials] = useState<LoginCredentials>({
    Email: '',
    Password: '',
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  React.useEffect(() => {
    if (isAuthenticated) {
      navigate('/orders');
    }
  }, [isAuthenticated, navigate]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await login(credentials);
      navigate('/orders');
    } catch (error) {
      // Error is handled in the login function
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) return <LoadingPage />;

  return (
    <div className="flex min-h-screen items-center justify-center bg-background">
      <div className="w-full max-w-md space-y-8 rounded-lg border bg-card p-8 shadow-lg">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-primary">Pet Shop Admin</h1>
          <p className="mt-2 text-sm text-muted-foreground">Đăng nhập để tiếp tục</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <Input
            label="Email"
            type="email"
            placeholder="admin@example.com"
            value={credentials.Email}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setCredentials({ ...credentials, Email: e.target.value })}
            required
          />

          <Input
            label="Mật khẩu"
            type="password"
            placeholder="••••••••"
            value={credentials.Password}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setCredentials({ ...credentials, Password: e.target.value })}
            required
          />

          <Button
            type="submit"
            className="w-full"
            isLoading={isSubmitting}
          >
            Đăng nhập
          </Button>
        </form>

        <p className="text-center text-xs text-muted-foreground">
          Sử dụng tài khoản admin để đăng nhập
        </p>
      </div>
    </div>
  );
}
