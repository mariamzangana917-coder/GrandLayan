import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/customer_auth_provider.dart';
import '../data/models/customer_appointment.dart';
import '../data/repositories/appointment_repository.dart';
import '../data/services/appointment_api_service.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppointmentRepository(
    apiService: AppointmentApiService(apiClient: apiClient),
  );
});

final customerAppointmentsProvider =
    AsyncNotifierProvider<CustomerAppointmentsNotifier, List<CustomerAppointment>>(
  CustomerAppointmentsNotifier.new,
);

class CustomerAppointmentsNotifier
    extends AsyncNotifier<List<CustomerAppointment>> {
  AppointmentRepository get _repository =>
      ref.read(appointmentRepositoryProvider);

  @override
  Future<List<CustomerAppointment>> build() async {
    return _fetchAppointments();
  }

  Future<List<CustomerAppointment>> _fetchAppointments() async {
    final response = await _repository.fetchAppointments(page: 1);
    return response.appointments;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAppointments);
  }

  Future<CustomerAppointment> cancelAppointment({
    required int appointmentId,
    required String reason,
  }) async {
    final updatedAppointment = await _repository.cancelCustomerAppointment(
      appointmentId: appointmentId,
      reason: reason,
    );

    final currentList = state.asData?.value;
    if (currentList != null) {
      final updatedList = currentList.map((appointment) {
        if (appointment.id == appointmentId) {
          return updatedAppointment;
        }
        return appointment;
      }).toList();
      state = AsyncData(updatedList);
    }

    ref.invalidate(customerAppointmentDetailsProvider(appointmentId));

    return updatedAppointment;
  }
}

class AppointmentTabFilterNotifier
    extends Notifier<AppointmentStatusCategory> {
  @override
  AppointmentStatusCategory build() {
    return AppointmentStatusCategory.upcoming;
  }

  void setFilter(AppointmentStatusCategory category) {
    state = category;
  }
}

final appointmentTabFilterProvider = NotifierProvider<
    AppointmentTabFilterNotifier, AppointmentStatusCategory>(
  AppointmentTabFilterNotifier.new,
);

final filteredAppointmentsProvider =
    Provider.autoDispose<AsyncValue<List<CustomerAppointment>>>((ref) {
  final appointmentsAsync = ref.watch(customerAppointmentsProvider);
  final filter = ref.watch(appointmentTabFilterProvider);

  return appointmentsAsync.whenData((appointments) {
    return switch (filter) {
      AppointmentStatusCategory.upcoming =>
        appointments.where((a) => a.isUpcoming).toList(),
      AppointmentStatusCategory.past =>
        appointments.where((a) => a.isPast).toList(),
      AppointmentStatusCategory.all => appointments,
    };
  });
});

final customerAppointmentDetailsProvider = FutureProvider.autoDispose
    .family<CustomerAppointment, int>((ref, appointmentId) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.fetchAppointmentDetails(appointmentId);
});
