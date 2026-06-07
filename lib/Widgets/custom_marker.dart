import 'package:cpi_app/models/outlet.dart';
import 'package:cpi_app/screens/outlet_assignments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Monument {
  static const double size = 35;

  Monument(
      {required this.outlet,
      required this.focused,
      required this.lat,
      required this.long});

  final Outlet outlet;
  final double lat;
  final double long;
  final bool focused;
}

class MonumentMarker extends Marker {
  MonumentMarker({required this.monument})
      : super(
          anchorPos: AnchorPos.align(AnchorAlign.top),
          height: Monument.size,
          width: Monument.size,
          point: LatLng(monument.lat, monument.long),
          builder: (BuildContext ctx) => Icon(
            Icons.location_pin,
            color: monument.focused ? Colors.amber : Colors.teal,
            size: 35,
          ),
        );

  final Monument monument;
}

class MonumentMarkerPopup extends StatelessWidget {
  const MonumentMarkerPopup({required this.monument});

  final Monument monument;

  @override
  Widget build(BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          width: 200,
          margin: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                label: Container(
                  child: Text(monument.outlet.estName),
                ),
                icon: const Icon(Icons.store),
                onPressed: () {
                  Navigator.of(context).popAndPushNamed(
                      OutletAssignmentsScreen.routeName,
                      arguments: monument.outlet.outletId);
                },
              ),
              const SizedBox(height: 1),
              Text('${monument.lat}, ${monument.long}'),
            ],
          ),
        ));
  }
}
