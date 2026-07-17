import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'sonner';
import { AuthProvider, ThemeProvider, QueryProvider } from '@/providers';
import { ProtectedRoute } from '@/components';
import { DashboardLayout } from '@/layouts';
import { LoginPage, DashboardPage, OrderPage, UserPage, ProductPage, ChatPage } from '@/pages';
import { NotFound } from '@/components';

function App() {
  return (
    <React.StrictMode>
      <BrowserRouter>
        <ThemeProvider>
          <QueryProvider>
            <AuthProvider>
              <Toaster position="top-right" richColors />
              <Routes>
                <Route path="/login" element={<LoginPage />} />
                <Route
                  path="/"
                  element={
                    <ProtectedRoute>
                      <DashboardLayout />
                    </ProtectedRoute>
                  }
                >
                  <Route index element={<Navigate to="/dashboard" replace />} />
                  <Route path="dashboard" element={<DashboardPage />} />
                  <Route path="orders" element={<OrderPage />} />
                  <Route path="products" element={<ProductPage />} />
                  <Route path="users" element={<UserPage />} />
                  <Route path="chat" element={<ChatPage />} />
                </Route>
                <Route path="*" element={<NotFound />} />
              </Routes>
            </AuthProvider>
          </QueryProvider>
        </ThemeProvider>
      </BrowserRouter>
    </React.StrictMode>
  );
}

export default App;
