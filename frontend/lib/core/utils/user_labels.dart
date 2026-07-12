String roleLabel(String? role) => switch (role) {
  'manager' => 'Quản lý',
  'staff' => 'Nhân viên',
  'tenant' => 'Người thuê',
  _ => role ?? '',
};

String statusLabel(String? status) => switch (status) {
  'active' => 'Đang hoạt động',
  'inactive' => 'Ngừng hoạt động',
  'locked' => 'Đã khóa',
  _ => status ?? '',
};
