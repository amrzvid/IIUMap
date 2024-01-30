import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_iiumap/provider/auth_provider.dart';
import 'package:flutter_iiumap/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_iiumap/model/directions_model.dart';
import 'package:flutter_iiumap/provider/directions_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final Completer<GoogleMapController> _googleMapController = Completer();
  Location _locationController = Location();
  static const LatLng _centerIIUM =
      LatLng(3.2503284083090898, 101.7345085386681);
  LatLng? _currentPosition = null;

  Marker? _origin;
  Marker? _destination;
  Directions? _info;

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("IIUMap"),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
              onPressed: () async {
                ap.signOut().then(
                      (value) => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WelcomeScreen(),
                          ),
                          (route) => false),
                    );
              },
              icon: const Icon(Icons.logout),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.white),
              )),

              
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          _currentPosition == null
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : GoogleMap(
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  initialCameraPosition: const CameraPosition(
                    target: _centerIIUM,
                    zoom: 15.0,
                  ),
                  markers: {
                    if (_origin != null) _origin!,
                    if (_destination != null) _destination!,
                    Marker(
                      markerId: const MarkerId("_userLocation"),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure),
                      position: _currentPosition!,
                    ),
                  },
                  polylines: {
                  if (_info != null)
                    Polyline(
                      polylineId: const PolylineId('overview_polyline'),
                      color: Colors.purpleAccent,
                      width: 5,
                      points: _info!.polylinePoints
                        .map((e) => LatLng(e.latitude, e.longitude))
                        .toList()
                    ),
                  },
                  mapType: MapType.normal,
                  onMapCreated: (GoogleMapController controller) {
                    if (!_googleMapController.isCompleted) {
                      _googleMapController.complete(controller);
                    }
                  },
                  onLongPress: _addMarker,
                ),

                if(_info != null)
                  Positioned(
                    top: 20.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellowAccent,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 6.0,
                          )
                        ]
                      ), 
                      child: Text(
                        '${_info!.totalDistance}, ${_info!.totalDuration}',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )

        ],
      ),

      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.white,
      //   foregroundColor: Colors.black,
        
      //   onPressed: () => _googleMapController.animateCamera(
      //     _info != null
      //     ? CameraUpdate.newLatLngBounds(_info!.bounds, 100.0)
      //     : CameraUpdate.newCameraPosition(_initialCameraPosition),
      //   ),
      //   child: const Icon(Icons.center_focus_strong),
      // ),

            
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: "Search for a place",
        child: const Icon(Icons.search),
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue,
        shape: CircleBorder(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.blue.shade50,
        unselectedItemColor: Colors.blue.shade900,
        showUnselectedLabels: false,
        selectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "LiveTracker",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Future<void> _cameraToCurrentPosition(LatLng position) async {
    final GoogleMapController controller = await _googleMapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 15.0,
        ),
      ),
    );
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _cameraToCurrentPosition(_currentPosition!);
        });
      }
    });
  }

  void _addMarker(LatLng pos) async{
    if(_origin == null || (_origin != null && _destination != null)) {
      setState(() {
        _origin = Marker(
          markerId: const MarkerId('origin'),
          infoWindow: const InfoWindow(title: 'Origin'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: pos,
        );

        _destination = null;

        _info = null;
      });
    }else {
      setState(() {
        _destination = Marker(
          markerId: const MarkerId('destination'),
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: pos, 
        );
      });

      final directions = await DirectionsRepository()
        .getDirections(origin: _origin!.position, destination: _destination!.position);
      setState(()=> _info = directions);
    }
  }
}
