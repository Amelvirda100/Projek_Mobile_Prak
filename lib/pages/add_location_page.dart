import 'package:budgetlisting/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddLocationPage extends StatefulWidget {
  @override
  _AddLocationPageState createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final MapController _mapController = MapController();
  final TextEditingController _locationNameController = TextEditingController();

  LatLng? _selectedLocation;
  LatLng? _initialLocation;
  bool _locationReady = false;
  late String _token;

  final Color mainColor = const Color.fromRGBO(97, 126, 140, 1.0);

  @override
  void initState() {
    super.initState();
    _loadToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserLocation();
    });
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token') ?? '';
    });
  }

  Future<void> _getUserLocation() async {
    try {
      Location location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locationData = await location.getLocation();
      if (locationData.latitude == null || locationData.longitude == null) return;

      final currentLatLng = LatLng(locationData.latitude!, locationData.longitude!);

      setState(() {
        _initialLocation = currentLatLng;
        _selectedLocation = currentLatLng;
        _locationReady = true;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _mapController.move(currentLatLng, 15.0);
        }
      });
    } catch (e) {
      debugPrint("Gagal mendapatkan lokasi pengguna: $e");
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedLocation = latlng;
    });
  }

  void _onSave() async {
    if (_selectedLocation == null || _locationNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih lokasi dan isi nama lokasi')),
      );
      return;
    }

    final locationService = TransactionAPI();
    final result = await locationService.addLocation(
      token: _token,
      name: _locationNameController.text,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );

    if (result['success']) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 3,
        iconTheme: const IconThemeData(color: Colors.white), // ✅ arrow putih
        title: const Text(
          'Tambah Lokasi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: _locationReady && _initialLocation != null
          ? SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      mapController: _mapController,
                      options: MapOptions(
                        center: _initialLocation,
                        zoom: 15.0,
                        maxZoom: 18.0,
                        minZoom: 3.0,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                          userAgentPackageName: 'com.example.app',
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 80,
                                height: 80,
                                point: _selectedLocation!,
                                builder: (ctx) => const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedLocation != null) ...[
                Text(
                  'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _locationNameController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Nama Lokasi',
                  hintText: 'Masukkan nama lokasi',
                  labelStyle: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  prefixIcon: const Icon(Icons.edit_location_alt, color: Colors.blueGrey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: mainColor, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Simpan Lokasi',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: _onSave,
                ),
              ),
            ],
                    ),
                  ),
          )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
