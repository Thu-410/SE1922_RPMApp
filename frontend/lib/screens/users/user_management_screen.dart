import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/user_labels.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../core/theme/app_theme.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  static const routeName = '/users';

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _selectedRole;
  String? _selectedStatus;
  int _page = 1;
  int _totalPages = 1;

  static const _roles = ['manager', 'staff', 'tenant'];
  static const _statuses = ['active', 'inactive', 'locked'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().user?.role == 'manager') _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({int? page}) async {
    setState(() => _isLoading = true);

    try {
      final result = await context.read<UserService>().getUsers(
        role: _selectedRole,
        status: _selectedStatus,
        search: _searchController.text.trim(),
        page: page ?? _page,
        limit: 10,
      );

      if (!mounted) return;
      setState(() {
        _users = result.users;
        _page = result.page;
        _totalPages = result.totalPages;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openAddUser() async {
    final created = await Navigator.of(
      context,
    ).pushNamed(AddUserScreen.routeName);
    if (created == true) {
      await _loadUsers(page: 1);
    }
  }

  Future<void> _openEditUser(UserModel user) async {
    final updated = await Navigator.of(
      context,
    ).pushNamed(EditUserScreen.routeName, arguments: user);
    if (updated == true) {
      await _loadUsers();
    }
  }

  Future<void> _lockUser(UserModel user) async {
    final userService = context.read<UserService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khóa tài khoản'),
        content: Text('Bạn có chắc muốn khóa tài khoản ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Khóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await userService.deleteUser(user.id);
      if (!mounted) return;
      _showMessage('Đã khóa tài khoản');
      await _loadUsers();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;

    if (role != 'manager') {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý tài khoản')),
        body: const Center(child: Text('Chỉ Manager được truy cập màn này')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : () => _loadUsers(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddUser,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm người dùng'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Tìm theo tên/email',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => _loadUsers(page: 1),
                      icon: const Icon(Icons.tune),
                    ),
                  ),
                  onSubmitted: (_) => _loadUsers(page: 1),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tất cả'),
                          ),
                          ..._roles.map(
                            (role) => DropdownMenuItem<String?>(
                              value: role,
                              child: Text(roleLabel(role)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedRole = value);
                          _loadUsers(page: 1);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tất cả'),
                          ),
                          ..._statuses.map(
                            (status) => DropdownMenuItem<String?>(
                              value: status,
                              child: Text(statusLabel(status)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                          _loadUsers(page: 1);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: _users.isEmpty && !_isLoading
                ? const Center(child: Text('Không có tài khoản nào'))
                : ListView.separated(
                    itemCount: _users.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(user.fullName),
                          subtitle: Text(
                            '${user.email}\n${roleLabel(user.role)} • ${statusLabel(user.status)}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _openEditUser(user);
                              }
                              if (value == 'lock') {
                                _lockUser(user);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Sửa')),
                              PopupMenuItem(
                                value: 'lock',
                                child: Text('Khóa tài khoản'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: _page > 1 && !_isLoading
                      ? () => _loadUsers(page: _page - 1)
                      : null,
                  child: const Text('Trước'),
                ),
                Text('Trang $_page / $_totalPages'),
                OutlinedButton(
                  onPressed: _page < _totalPages && !_isLoading
                      ? () => _loadUsers(page: _page + 1)
                      : null,
                  child: const Text('Sau'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
