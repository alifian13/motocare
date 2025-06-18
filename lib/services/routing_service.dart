// lib/services/routing_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  /// titik [start] dan [end].
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    // URL untuk OSRM demo server.
    var url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var coordinates = data['routes'][0]['geometry']['coordinates'] as List;
        return coordinates
            .map((coord) => LatLng(coord[1] as double, coord[0] as double))
            .toList();
      } else {
        print('Error from OSRM API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception while fetching route: $e');
      return [];
    }
  }
}
