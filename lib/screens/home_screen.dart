import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GoogleMapController _googleMapController;

  final Location _location = Location();
  LatLng? _currentLocationInfo;
  StreamSubscription? _streamLocationData;

  late Marker _marker;
  final List<LatLng> _latLngList = [];
  final Set<Polyline> _polyLineSet = {};

  bool isFollowing = true;

  @override
  void initState() {
    super.initState();
    fetchInitialLocation();
  }

  void fetchInitialLocation() async {
    final LocationData initialLocation = await _location.getLocation();
    setState(() {
      _currentLocationInfo = LatLng(initialLocation.latitude!, initialLocation.longitude!);
      updateMarkerInformation();
      updatePolylineInformation();
    });

    getCurrentLocation();
  }

  void getCurrentLocation() {
    _location.requestPermission();

    _location.hasPermission().then((value) {
      if (value == PermissionStatus.granted) {
        _location.changeSettings(interval: 10000);

        _streamLocationData =
            _location.onLocationChanged.listen((LocationData locationData) {
              setState(() {
                _currentLocationInfo = LatLng(locationData.latitude!, locationData.longitude!);
                updateMarkerInformation();
                updatePolylineInformation();

                if (isFollowing) {
                  _googleMapController
                      .animateCamera(CameraUpdate.newLatLng(_currentLocationInfo!));
                }
              });
            });
      }
    });
  }

  void updateMarkerInformation() {
    _marker = Marker(
      markerId: const MarkerId('current_location_marker_id'),
      position: _currentLocationInfo!,
      infoWindow: InfoWindow(
        title: 'My current location',
        snippet:
        'Lat: ${_currentLocationInfo!.latitude}, Lng: ${_currentLocationInfo!.longitude}',
      ),
      onTap: () {
        _googleMapController
            .showMarkerInfoWindow(const MarkerId('current_location_marker_id'));
      },
    );
  }

  void updatePolylineInformation() {
    _latLngList.add(_currentLocationInfo!);
    _polyLineSet.add(Polyline(
      polylineId: const PolylineId('polyline_list'),
      points: _latLngList,
      color: Colors.blue,
      width: 17,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Live Location Tracking', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepOrange,
        actions: [
          GestureDetector(
            onTap: () {
              isFollowing = !isFollowing;
              setState(() {
                getCurrentLocation();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2.0),
              child: const Icon(
                Icons.my_location_outlined,
                color: Colors.deepOrange,
              ),
            ),
          ),
        ],
      ),
      body: _currentLocationInfo == null
          ? loadingAndRefresh()
          : GoogleMap(
        compassEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _googleMapController = controller;
        },
        initialCameraPosition:
        CameraPosition(zoom: 14, target: _currentLocationInfo!),
        markers: {_marker},
        polylines: _polyLineSet,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }

  Center loadingAndRefresh() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Text("Fetching The Live Location..."),
           CircularProgressIndicator(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _streamLocationData?.cancel();
    super.dispose();
  }
}

