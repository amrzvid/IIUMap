import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iiumap/model/history_model.dart';
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
  final Completer<GoogleMapController> _googleMapController = Completer();
  final Location _locationController = Location();
  static const LatLng _centerIIUM =
      LatLng(3.2503284083090898, 101.7345085386681);
  LatLng? _currentPosition;
  final List<String> records = [];
  Set<Marker> _markers = {};
  String _type = 'All';

  Marker? _origin;
  Marker? _destination;
  Directions? _info;

  void _fetchLocation(String typeFilter) async {
    QuerySnapshot querySnapshot;
    if (typeFilter == 'All') {
      querySnapshot =
          await FirebaseFirestore.instance.collection('location').get();
    } else {
      querySnapshot = await FirebaseFirestore.instance
          .collection('location')
          .where('type', isEqualTo: typeFilter)
          .get();
    }

    setState(() {
      _markers = querySnapshot.docs.map((doc) {
        var location = doc.data() as Map<String, dynamic>;
        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(double.parse(location['latitude']),
              double.parse(location['longitude'])),
          infoWindow: InfoWindow(
              title: location['name'],
              snippet:
                  "Latitude: ${location['latitude']} Longitude: ${location['longitude']}"),
          icon: location['type'] == 'Mahallah'
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange)
              : location['type'] == 'Kuliyyah'
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue)
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueMagenta),
        );
      }).toSet();
    });
  }

  void _onChanged(String? value) {
    if (value != null) {
      setState(() {
        _type = value;
      });
      _fetchLocation(_type);
    }
  }

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
    _fetchLocation(_type);
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
                            builder: (context) => const WelcomeScreen(),
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
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                )
              : GoogleMap(
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  initialCameraPosition: const CameraPosition(
                    target: _centerIIUM,
                    zoom: 16.0,
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
                    ..._markers,
                  },
                  polylines: {
                    if (_info != null)
                      Polyline(
                          polylineId: const PolylineId('overview_polyline'),
                          color: Colors.purpleAccent,
                          width: 5,
                          points: _info!.polylinePoints
                              .map((e) => LatLng(e.latitude, e.longitude))
                              .toList()),
                  },
                  mapType: MapType.normal,
                  onMapCreated: (GoogleMapController controller) {
                    if (!_googleMapController.isCompleted) {
                      _googleMapController.complete(controller);
                    }
                  },
                  onLongPress: _addMarker,
                ),
          if (_info != null)
            Positioned(
              left: 10,
              top: 10.0,
              child: Container(
                height: 40.0,
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
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
                    ]),
                child: Text(
                  '${_info!.totalDistance}, ${_info!.totalDuration}',
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 100,
                height: 40,
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.grey,
                        offset: Offset(0, 2),
                        blurRadius: 6.0,
                      )
                    ],
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: DropdownButton<String>(
                    iconEnabledColor: Colors.blue,
                    underline: const SizedBox(),
                    value: _type,
                    icon: const Icon(Icons.arrow_drop_down),
                    iconSize: 20,
                    elevation: 8,
                    style: const TextStyle(color: Colors.black),
                    onChanged: _onChanged,
                    items: <String>[
                      'All',
                      'Mahallah',
                      'Kuliyyah',
                      'Others',
                      'None'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ap = Provider.of<AuthProvider>(context, listen: false);
          String userId = ap.getUserModel.uid; // Get the user ID

          // Check if a destination has been set
          if (_destination == null) {
            return;
          }

          // Use the destination marker's position as the destination name
          String destinationName = _destination!.position.toString();

          HistoryModel history = HistoryModel(
            historyId: '',
            uid: userId,
            location: destinationName, // Use the destination name here
            timeStamp: DateTime.now(),
          );

          await addHistoryToFirestore(
              history); // Store the history in Firestore

          setState(() {
            List<String> records =
                []; // Define the variable 'records' as an empty list
            records.add(
                destinationName); // Add the destination name to the local list
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.all(16),
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  color: Colors.green.withOpacity(0.8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Successfully saved!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    Text(
                      "Your visit has been saved to your history.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        tooltip: "Save your visit",
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue,
        shape: const CircleBorder(),
        child: const Icon(Icons.check),
      ),
    );
  }

  Future<void> _cameraToCurrentPosition(LatLng position) async {
    final GoogleMapController controller = await _googleMapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 16.0,
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

  void _addMarker(LatLng pos) async {
    if (_origin == null || (_origin != null && _destination != null)) {
      setState(() {
        _origin = Marker(
          markerId: const MarkerId('origin'),
          infoWindow: const InfoWindow(title: 'Origin'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: pos,
        );

        _destination = null;

        _info = null;
      });
    } else {
      setState(() {
        _destination = Marker(
          markerId: const MarkerId('destination'),
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarker,
          position: pos,
        );
      });

      final directions = await DirectionsRepository().getDirections(
          origin: _origin!.position, destination: _destination!.position);
      setState(() => _info = directions);
    }
  }
}
