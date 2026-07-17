import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import './providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  
  String? _selectedGender;
  DateTime? _selectedBirthday;
  
  final List<String> _genders = ['Nam', 'Nữ', 'Khác'];

  @override
  void initState() {
    super.initState();
    debugPrint('[EditProfileScreen] initState() executed');
    final profile = ref.read(profileNotifierProvider).user;
    
    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    
    _selectedGender = profile?.gender;
    if (_selectedGender != null && !_genders.contains(_selectedGender)) {
      _selectedGender = 'Khác';
    }
    
    _selectedBirthday = profile?.birthday;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
              primary: Colors.orange.shade800,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Close bottom sheet
        navigator.pop();
        
        final success = await ref
            .read(profileNotifierProvider.notifier)
            .uploadAvatar(image);

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success ? 'Cập nhật ảnh đại diện thành công' : 'Lỗi khi tải ảnh lên'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Không thể chọn hình ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAvatarPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.orange),
                title: const Text('Chọn ảnh từ Thư viện'),
                onTap: () => _pickAndUploadImage(ImageSource.gallery),
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: Colors.orange),
                  title: const Text('Chụp ảnh mới'),
                  onTap: () => _pickAndUploadImage(ImageSource.camera),
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Xóa ảnh đại diện'),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  navigator.pop();
                  final success = await ref.read(profileNotifierProvider.notifier).removeAvatar();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Đã gỡ ảnh đại diện' : 'Gỡ ảnh đại diện thất bại'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(profileNotifierProvider.notifier).updateProfile(
            fullName: _fullNameController.text,
            phone: _phoneController.text,
            gender: _selectedGender,
            birthday: _selectedBirthday,
            bio: _bioController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Lưu thông tin thành công' : 'Lưu thông tin thất bại'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[EditProfileScreen] build() executed');
    final profileState = ref.watch(profileNotifierProvider);
    final user = profileState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final String initial = (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa thông tin',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),
      body: profileState.status == ProfileStatus.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar display and overlay trigger
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.orange.shade800, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ClipOval(
                              child: user?.avatar != null && user!.avatar!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: user.avatar!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      errorWidget: (context, url, error) => Center(
                                        child: Text(
                                          initial,
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 36,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 36,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _showAvatarPickerOptions(context),
                              child: Container(
                                height: 34,
                                width: 34,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade800,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Full Name Input
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Họ và tên không được để trống';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Phone Number Input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gender Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Giới tính',
                        prefixIcon: const Icon(Icons.wc_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _genders.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Birthday input trigger
                    InkWell(
                      onTap: () => _selectBirthday(context),
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ngày sinh',
                          prefixIcon: const Icon(Icons.calendar_month_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selectedBirthday == null
                              ? 'Chọn ngày sinh'
                              : '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}',
                          style: TextStyle(
                            color: _selectedBirthday == null
                                ? (isDark ? Colors.grey[600] : Colors.grey[700])
                                : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bio Input
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Tiểu sử',
                        prefixIcon: const Icon(Icons.edit_note_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                        ),
                        child: const Text(
                          'Lưu thay đổi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
