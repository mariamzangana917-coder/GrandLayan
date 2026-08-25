import '../models/customer_appointment.dart';
import '../services/appointment_api_service.dart';

class AppointmentRepository {
  AppointmentRepository({AppointmentApiService? apiService})
    : _apiService = apiService ?? AppointmentApiService();

  final AppointmentApiService _apiService;

  Future<Map<String, dynamic>> createAppointment({
    required int departmentId,
    required DateTime requestedStartAt,
    required int catalogItemId,
    int quantity = 1,
    String? customerNotes,
    String? couponCode,
  }) {
    return _apiService.createAppointment(
      departmentId: departmentId,
      requestedStartAt: requestedStartAt,
      customerNotes: customerNotes,
      couponCode: couponCode,
      items: <Map<String, dynamic>>[
        <String, dynamic>{
          'catalog_item_id': catalogItemId,
          'quantity': quantity,
        },
      ],
    );
  }

  Future<Map<String, dynamic>> createAppointmentWithItems({
    required int departmentId,
    required DateTime requestedStartAt,
    required List<int> catalogItemIds,
    String? customerNotes,
    String? couponCode,
  }) {
    if (catalogItemIds.isEmpty) {
      throw ArgumentError('يجب اختيار خدمة واحدة على الأقل.');
    }

    final List<int> uniqueIds = catalogItemIds.toSet().toList(growable: false);

    return _apiService.createAppointment(
      departmentId: departmentId,
      requestedStartAt: requestedStartAt,
      customerNotes: customerNotes,
      couponCode: couponCode,
      items: uniqueIds
          .map(
            (int catalogItemId) => <String, dynamic>{
              'catalog_item_id': catalogItemId,
              'quantity': 1,
            },
          )
          .toList(growable: false),
    );
  }

  Future<Map<String, dynamic>> getAppointments({int page = 1}) {
    return _apiService.getAppointments(page: page);
  }

  Future<CustomerAppointmentListResponse> fetchAppointments({int page = 1}) async {
    final response = await _apiService.getAppointments(page: page);
    return CustomerAppointmentListResponse.fromJson(response);
  }

  Future<Map<String, dynamic>> getAppointment(int appointmentId) {
    return _apiService.getAppointment(appointmentId);
  }

  Future<CustomerAppointment> fetchAppointmentDetails(int appointmentId) async {
    final response = await _apiService.getAppointment(appointmentId);
    final rawData = response['data'];
    if (rawData is Map) {
      return CustomerAppointment.fromJson(Map<String, dynamic>.from(rawData));
    }
    return CustomerAppointment.fromJson(response);
  }

  Future<Map<String, dynamic>> cancelAppointment({
    required int appointmentId,
    required String reason,
  }) {
    return _apiService.cancelAppointment(
      appointmentId: appointmentId,
      reason: reason,
    );
  }

  Future<CustomerAppointment> cancelCustomerAppointment({
    required int appointmentId,
    required String reason,
  }) async {
    final response = await _apiService.cancelAppointment(
      appointmentId: appointmentId,
      reason: reason,
    );
    final rawData = response['data'];
    if (rawData is Map) {
      return CustomerAppointment.fromJson(Map<String, dynamic>.from(rawData));
    }
    return CustomerAppointment.fromJson(response);
  }
}
