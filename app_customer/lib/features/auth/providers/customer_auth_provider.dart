import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/notifications/customer_device_token_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/models/customer_user.dart';
import '../data/repositories/customer_auth_repository.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(storage: ref.watch(secureStorageServiceProvider));
});

final customerDeviceTokenServiceProvider = Provider<CustomerDeviceTokenService>(
  (ref) {
    return CustomerDeviceTokenService(
      apiClient: ref.watch(apiClientProvider),
      storage: ref.watch(secureStorageServiceProvider),
    );
  },
);

final customerAuthRepositoryProvider = Provider<CustomerAuthRepository>((ref) {
  return CustomerAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageServiceProvider),
    deviceTokenService: ref.watch(customerDeviceTokenServiceProvider),
  );
});

final customerAuthProvider =
    AsyncNotifierProvider<CustomerAuthNotifier, CustomerUser?>(
      CustomerAuthNotifier.new,
    );

class CustomerAuthNotifier extends AsyncNotifier<CustomerUser?> {
  CustomerAuthRepository get _repository {
    return ref.read(customerAuthRepositoryProvider);
  }

  @override
  Future<CustomerUser?> build() async {
    return _repository.restoreSession();
  }

  Future<bool> login({required String login, required String password}) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => _repository.login(login: login, password: password),
    );

    state = result;

    return !result.hasError;
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => _repository.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      ),
    );

    state = result;

    return !result.hasError;
  }

  Future<CustomerUser> updateProfile({
    required String name,
    required String phone,
    required String email,
  }) async {
    final updatedCustomer = await _repository.updateProfile(
      name: name,
      phone: phone,
      email: email,
    );

    state = AsyncData(updatedCustomer);

    return updatedCustomer;
  }

  Future<CustomerUser> updateAvatar({required File image}) async {
    final updatedCustomer = await _repository.updateAvatar(image: image);

    state = AsyncData(updatedCustomer);

    return updatedCustomer;
  }

  Future<CustomerUser> deleteAvatar() async {
    final updatedCustomer = await _repository.deleteAvatar();

    state = AsyncData(updatedCustomer);

    return updatedCustomer;
  }

  Future<void> logout() async {
    state = const AsyncLoading();

    try {
      await _repository.logout();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refreshSession() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_repository.restoreSession);
  }
}
