import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgetlisting/models/transaction_model.dart';
import 'package:budgetlisting/models/location_model.dart';
import 'package:budgetlisting/services/transaction_service.dart';
import 'package:budgetlisting/services/location_service.dart';

class EditPage extends StatefulWidget {
  final Transaction transaction;

  const EditPage({super.key, required this.transaction});

  @override
  State<EditPage> createState() => _EditPage();
}

class _EditPage extends State<EditPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();

  String? _type;
  String? _currencyCode;
  String? _timeZone;
  DateTime _selectedDate = DateTime.now();
  double _currencyRate = 1.0;

  final List<String> _types = ['income', 'expense'];
  final List<String> _currencies = ['USD', 'JPY', 'EUR', 'SGD', 'IDR'];
  final Map<String, double> _currencyRates = {
    'USD': 16200.0,
    'JPY': 112.0,
    'EUR': 18500.0,
    'SGD': 12600.0,
    'IDR': 1.0
  };

  final Map<String, String> _timezones = {
    'Asia/Jakarta': 'WIB',
    'Asia/Makassar': 'WITA',
    'Asia/Jayapura': 'WIT',
    'Europe/London': 'London',
  };

  List<Location> _allLocations = [];
  Location? _selectedLocation;
  bool _isLoadingLocation = false;

  // Warna utama aplikasi
  final Color mainColor = const Color.fromRGBO(97, 126, 140, 1.0);

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAllLocations();
    _populateFormData();
  }

  void _populateFormData() {
    final transaction = widget.transaction;
    setState(() {
      _type = transaction.type;
      _currencyCode = transaction.currencyCode;
      _timeZone = transaction.timeZone;
      _currencyRate = transaction.currencyRate ?? 1.0;
      _selectedDate = DateFormat('yyyy-MM-dd').parse(transaction.date!);

      _amountController.text = transaction.amount?.toStringAsFixed(2) ?? '';
      _categoryController.text = transaction.category ?? '';
      _noteController.text = transaction.note ?? '';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _loadAllLocations() async {
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final results = await LocationService().getAllLocations(token);
      setState(() {
        _allLocations = results;

        if (widget.transaction.locationId != null) {
          try {
            _selectedLocation = results.firstWhere(
                  (loc) => loc.id == widget.transaction.locationId!.id,
            );
          } catch (e) {
            _selectedLocation = null;
          }
        } else {
          _selectedLocation = null;
        }
      });
    } catch (e) {
      setState(() {
        _allLocations = [];
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _updateTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token not found')));
      return;
    }

    final updatedTransaction = Transaction(
      id: widget.transaction.id,
      type: _type!,
      amount: double.parse(_amountController.text),
      category: _categoryController.text,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      currencyCode: _currencyCode,
      currencyRate: _currencyRate,
      timeZone: _timeZone,
      locationName: _selectedLocation?.name,
      locationId: _selectedLocation,
    );

    try {
      final result = await TransactionAPI.updateTransaction(
        updatedTransaction,
        widget.transaction.id!,
        token,
      );

      if (result['message']?.toLowerCase().contains('updated') == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil diperbarui')),
        );
        Navigator.pop(context, true); // true agar DetailPage tahu data sudah diperbarui
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${result['message'] ?? 'Unknown error'}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 3,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Transaksi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
            // Nama Kategori
            _buildInputCard(
            icon: Icons.category,
            label: 'Nama',
            child: TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                hintText: 'Masukkan nama transaksi',
                border: InputBorder.none,
              ),
              validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
            ),
          ),

          const SizedBox(height: 16),

          // Tipe Transaksi
          _buildInputCard(
            icon: Icons.compare_arrows,
            label: 'Tipe',
            child: DropdownButtonFormField<String>(
              value: _type,
              items: _types
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _type = val),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              validator: (val) => val == null ? 'Pilih tipe' : null,
            ),
          ),

          const SizedBox(height: 16),

          // Jumlah
          _buildInputCard(
            icon: Icons.attach_money,
            label: 'Jumlah',
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Masukkan jumlah',
                border: InputBorder.none,
              ),
              validator: (val) => val == null || double.tryParse(val) == null
                  ? 'Masukkan angka valid'
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // Catatan
          _buildInputCard(
            icon: Icons.note,
            label: 'Catatan (opsional)',
            child: TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Tambahkan catatan',
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Tanggal
          _buildInputCard(
            icon: Icons.calendar_today,
            label: 'Tanggal',
            child: InkWell(
              onTap: _pickDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                  const Icon(Icons.calendar_month, color: Colors.grey),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Mata Uang
        _buildInputCard(
          icon: Icons.currency_exchange,
          label: 'Mata Uang',
          child: DropdownButtonFormField<String>(
            value: _currencyCode,
            items: _currencies
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _currencyCode = val;
                _currencyRate = _currencyRates[val] ?? 1.0;
              });
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Zona Waktu
        _buildInputCard(
          icon: Icons.access_time,
          label: 'Zona Waktu',
          child: DropdownButtonFormField<String>(
            value: _timeZone,
            items: _timezones.entries
                .map(
                  (entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
                .toList(),
            onChanged: (val) => setState(() => _timeZone = val),
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Lokasi
        _buildInputCard(
          icon: Icons.location_on,
          label: 'Lokasi (opsional)',
          child: _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : DropdownButton<Location>(
            value: _selectedLocation,
            items: _allLocations
                .map(
                  (loc) => DropdownMenuItem(
                value: loc,
                child: Text(loc.name),
              ),
            )
                .toList(),
            onChanged: (val) {
              setState(() => _selectedLocation = val);
            },
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Pilih lokasi'),
          ),
        ),

        const SizedBox(height: 30),

        // Tombol Update
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'Perbarui Transaksi',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: _updateTransaction,
          ),
        ),
        ],
      ),
    ),
    ),
    );
  }

  // Widget untuk membangun input card yang konsisten
  Widget _buildInputCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: mainColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: Colors.grey, size: 24),
                const SizedBox(width: 12),
                Expanded(child: child),
              ],
            ),
          ],
        ),
      ),
    );
  }
}