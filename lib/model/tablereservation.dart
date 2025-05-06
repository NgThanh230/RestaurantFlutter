class TableReservation {
  final int id;
  final String guestName;
  final String guestPhone;
  final int numberOfGuests;
  final DateTime startTime;
  final DateTime createdAt;
  final String notes;
  final String status;

  TableReservation({
    required this.id,
    required this.guestName,
    required this.guestPhone,
    required this.numberOfGuests,
    required this.startTime,
    required this.createdAt,
    required this.notes,
    required this.status,
  });

  factory TableReservation.fromJson(Map<String, dynamic> json) {
    return TableReservation(
      id: json['id'],
      guestName: json['guestName'],
      guestPhone: json['guestPhone'],
      numberOfGuests: json['numberOfGuests'],
      startTime: DateTime.parse(json['startTime']),
      createdAt: DateTime.parse(json['createdAt']),
      notes: json['notes'] ?? '',
      status: json['status'],
    );
  }
}
