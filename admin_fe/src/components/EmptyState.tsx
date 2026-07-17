import React from 'react';
import { Package, Users, ShoppingCart, MessageSquare } from 'lucide-react';
import { cn } from '@/utils/cn';

interface EmptyStateProps {
  icon?: 'package' | 'users' | 'shopping' | 'message' | React.ReactNode;
  title: string;
  description?: string;
  action?: React.ReactNode;
  className?: string;
}

const icons = {
  package: Package,
  users: Users,
  shopping: ShoppingCart,
  message: MessageSquare,
};

export function EmptyState({
  icon = 'package',
  title,
  description,
  action,
  className,
}: EmptyStateProps) {
  const Icon = typeof icon === 'string' ? icons[icon as keyof typeof icons] : null;

  return (
    <div className={cn('flex flex-col items-center justify-center p-8 text-center', className)}>
      <div className="mb-4 rounded-full bg-muted p-4">
        {typeof icon === 'string' && Icon ? (
          <Icon className="h-8 w-8 text-muted-foreground" />
        ) : (
          icon
        )}
      </div>
      <h3 className="mb-2 text-lg font-semibold text-foreground">{title}</h3>
      {description && (
        <p className="mb-4 max-w-sm text-sm text-muted-foreground">{description}</p>
      )}
      {action && <div className="mt-2">{action}</div>}
    </div>
  );
}
