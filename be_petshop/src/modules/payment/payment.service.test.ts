import { describe, expect, it } from 'vitest';
import { PaymentService } from './payment.service';

describe('PaymentService', () => {
  it('truncates the payment description to 25 characters', () => {
    const service = new PaymentService('demo-client', 'demo-api-key', 'demo-checksum');
    const description = (service as any).buildDescription(
      'Thanh toan PawMart demo cho buoi hoc'
    );

    expect(description).toBe('Thanh toan PawMart');
  });
});
