import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/configs/providers.dart';
import '../../../domain/entities/user.dart';
import '../../../data/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState {
  final ProfileStatus status;
  final User? user;
  final String? errorMessage;

  ProfileState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory ProfileState.initial() => ProfileState(status: ProfileStatus.initial);
  factory ProfileState.loading() => ProfileState(status: ProfileStatus.loading);
  factory ProfileState.loaded(User user) => ProfileState(status: ProfileStatus.loaded, user: user);
  factory ProfileState.error(String message) => ProfileState(status: ProfileStatus.error, errorMessage: message);

  ProfileState copyWith({
    ProfileStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  io.Socket? _socket;

  @override
  ProfileState build() {
    dev.log('[ProfileNotifier] build() executed');

    // Listen to changes on authNotifierProvider dynamically without re-triggering builds
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      dev.log('[ProfileNotifier] authNotifierProvider changed. Status: ${next.status}');
      if (next.status == AuthStatus.unauthenticated) {
        _disconnectSocket();
        state = ProfileState.initial();
      } else if (next.status == AuthStatus.authenticated && next.user != null) {
        state = ProfileState.loaded(next.user!);
        _connectSocket();
      }
    });

    ref.onDispose(() {
      dev.log('[ProfileNotifier] disposing');
      _disconnectSocket();
    });

    final authState = ref.read(authNotifierProvider);
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      dev.log('[ProfileNotifier] initializing state: authenticated user');
      // Return initially with user data from session, then lazily fetch full profile
      Future.microtask(() {
        loadProfile();
        _connectSocket();
      });
      return ProfileState.loaded(authState.user!);
    } else {
      dev.log('[ProfileNotifier] initializing state: unauthenticated user');
      return ProfileState.initial();
    }
  }

  // 1. Fetch profile metadata from REST
  Future<void> loadProfile() async {
    dev.log('[ProfileNotifier] loadProfile() triggered');
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.get('/users/profile');
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        dev.log('[ProfileNotifier] loadProfile() success. Syncing user to state.');
        state = ProfileState.loaded(user);
        
        // Sync back to auth provider
        ref.read(authNotifierProvider.notifier).updateSessionUser(user);
      } else {
        state = ProfileState.error('Không thể tải thông tin cá nhân.');
      }
    } catch (e) {
      dev.log('Error loading profile: $e');
      state = ProfileState.error('Không thể kết nối máy chủ.');
    }
  }

  // 2. Update profile fields
  Future<bool> updateProfile({
    required String fullName,
    String? phone,
    String? gender,
    DateTime? birthday,
    String? bio,
  }) async {
    dev.log('[ProfileNotifier] updateProfile() triggered');
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.patch('/users/profile', data: {
        'fullName': fullName,
        'phoneNumber': phone,
        'gender': gender,
        'birthday': birthday?.toIso8601String(),
        'bio': bio,
      });

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        dev.log('[ProfileNotifier] updateProfile() success. Syncing user.');
        state = ProfileState.loaded(user);
        
        // Sync back to auth provider
        ref.read(authNotifierProvider.notifier).updateSessionUser(user);
        return true;
      } else {
        state = ProfileState.error('Cập nhật thông tin thất bại.');
        return false;
      }
    } catch (e) {
      dev.log('[ProfileNotifier] Error updating profile: $e');
      state = ProfileState.error('Không thể lưu thông tin. Vui lòng kiểm tra kết nối.');
      return false;
    }
  }

  // 3. Upload avatar directly to Cloudinary via backend profile endpoint
  Future<bool> uploadAvatar(XFile file) async {
    dev.log('[ProfileNotifier] uploadAvatar() triggered for file: ${file.name}');
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final client = ref.read(apiClientProvider);
      
      final MultipartFile multipartFile;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        );
      } else {
        multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        );
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await client.dio.post(
        '/users/profile/avatar',
        data: formData,
      );

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        dev.log('[ProfileNotifier] uploadAvatar() success. Syncing user.');
        state = ProfileState.loaded(user);
        
        // Sync back to auth provider
        ref.read(authNotifierProvider.notifier).updateSessionUser(user);
        return true;
      } else {
        state = ProfileState.error('Tải ảnh đại diện thất bại.');
        return false;
      }
    } catch (e) {
      dev.log('[ProfileNotifier] Error uploading avatar: $e');
      state = ProfileState.error('Lỗi khi tải ảnh lên. Vui lòng thử lại.');
      return false;
    }
  }

  // 4. Remove avatar URL (PATCH null to avatar)
  Future<bool> removeAvatar() async {
    dev.log('[ProfileNotifier] removeAvatar() triggered');
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.patch('/users/profile', data: {
        'avatar': null,
      });

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        dev.log('[ProfileNotifier] removeAvatar() success. Syncing user.');
        state = ProfileState.loaded(user);
        ref.read(authNotifierProvider.notifier).updateSessionUser(user);
        return true;
      } else {
        state = ProfileState.error('Xóa ảnh đại diện thất bại.');
        return false;
      }
    } catch (e) {
      dev.log('[ProfileNotifier] Error removing avatar: $e');
      state = ProfileState.error('Lỗi kết nối máy chủ.');
      return false;
    }
  }

  // 5. Connect background socket to auto-update badges
  void _connectSocket() {
    if (_socket != null && _socket!.connected) return;

    final token = ref.read(authLocalDataSourceProvider).getAccessToken();
    if (token == null || token.isEmpty) return;

    final String apiBase = ApiClient.getBaseUrl();
    String socketUrl = 'http://localhost:3002';
    if (apiBase.contains('10.0.2.2')) {
      socketUrl = 'http://10.0.2.2:3002';
    } else if (apiBase.contains('localhost')) {
      socketUrl = 'http://localhost:3002';
    } else {
      try {
        final uri = Uri.parse(apiBase);
        socketUrl = '${uri.scheme}://${uri.host}:3002';
      } catch (_) {}
    }

    dev.log('Profile socket connecting to: $socketUrl/chat');

    _socket = io.io('$socketUrl/chat', io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .disableAutoConnect()
        .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      dev.log('Profile socket connected: auto-badge active');
    });

    _socket!.on('conversations_updated', (data) {
      if (data != null && data['conversationId'] != null) {
        final int cid = data['conversationId'] as int;
        if (state.user?.conversationId == cid && data['unreadCustomer'] != null) {
          final int unread = data['unreadCustomer'] as int;
          dev.log('Auto-updating unread customer badge via Socket: $unread');
          if (state.user != null) {
            final updatedUser = state.user!.copyWith(unreadSupportMessages: unread);
            state = ProfileState.loaded(updatedUser);
            ref.read(authNotifierProvider.notifier).updateSessionUser(updatedUser);
          }
        }
      }
    });
  }

  void _disconnectSocket() {
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.close();
      _socket = null;
      dev.log('Profile socket disconnected');
    }
  }

  void refresh() {
    loadProfile();
  }
}

final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});
