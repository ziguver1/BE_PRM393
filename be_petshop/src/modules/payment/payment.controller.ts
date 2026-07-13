import { NextRequest, NextResponse } from 'next/server';
import { PaymentService } from './payment.service';
import { handleError } from '@/middleware/error.middleware';

const paymentService = new PaymentService();

export class PaymentController {
  async createLink(req: NextRequest) {
    try {
      const body = await req.json();
      const orderId = Number(body.OrderId);
      const returnUrl = body.returnUrl ? String(body.returnUrl) : undefined;
      const cancelUrl = body.cancelUrl ? String(body.cancelUrl) : undefined;

      if (!orderId) {
        return NextResponse.json({ error: 'OrderId is required.' }, { status: 400 });
      }

      const result = await paymentService.createPaymentLink(orderId, returnUrl, cancelUrl);
      return NextResponse.json(result, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async handleSuccess(req: NextRequest) {
    try {
      const { searchParams } = new URL(req.url);
      const orderCode = searchParams.get('orderCode') || '';
      const paymentId = searchParams.get('id') || '';

      const html = `
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Thanh toán thành công - PawMart</title>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: 'Outfit', sans-serif;
      background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      color: #333;
    }
    .card {
      background: white;
      padding: 40px;
      border-radius: 24px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.1);
      text-align: center;
      max-width: 450px;
      width: 90%;
      box-sizing: border-box;
      animation: slideUp 0.6s cubic-bezier(0.16, 1, 0.3, 1);
    }
    @keyframes slideUp {
      from { transform: translateY(30px); opacity: 0; }
      to { transform: translateY(0); opacity: 1; }
    }
    .icon-container {
      width: 80px;
      height: 80px;
      background: #e6fcf5;
      color: #099268;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
      font-size: 40px;
      font-weight: bold;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0% { box-shadow: 0 0 0 0 rgba(9, 146, 104, 0.4); }
      70% { box-shadow: 0 0 0 15px rgba(9, 146, 104, 0); }
      100% { box-shadow: 0 0 0 0 rgba(9, 146, 104, 0); }
    }
    h1 {
      font-size: 26px;
      font-weight: 800;
      margin: 0 0 12px;
      color: #099268;
    }
    p {
      font-size: 16px;
      color: #666;
      line-height: 1.5;
      margin: 0 0 30px;
    }
    .details {
      background: #f8f9fa;
      padding: 16px;
      border-radius: 12px;
      margin-bottom: 30px;
      text-align: left;
      font-size: 14px;
    }
    .detail-item {
      display: flex;
      justify-content: space-between;
      margin-bottom: 8px;
    }
    .detail-item:last-child {
      margin-bottom: 0;
    }
    .label {
      color: #888;
    }
    .value {
      font-weight: 600;
      color: #495057;
    }
    .btn {
      display: inline-block;
      background: #ff8e53;
      color: white;
      text-decoration: none;
      padding: 14px 28px;
      border-radius: 12px;
      font-weight: 600;
      font-size: 16px;
      transition: all 0.3s ease;
      border: none;
      cursor: pointer;
      box-shadow: 0 4px 15px rgba(255, 142, 83, 0.3);
      width: 100%;
    }
    .btn:hover {
      background: #f07635;
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(255, 142, 83, 0.4);
    }
    .btn:active {
      transform: translateY(0);
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon-container">✓</div>
    <h1>Thanh toán thành công!</h1>
    <p>Cảm ơn bạn đã mua sắm tại PawMart. Đơn hàng của bạn đã được thanh toán và đang được xử lý.</p>
    
    <div class="details">
      <div class="detail-item">
        <span class="label">Mã đơn hàng:</span>
        <span class="value">${orderCode}</span>
      </div>
      ${paymentId ? `
      <div class="detail-item">
        <span class="label">Mã giao dịch:</span>
        <span class="value">${paymentId}</span>
      </div>` : ''}
    </div>
    
    <button class="btn" onclick="goBackToApp()">Quay lại ứng dụng</button>
  </div>
  
  <script>
    function goBackToApp() {
      // Try opening deep links
      window.location.href = "pawmart://payment/success?orderCode=${orderCode}";
      
      // Fallback message for web view interceptors or standard users
      setTimeout(function() {
        alert("Nếu ứng dụng không tự mở, bạn có thể tự đóng cửa sổ trình duyệt này.");
      }, 1500);
    }
    // Auto-redirect on load
    window.onload = function() {
      setTimeout(goBackToApp, 500);
    }
  </script>
</body>
</html>
      `;
      return new NextResponse(html, {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      });
    } catch (error) {
      return handleError(error);
    }
  }

  async handleCancel(req: NextRequest) {
    try {
      const { searchParams } = new URL(req.url);
      const orderCode = searchParams.get('orderCode') || '';

      const html = `
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Thanh toán đã hủy - PawMart</title>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: 'Outfit', sans-serif;
      background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      color: #333;
    }
    .card {
      background: white;
      padding: 40px;
      border-radius: 24px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.1);
      text-align: center;
      max-width: 450px;
      width: 90%;
      box-sizing: border-box;
      animation: slideUp 0.6s cubic-bezier(0.16, 1, 0.3, 1);
    }
    @keyframes slideUp {
      from { transform: translateY(30px); opacity: 0; }
      to { transform: translateY(0); opacity: 1; }
    }
    .icon-container {
      width: 80px;
      height: 80px;
      background: #fff0f6;
      color: #e64980;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
      font-size: 40px;
      font-weight: bold;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0% { box-shadow: 0 0 0 0 rgba(230, 73, 128, 0.4); }
      70% { box-shadow: 0 0 0 15px rgba(230, 73, 128, 0); }
      100% { box-shadow: 0 0 0 0 rgba(230, 73, 128, 0); }
    }
    h1 {
      font-size: 26px;
      font-weight: 800;
      margin: 0 0 12px;
      color: #e64980;
    }
    p {
      font-size: 16px;
      color: #666;
      line-height: 1.5;
      margin: 0 0 30px;
    }
    .btn {
      display: inline-block;
      background: #ff8e53;
      color: white;
      text-decoration: none;
      padding: 14px 28px;
      border-radius: 12px;
      font-weight: 600;
      font-size: 16px;
      transition: all 0.3s ease;
      border: none;
      cursor: pointer;
      box-shadow: 0 4px 15px rgba(255, 142, 83, 0.3);
      width: 100%;
    }
    .btn:hover {
      background: #f07635;
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(255, 142, 83, 0.4);
    }
    .btn:active {
      transform: translateY(0);
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon-container">✕</div>
    <h1>Thanh toán đã hủy</h1>
    <p>Giao dịch của bạn đã bị hủy bỏ hoặc không thể hoàn thành. Vui lòng thử lại hoặc chọn hình thức thanh toán khác.</p>
    
    <button class="btn" onclick="goBackToApp()">Quay lại ứng dụng</button>
  </div>
  
  <script>
    function goBackToApp() {
      // Try opening deep links
      window.location.href = "pawmart://payment/cancel?orderCode=${orderCode}";
      
      // Fallback message for web view interceptors or standard users
      setTimeout(function() {
        alert("Nếu ứng dụng không tự mở, bạn có thể tự đóng cửa sổ trình duyệt này.");
      }, 1500);
    }
    // Auto-redirect on load
    window.onload = function() {
      setTimeout(goBackToApp, 500);
    }
  </script>
</body>
</html>
      `;
      return new NextResponse(html, {
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      });
    } catch (error) {
      return handleError(error);
    }
  }

  async webhook(req: NextRequest) {
    try {
      const body = await req.json();
      await paymentService.verifyWebhook(body);
      return NextResponse.json({ success: true }, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }
}
