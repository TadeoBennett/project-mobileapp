import 'dart:async';

import 'package:cpi_app/Widgets/loading.dart';
import 'package:cpi_app/helpers/utility_functions.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:geolocator/geolocator.dart';

import '../models/user_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:get/get.dart';

import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

// import '../data/outlets.dart';
import '../models/outlet.dart';
import '../widgets/custom_marker.dart';
// import '../helpers/session.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedTileProvider extends TileProvider {
  CachedTileProvider();

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    print(getTileUrl(coords, options));

    return CachedNetworkImageProvider(
      getTileUrl(coords, options),

      //Now you can set options that determine how the image gets cached via whichever plugin you use.
    );
  }
}

//Stream Subscription stores change location subscription
StreamSubscription? stream;

final userLocationStreamProvider =
    StreamProvider.autoDispose<UserLocation>((ref) {
  //Instance of Location is used to get Location
  final location = Location();

  //StreamController is used to broadcast location changes
  final StreamController<UserLocation> _locationController =
      StreamController<UserLocation>.broadcast();

  //Requesting Permission to listen to location changes
  location.requestPermission().then((granted) {
    //checks if permission is granted
    if (granted == PermissionStatus.granted) {
      //subscription to location changes executed
      stream = location.onLocationChanged.listen((locationData) {
        // print('Location ${locationData.longitude}');

        //Emit change in Location!
        _locationController.add(UserLocation(
            latitude: locationData.latitude,
            longitude: locationData.longitude));
      }, onDone: () {
        print('On done');
        stream!.cancel();
      }, onError: (_) {
        print('An Error Occurred');
      });
    }
  }).catchError((error) {
    throw error;
  });

  return _locationController.stream;
});

class OutletMapScreen extends ConsumerStatefulWidget {
  const OutletMapScreen({Key? key}) : super(key: key);

  static const routeName = '/map';

  @override
  OutletMapScreenState createState() => OutletMapScreenState();
}

class OutletMapScreenState extends ConsumerState<OutletMapScreen> {
  final MapController mapController = MapController();

  LatLng? center;

  @override
  void initState() {
    UtilityFunctions().getCurrentLocation().then((value) {
      print("Center value:  $value");
      setState(() {
        center = LatLng(value["latitude"], value["longitude"]);
      });
    }).catchError((error) {
      setState(() {
        center = LatLng(17.2475, -88.7749); // Just Set BMP to Center if fails
      });
    });

    super.initState();
  }

  //Cleans Up the Location Subscription upon changing screen
  @override
  void dispose() {
    super.dispose();
    stream!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    //MAP BUILDING START

    int? storeId = ModalRoute.of(context)!.settings.arguments as int?;

    List<Marker> markers = [
      Marker(
        point: LatLng(17.2475, -88.7749),
        rotate: true,
        // rotateOrigin: Offset(),
        anchorPos: AnchorPos.align(AnchorAlign.top),
        width: 20,
        height: 20,
        builder: (context) => Icon(Icons.location_on),
      ),
    ];

    List<Outlet> outlets = ref.read(outletsProvider).getOutletsWithLocation();

    LatLng? mapCenter;
    String pageTitle;
    double mapZoom;

    if (storeId != null) {
      Outlet curOutlet = ref.read(outletsProvider).getOutletById(storeId);

      if ([null, 0, 0.0].contains(curOutlet.lat) != true &&
          [null, 0, 0.0].contains(curOutlet.long) != true) {
        mapCenter = LatLng(curOutlet.lat as double, curOutlet.long as double);
        pageTitle = "Map - ${curOutlet.estName}";
        mapZoom = 17;
      } else {
        pageTitle = "Map";
        mapCenter = center;
        mapZoom = 15.5;
      }
    } else {
      pageTitle = "Map";
      mapCenter = center;
      mapZoom = 15.5;
    }

    List<MonumentMarker>? outs = outlets
        .map(
          (outlet) => MonumentMarker(
            monument: Monument(
              lat: outlet.lat as double,
              long: outlet.long as double,
              outlet: outlet,
              focused: storeId == outlet.outletId,
            ),
          ),
        )
        .toList();

    // double innerScreenHeight = MediaQuery.of(context).size.height -
    //     (MediaQuery.of(context).padding.top + kToolbarHeight);

    final PopupController popupLayerController = PopupController();

    print("MAP CENTER: $mapCenter");

    //MAP BUILDING END

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          enableFeedback: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: mapCenter == null
          ? const Loading()
          : Container(
              // height: innerScreenHeight,
              child: Column(
              children: [
                Flexible(
                  child: FlutterMap(
                    options: MapOptions(
                        center: mapCenter,
                        zoom: mapZoom,
                        onTap: (x, Y) {
                          print("SSS");
                          popupLayerController.hideAllPopups();
                          print("llll");
                        }),
                    children: [
                      TileLayerWidget(
                        options: TileLayerOptions(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: <String>['a', 'b', 'c'],
                        ),
                      ),
                      PopupMarkerLayerWidget(
                        options: PopupMarkerLayerOptions(
                            popupController: popupLayerController,
                            markers: [...outs, ...showLiveLocation(ref)],
                            markerRotateAlignment:
                                PopupMarkerLayerOptions.rotationAlignmentFor(
                                    AnchorAlign.top),
                            popupBuilder:
                                (BuildContext context, Marker marker) {
                              if (marker is MonumentMarker) {
                                return MonumentMarkerPopup(
                                    monument: marker.monument);
                              }
                              return const Text('');
                            }),
                      ),
                    ],
                  ),
                )
              ],
            )),
    );
  }

  List<Marker> showLiveLocation(WidgetRef ref) {
    final stream = ref.watch(userLocationStreamProvider);
    return stream.when(
        data: (value) {
          return [
            Marker(
              builder: (ctx) => const Icon(
                Icons.circle_sharp,
                color: Colors.blue,
                size: 20,
              ),
              point:
                  LatLng(value.latitude as double, value.longitude as double),
              width: 10,
              height: 10,
            )
          ];
        },
        loading: () => [],
        // Marker(builder: (ctx) => const Text(''), point: LatLng(0, 0)),
        error: (error, _) {
          Navigator.of(context).pop();
          return [];
        });
  }
}
