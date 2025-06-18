import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../utils/date_formatter.dart';
import '../models/trip_model.dart';
import '../services/routing_service.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final RoutingService _routingService = RoutingService();
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoute() async {
    if (widget.trip.startLatitude != null &&
        widget.trip.startLongitude != null &&
        widget.trip.endLatitude != null &&
        widget.trip.endLongitude != null) {
      final start =
          LatLng(widget.trip.startLatitude!, widget.trip.startLongitude!);
      final end = LatLng(widget.trip.endLatitude!, widget.trip.endLongitude!);

      try {
        final route = await _routingService.getRoute(start, end);
        if (mounted) {
          if (route.isNotEmpty) {
            setState(() {
              _routePoints = route;
              _isLoading = false;
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(_routePoints),
                  padding: const EdgeInsets.all(50.0),
                ),
              );
            });
          } else {
            setState(() {
              _errorMessage = 'Gagal mendapatkan data rute dari server.';
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Terjadi kesalahan saat memuat rute: $e';
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'Data koordinat perjalanan tidak lengkap.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Perjalanan'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Bagian Peta
          Expanded(
            flex: 3,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(_errorMessage, textAlign: TextAlign.center),
                      ))
                    : _buildMap(),
          ),
          // Bagian Detail Teks
          Expanded(
            flex: 2,
            child: _buildDetailsCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _routePoints.isNotEmpty
            ? LatLng((_routePoints.first.latitude + _routePoints.last.latitude) / 2,
                       (_routePoints.first.longitude + _routePoints.last.longitude) / 2)
            : const LatLng(-7.7956, 110.3695),
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          // Aktifkan semua interaksi (zoom, geser)
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.motocare',
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 5.0,
                color: Colors.blue.shade700,
              ),
            ],
          ),
        if (_routePoints.isNotEmpty)
          MarkerLayer(
            markers: [
              // Marker Start
              Marker(
                width: 80.0,
                height: 80.0,
                point: _routePoints.first,
                child:
                    const Icon(Icons.location_on, color: Colors.green, size: 40),
              ),
              // Marker End
              Marker(
                width: 80.0,
                height: 80.0,
                point: _routePoints.last,
                child: const Icon(Icons.flag, color: Colors.red, size: 40),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Perjalanan pada:',
              style: Theme.of(context).textTheme.titleMedium),
          Text(
            DateFormatter.toWibString(widget.trip.startTime, format: 'EEEE, dd MMMM HH:mm'),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(context, Icons.route_outlined, 'Jarak Tempuh',
                      '${widget.trip.distanceKm.toStringAsFixed(2)} km'),
                  const Divider(height: 20),
                  _buildDetailRow(context, Icons.place_outlined, 'Dari',
                      widget.trip.startAddress ?? 'Tidak diketahui'),
                  const Divider(height: 20),
                  _buildDetailRow(context, Icons.flag_outlined, 'Ke',
                      widget.trip.endAddress ?? 'Tidak diketahui'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
