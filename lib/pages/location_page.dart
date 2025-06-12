// Tambahan: Import
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgetlisting/models/location_model.dart';
import 'package:budgetlisting/services/location_service.dart';
import 'package:budgetlisting/pages/add_location_page.dart';
import 'package:budgetlisting/pages/edit_location_page.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final Color mainColor = const Color.fromRGBO(97, 126, 140, 1.0);
  List<Location> _locations = [];
  bool _isLoading = true;
  String? _error;
  late String _token;

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    await _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_token.isEmpty) {
        setState(() {
          _error = 'Token tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      final result = await LocationService().getAllLocations(_token);
      setState(() {
        _locations = result;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat lokasi: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToAddLocationPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddLocationPage()),
    );
    if (result == true) _fetchLocations();
  }

  Future<void> _navigateToEditLocationPage(Location location) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditLocationPage(location: location),
      ),
    );
    if (result == true) _fetchLocations();
  }

  Future<void> _confirmDeleteLocation(Location location) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Lokasi'),
        content: Text('Yakin ingin menghapus lokasi "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await LocationService().deleteLocation(
        token: _token,
        id: location.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );

      if (result['success']) {
        _fetchLocations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // ✅ Pusatkan judul
        backgroundColor: mainColor,
        elevation: 3,
        title: const Text(
          'Daftar Lokasi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600, // Lebih tebal dari normal
            color: Colors.white,          // Putih
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _navigateToAddLocationPage,
            icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.white, width: 1),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
          ),
        )
            : _locations.isEmpty
            ? const Center(
          child: Text(
            'Belum ada lokasi yang tersedia.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto', // atau ganti dengan font bagus lain
            ),
            textAlign: TextAlign.center,
          ),
        )

            : ListView.separated(
          itemCount: _locations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final loc = _locations[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                leading: const Icon(Icons.location_on,
                    color: Colors.blueGrey, size: 30),
                title: Text(
                  loc.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Lat: ${loc.latitude.toStringAsFixed(4)}\nLong: ${loc.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.grey),
                      onPressed: () => _navigateToEditLocationPage(loc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () =>
                          _confirmDeleteLocation(loc),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
