import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LocationData? _currentLocation;
  final Location _location = Location();
  final List<LatLng> _polylineCoordinates = [];
  final Set<Polyline> _polylines = {};
  Marker? _marker;
  LatLng? _previousLatLng;
  bool isTracking = false;
  var _mapType = MapType.normal;
  bool _initialLocationAcquired = false;
  bool _hasLocationPermission = true;

  @override
  void initState() {
    super.initState();
    _initLocationService();
  }

  void _initLocationService() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }
     PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _hasLocationPermission = false;
        setState(() {});
        return;
      }
    }
    _hasLocationPermission = true;
    setState(() {});

    _location.onLocationChanged.listen((LocationData locationData) {
      _currentLocation = locationData;
      if (!_initialLocationAcquired) {
        _initialLocationAcquired = true;
        _mapController!.animateCamera(CameraUpdate.newLatLng(
          LatLng(locationData.latitude!, locationData.longitude!),
        ));
      }
      _updateMap();
    });
  }
  void _updateMap() {
    if (_currentLocation != null && _mapController != null) {
      final newLatLng =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);

      if (isTracking) {
        if (_marker != null && _previousLatLng != null) {
          _polylines.add(Polyline(
            polylineId: const PolylineId("polyline"),
            color: Colors.blue,
            points: [..._polylineCoordinates, newLatLng],
          ));
        }
        _polylineCoordinates.add(newLatLng);
      }

      _marker = Marker(
        markerId: const MarkerId("marker"),
        position: newLatLng,
        infoWindow: InfoWindow(
            title: "My Current Location",
            snippet: "${newLatLng.latitude} , ${newLatLng.longitude}"),
      );

      _previousLatLng = newLatLng;
      _mapController!.animateCamera(CameraUpdate.newLatLng(newLatLng));
    }
    setState(() {});
  }

  void _startTracking() {
    _polylineCoordinates.clear();
    _polylines.clear();
    _previousLatLng = null;

    isTracking = true;
    Fluttertoast.showToast(msg: "Tracking Started");
    setState(() {});
  }

  void _stopTracking() {
    isTracking = false;
    Fluttertoast.showToast(msg: "Tracking Stopped");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if(!_hasLocationPermission){
      return  Scaffold(
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Location Denied"),
            ElevatedButton(onPressed: _initLocationService, child: const Text("Request Permission"))
          ],
        ),),
      );
    }  else{
      return Scaffold(
        appBar: AppBar(
          title: const Text("Real-Time Location Tracker"),
          actions: [
            TextButton(
              onPressed: () {
                _stopTracking();
                _polylineCoordinates.clear();
                _polylines.clear();
                Fluttertoast.showToast(msg: 'Tracking Cleared');
                setState(() {});
              },
              child: const Text(
                "Clear Tracking",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Visibility(
          visible: _initialLocationAcquired,
          replacement: const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Text("Getting Your Current Location!")
            ],
          ),),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition:
                const CameraPosition(target: LatLng(0, 0), zoom: 15),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: _marker != null ? <Marker>{_marker!} : <Marker>{},
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: _mapType,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _mapType = (_mapType == MapType.normal) ? MapType.satellite : MapType.normal;
                  });
                },
                child: Text(_mapType == MapType.normal ? "Normal" : "Satellite"),
              ),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton.extended(
              onPressed: isTracking ? _stopTracking : _startTracking,
              label: Column(
                children: [
                  Text(isTracking ? "Stop" : "Start"),
                  const Text("Tracking"),
                ],
              ),
            ),
          ],
        ),
      );
    }

  }
}
