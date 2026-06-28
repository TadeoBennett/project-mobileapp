import 'dart:async';

import 'package:cpi_app/Widgets/loading.dart';
import 'package:cpi_app/helpers/utility_functions.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:geolocator/geolocator.dart';

import '../models/user_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

import '../models/outlet.dart';
import '../widgets/custom_marker.dart';
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

StreamSubscription? stream;

final userLocationStreamProvider =
    StreamProvider.autoDispose<UserLocation>((ref) {
  final StreamController<UserLocation> locationController =
      StreamController<UserLocation>.broadcast();

  Geolocator.checkPermission().then((permission) async {
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      stream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).listen((position) {
        locationController.add(UserLocation(
            latitude: position.latitude, longitude: position.longitude));
      }, onDone: () {
        stream?.cancel();
      }, onError: (_) {
        print('An Error Occurred');
      });
    }
  }).catchError((error) {
    locationController.addError(error);
  });

  ref.onDispose(() {
    stream?.cancel();
    locationController.close();
  });

  return locationController.stream;
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
    stream?.cancel();
    super.dispose();
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
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: <String>['a', 'b', 'c'],
                          tileProvider: NetworkTileProvider(
                            headers: {
                              'User-Agent': 'CPI App (com.sib.cpi_app)',
                            },
                          ),
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
    final locationStream = ref.watch(userLocationStreamProvider);
    return locationStream.when(
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
        error: (error, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
          return [];
        });
  }
}
