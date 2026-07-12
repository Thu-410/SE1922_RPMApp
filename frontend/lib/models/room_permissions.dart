class RoomPermissions {
  const RoomPermissions({
    required this.canView,
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
    required this.canUpdateStatus,
  });

  final bool canView;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canUpdateStatus;

  // Giữ tương thích khi module đăng nhập/phân quyền chưa được merge.
  static const unrestricted = RoomPermissions(
    canView: true,
    canCreate: true,
    canEdit: true,
    canDelete: true,
    canUpdateStatus: true,
  );

  static const denied = RoomPermissions(
    canView: false,
    canCreate: false,
    canEdit: false,
    canDelete: false,
    canUpdateStatus: false,
  );

  factory RoomPermissions.fromRole(String? roleName) {
    return switch (roleName?.trim().toLowerCase()) {
      'manager' => unrestricted,
      'staff' => const RoomPermissions(
        canView: true,
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canUpdateStatus: true,
      ),
      'tenant' => const RoomPermissions(
        canView: true,
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canUpdateStatus: false,
      ),
      _ => denied,
    };
  }
}
