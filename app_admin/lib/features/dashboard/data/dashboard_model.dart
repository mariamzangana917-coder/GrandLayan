class DashboardModel {
  const DashboardModel({
    required this.todayAppointments,
    required this.pendingAppointments,
    required this.inProgressAppointments,
    required this.completedAppointments,
    required this.followUp,
  });

  final int todayAppointments;
  final int pendingAppointments;
  final int inProgressAppointments;
  final int completedAppointments;
  final DashboardFollowUp? followUp;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final summary =
        json['summary'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final followUpJson = json['follow_up'];

    return DashboardModel(
      todayAppointments: _toInt(summary['today']),
      pendingAppointments: _toInt(summary['pending']),
      inProgressAppointments: _toInt(summary['in_progress']),
      completedAppointments: _toInt(summary['completed']),
      followUp: followUpJson is Map
          ? DashboardFollowUp.fromJson(Map<String, dynamic>.from(followUpJson))
          : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DashboardFollowUp {
  const DashboardFollowUp({
    required this.id,
    required this.reference,
    required this.customerName,
    required this.status,
    required this.requestedStartAt,
    required this.itemNames,
  });

  final int id;
  final String reference;
  final String customerName;
  final String status;
  final DateTime? requestedStartAt;
  final List<String> itemNames;

  factory DashboardFollowUp.fromJson(Map<String, dynamic> json) {
    final customer =
        json['customer'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final rawItems = json['items'];

    final itemNames = <String>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          final mappedItem = Map<String, dynamic>.from(item);

          final name = mappedItem['item_name'] ?? mappedItem['name'];

          if (name != null && name.toString().trim().isNotEmpty) {
            itemNames.add(name.toString());
          }
        }
      }
    }

    return DashboardFollowUp(
      id: DashboardModel._toInt(json['id']),
      reference: json['reference']?.toString() ?? '',
      customerName: customer['name']?.toString() ?? 'عميلة',
      status: json['status']?.toString() ?? 'pending',
      requestedStartAt: DateTime.tryParse(
        json['requested_start_at']?.toString() ?? '',
      ),
      itemNames: itemNames,
    );
  }

  String get servicesText {
    if (itemNames.isEmpty) {
      return 'لا توجد خدمات';
    }

    return itemNames.join(' + ');
  }
}
