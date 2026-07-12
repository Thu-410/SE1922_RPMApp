import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/user_labels.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadProfile().catchError((_) {
        if (!mounted) return;
        final message =
            context.read<AuthProvider>().errorMessage ?? 'Không thể tải hồ sơ';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      });
    });
  }

  Future<void> _openEditDialog() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) return;

    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chỉnh sửa thông tin'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'Họ tên'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
                      return 'Số điện thoại phải gồm 10 số và bắt đầu bằng 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ListenableBuilder(
              listenable: authProvider,
              builder: (context, _) => FilledButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        try {
                          await authProvider.updateProfile(
                            fullName: fullNameController.text.trim(),
                            phone: phoneController.text.trim(),
                          );

                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cập nhật thông tin thành công'),
                            ),
                          );
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                authProvider.errorMessage ??
                                    'Cập nhật thất bại',
                              ),
                            ),
                          );
                        }
                      },
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ),
          ],
        );
      },
    );

    fullNameController.dispose();
    phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: authProvider.isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: const Color(0xFFDDEDEA),
                      child: Text(
                        (user?.fullName.isNotEmpty ?? false)
                            ? user!.fullName
                                  .trim()
                                  .split(RegExp(r'\s+'))
                                  .where((part) => part.isNotEmpty)
                                  .map((e) => e[0])
                                  .take(2)
                                  .join()
                                  .toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDEDEA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              child: Text(
                                roleLabel(user?.role),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _ProfileRow(label: 'Email', value: user?.email ?? ''),
                      const Divider(),
                      _ProfileRow(
                        label: 'Điện thoại',
                        value: user?.phone ?? 'Chưa cập nhật',
                      ),
                      const Divider(),
                      _ProfileRow(
                        label: 'Trạng thái',
                        value: statusLabel(user?.status),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: authProvider.isLoading ? null : _openEditDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Chỉnh sửa'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamed(ChangePasswordScreen.routeName);
                  },
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Đổi mật khẩu'),
                ),
              ],
            ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
