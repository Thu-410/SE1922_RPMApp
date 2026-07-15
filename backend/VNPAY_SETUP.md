# Cấu hình VNPay

Ứng dụng không lưu `VNPAY_HASH_SECRET` trong Flutter. Backend tạo URL có chữ ký,
nhận IPN từ VNPay và chỉ sau đó mới cập nhật hóa đơn thành `paid`.

## Biến môi trường

Thêm vào `backend/.env`:

```env
PAYMENT_PUBLIC_URL=https://your-public-backend.example
VNPAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNPAY_TMN_CODE=YOUR_TMN_CODE
VNPAY_HASH_SECRET=YOUR_HASH_SECRET
```

`PAYMENT_PUBLIC_URL` không có `/api` ở cuối và phải là HTTPS truy cập được từ
Internet. Không commit file `.env`.

## URL đăng ký với VNPay

- Return URL: `https://your-public-backend.example/api/online-payments/vnpay/return`
- IPN URL: `https://your-public-backend.example/api/online-payments/vnpay/ipn`

Return URL chuyển trình duyệt về deep link `vnpaypayment://return`. Flutter chỉ
dùng deep link để làm mới màn hình; kết quả đáng tin cậy vẫn là IPN backend.

## Kiểm thử

1. Đăng nhập bằng tài khoản tenant có hóa đơn `unpaid` hoặc `overdue`.
2. Mở hóa đơn và chọn **Thanh toán ngay**.
3. Chọn **VNPay** và hoàn tất giao dịch sandbox.
4. VNPay gọi IPN; backend xác minh HMAC-SHA512, số tiền và mã hóa đơn.
5. Quay lại ứng dụng; hóa đơn được tải lại và hiển thị `paid`.
