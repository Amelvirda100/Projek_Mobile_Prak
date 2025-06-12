import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:budgetlisting/models/location_model.dart';
import 'package:budgetlisting/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditLocationPage extends StatefulWidget {
  final Location location;

  const EditLocationPage({Key? key, required this.location}) : super(key: key);

  @override
  _EditLocationPageState createState() => _EditLocationPageState();
}

class _EditLocationPageState extends State<EditLocationPage> {
  final MapController _mapController = MapController();
  final TextEditingController _locationNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  LatLng? _selectedLocation;
  late String _token;

  final Color mainColor = const Color.fromRGBO(97, 126, 140, 1.0);

  @override
  void initState() {
    super.initState();
    _loadToken();
    _initializeLocation();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token') ?? '';
    });
  }

  void _initializeLocation() {
    _selectedLocation = LatLng(
      widget.location.latitude,
      widget.location.longitude,
    );
    _locationNameController.text = widget.location.name;
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedLocation = latlng;
    });
  }

  void _onUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await LocationService().updateLocation(
      token: _token,
      id: widget.location.id,
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Lokasi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: _selectedLocation == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
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
                        center: _selectedLocation,
                        zoom: 15.0,
                        maxZoom: 18.0,
                        minZoom: 3.0,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                          userAgentPackageName: 'com.example.app',
                        ),
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
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _locationNameController,
                  style: const TextStyle(fontSize: 15),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama lokasi wajib diisi';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Nama Lokasi',
                    hintText: 'Masukkan nama lokasi',
                    labelStyle: const TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: const Icon(Icons.edit_location_alt,
                        color: Colors.blueGrey),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: mainColor, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Update Lokasi',
                    style:
                    TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: _onUpdate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
