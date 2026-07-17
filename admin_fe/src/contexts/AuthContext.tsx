import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { authService } from '@/services';
import { storage } from '@/utils/storage';
import { AdminInfo, LoginCredentials } from '@/types';
import { toast } from 'sonner';

interface AuthContextType {
  admin: AdminInfo | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => Promise<void>;
  refreshAdmin: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [admin, setAdmin] = useState<AdminInfo | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Check for existing admin session on mount
    const token = storage.get<string>('ACCESS_TOKEN');
    const adminInfo = storage.get<AdminInfo>('ADMIN_INFO');
    
    if (token && adminInfo) {
      setAdmin(adminInfo);
    }
    setIsLoading(false);
  }, []);

  const login = async (credentials: LoginCredentials) => {
    try {
      const response = await authService.login(credentials);
      
      const adminInfo: AdminInfo = {
        id: response.user.UserId,
        email: response.user.Email,
        name: response.user.FullName,
        role: response.user.Role,
        avatar: response.user.Avatar,
      };
      
      storage.set('ACCESS_TOKEN', response.accessToken);
      storage.set('REFRESH_TOKEN', response.refreshToken);
      storage.set('ADMIN_INFO', adminInfo);
      
      setAdmin(adminInfo);
      toast.success('Đăng nhập thành công');
    } catch (error) {
      toast.error('Đăng nhập thất bại');
      throw error;
    }
  };

  const logout = async () => {
    try {
      await authService.logout();
    } catch (error) {
      // Ignore logout errors
    } finally {
      storage.clear();
      setAdmin(null);
      toast.success('Đã đăng xuất');
    }
  };

  const refreshAdmin = () => {
    const adminInfo = storage.get<AdminInfo>('ADMIN_INFO');
    setAdmin(adminInfo);
  };

  return (
    <AuthContext.Provider
      value={{
        admin,
        isAuthenticated: !!admin,
        isLoading,
        login,
        logout,
        refreshAdmin,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
