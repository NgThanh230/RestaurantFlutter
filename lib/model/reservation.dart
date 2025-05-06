class Reservation {
  final int id;
  final DateTime startTime;
  final int numberOfGuests;
  final String guestName;
  final String guestPhone;
  final String notes;
  final String status;

  Reservation({
    required this.id,
    required this.startTime,
    required this.numberOfGuests,
    required this.guestName,
    required this.guestPhone,
    required this.notes,
    required this.status,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] ?? 0,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : DateTime.now(),
      numberOfGuests: json['numberOfGuests'] ?? 0,
      guestName: json['guestName'] ?? '',
      guestPhone: json['guestPhone'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'numberOfGuests': numberOfGuests,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'notes': notes,
      'status': status,
    };
  }
}