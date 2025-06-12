import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:budgetlisting/services/transaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgetlisting/models/transaction_model.dart';
import 'package:budgetlisting/pages/edit_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DetailPage extends StatefulWidget {
  final int transactionId;

  const DetailPage({Key? key, required this.transactionId}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<Transaction> _futureTransaction;
  bool _isDeleting = false;
  final mainColor = const Color.fromRGBO(97, 126, 140, 1.0);

  @override
  void initState() {
    super.initState();
    _futureTransaction = _initializeFutureTransaction();
  }

  Future<Transaction> _initializeFutureTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final json = await TransactionAPI.getTransactionById(
      token,
      widget.transactionId,
    );
    return Transaction.fromJson(json);
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah kamu yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    setState(() {
      _isDeleting = true;
    });

    try {
      await TransactionAPI.deleteTransaction(widget.transactionId, token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
        Navigator.of(context).pop(true); // Kembalikan nilai true
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus transaksi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }


  String formatCurrency(dynamic amount, String? currencyCode) {
    if (amount == null) return '-';
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: currencyCode != null ? '$currencyCode ' : 'Rp ',
      decimalDigits: 2,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        backgroundColor: mainColor,
        elevation: 3,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      body: FutureBuilder<Transaction>(
        future: _futureTransaction,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Transaksi tidak ditemukan'));
          } else {
            final transaction = snapshot.data!;
            final amount = transaction.amount;
            final rate = transaction.currencyRate ?? 1.0;
            final totalInIDR = (amount != null) ? amount * rate : 0;

            final location = transaction.locationId;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📍 MAPS SECTION
                    if (location != null)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SizedBox(
                          height: 250,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: FlutterMap(
                              options: MapOptions(
                                center: LatLng(location.latitude, location.longitude),
                                zoom: 15.0,
                                interactiveFlags: InteractiveFlag.none,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  subdomains: ['a', 'b', 'c'],
                                  userAgentPackageName: 'com.example.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(location.latitude, location.longitude),
                                      width: 50,
                                      height: 50,
                                      builder: (ctx) => const Icon(
                                        Icons.location_on,
                                        size: 40,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Card(
                        color: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline, color: Colors.grey),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'User tidak menambahkan lokasi pada transaksi ini.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // ✏️ EDIT & DELETE BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPage(transaction: transaction),
                              ),
                            ).then((value) {
                              if (value == true) {
                                setState(() {
                                  _futureTransaction = _initializeFutureTransaction();
                                });
                                Navigator.pop(context, true);
                                // TAMBAHKAN SNACKBAR DI SINI
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Perubahan disimpan')),
                                );
                              }
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: mainColor,
                            side: BorderSide(color: mainColor),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _isDeleting ? null : _deleteTransaction,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isDeleting
                              ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                          )
                              : const Icon(Icons.delete_outline, size: 20),
                          label: const Text('Hapus'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 📄 TRANSACTION DETAILS
                    Text(
                      'Detail Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TAMBAHKAN FIELD NAMA DI SINI
                    _buildDetailCard(icon: Icons.title, title: 'Nama', value: transaction.category ?? '-'),
                    _buildDetailCard(icon: Icons.compare_arrows, title: 'Tipe', value: transaction.type ?? '-'),
                    _buildDetailCard(icon: Icons.attach_money, title: 'Jumlah', value: formatCurrency(amount, transaction.currencyCode)),
                    _buildDetailCard(icon: Icons.currency_exchange, title: 'Jumlah (IDR)', value: formatCurrency(totalInIDR, 'Rp')),
                    _buildDetailCard(icon: Icons.note, title: 'Catatan', value: transaction.note ?? '-'),
                    _buildDetailCard(icon: Icons.calendar_today, title: 'Tanggal', value: transaction.date ?? '-'),
                    if (transaction.locationId != null)
                      _buildDetailCard(icon: Icons.location_on, title: 'Lokasi', value: transaction.locationName ?? '-'),
                    _buildDetailCard(icon: Icons.language, title: 'Timezone', value: transaction.timeZone ?? '-'),
                    _buildDetailCard(icon: Icons.create, title: 'Dibuat pada', value: transaction.createdAt ?? '-'),
                    _buildDetailCard(icon: Icons.update, title: 'Diperbarui pada', value: transaction.updatedAt ?? '-'),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDetailCard({required IconData icon, required String title, required String value}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: mainColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}