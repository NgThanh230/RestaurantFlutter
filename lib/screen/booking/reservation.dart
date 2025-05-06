import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test2/service/reservationsv.dart';
import 'package:test2/model/reservation.dart';
import 'package:test2/screen/booking/usingtable.dart'; // Import màn hình UsingTableScreen
import 'package:test2/screen/order/order.dart';

class ReservationScreen extends StatefulWidget {
  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _guestCountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<String> _tables = [];
  String? _selectedTable;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  bool _isLoading = false;
  bool _tablesFetched = false;

  List<String> _availableTimes = [];

  void _generateAvailableTimes() {
    _availableTimes.clear();
    DateTime startTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 10, 0);
    DateTime endTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 21, 0);

    while (startTime.isBefore(endTime)) {
      String time = DateFormat('HH:mm').format(startTime);
      _availableTimes.add(time);
      startTime = startTime.add(Duration(minutes: 30));
    }
  }

  Future<void> _fetchTables() async {
    final DateTime fullDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 17, 0);

    setState(() {
      _isLoading = true;
    });

    final tables = await ReservationService.fetchTablesForDateTime(fullDateTime);

    setState(() {
      _tables = tables;
      _selectedTable = _tables.isNotEmpty ? _tables[0] : null;
      _tablesFetched = true;
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tablesFetched = false;
        _selectedTable = null;
        _tables = [];
      });
      await _fetchTables();
    }
  }

  @override
  void initState() {
    super.initState();
    _generateAvailableTimes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đặt Bàn')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tên:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _nameController),
              SizedBox(height: 16),
              Text('Số điện thoại:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Số điện thoại của bạn',
                ),
              ),
              SizedBox(height: 16),
              Text('Ngày:', style: TextStyle(fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('Giờ:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'Chọn giờ',
                  border: OutlineInputBorder(),
                ),
                value: _selectedTime,
                hint: Text('Chọn giờ'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTime = newValue;
                  });
                },
                items: _availableTimes.map((String time) {
                  return DropdownMenuItem<String>(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              Text('Số khách:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _guestCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Số lượng khách',
                ),
              ),
              SizedBox(height: 16),
              Text('Ghi chú:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Yêu cầu đặc biệt (nếu có)',
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    if (_nameController.text.isEmpty || _selectedTime == null || _guestCountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                      );
                      return;
                    }

                    // Kiểm tra giá trị số khách hợp lệ
                    if (int.tryParse(_guestCountController.text) == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vui lòng nhập số khách hợp lệ')),
                      );
                      return;
                    }

                    int guestCount = int.tryParse(_guestCountController.text) ?? 1;
                    final reservation = Reservation(
                      id: 0, // chỉ để placeholder, không dùng khi tạo
                      startTime: DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        int.parse(_selectedTime!.split(':')[0]),
                        int.parse(_selectedTime!.split(':')[1]),
                      ),
                      numberOfGuests: guestCount,
                      guestName: _nameController.text,
                      guestPhone: _phoneController.text,
                      notes: _notesController.text,
                      status: 'PENDING', // hoặc 'NEW' tùy logic backend
                    );

                    // In ra thông tin trước khi gửi để debug
                    print("Đang gửi đặt bàn với số khách: ${reservation.numberOfGuests}");

                    setState(() {
                      _isLoading = true;
                    });

                    Reservation? createdReservation = await ReservationService.createReservation(reservation);

                    setState(() {
                      _isLoading = false;
                    });

                    if (createdReservation != null) {
                      print("Reservation ID: ${createdReservation.id}");
                      print("Number of guests: ${createdReservation.numberOfGuests}");

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Đặt bàn thành công'),
                            content: Text('Bạn có muốn đặt món luôn không?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UsingTableScreen(
                                        reservationId: createdReservation.id,
                                        reservationData: createdReservation, // Truyền dữ liệu đặt bàn đã nhập
                                      ),
                                    ),
                                  );
                                },
                                child: Text('Tôi sẽ đặt sau'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderScreen(),
                                    ),
                                  );
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đặt bàn thất bại. Vui lòng thử lại')),
                      );
                    }
                  },
                  child: Text('Đặt Bàn'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}