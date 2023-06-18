import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

import '../../Models/trip.dart';
import '../../widgets/progress_dialog.dart';

class MyWidget extends StatefulWidget {
  final Trip trip;

  @override
  _MyWidgetState createState() => _MyWidgetState();

  const MyWidget({super.key, required this.trip});
}

class _MyWidgetState extends State<MyWidget> {
  late final TextEditingController _tripNameController;
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;
  bool _trackingActive = false;
  double _totalDistance = 0.0;
  Position? _destination;
  Timer? _simulationTimer;
  double _costPerMeter = 0.1; // 0.1 birr per meter
  double _costPerMinute = 0.5; // 0.5 birr minute
  double _totalCost = 0.0;
  DateTime? _startTime;
  late final GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  Set<Polyline> _polylines = {};
  bool _isEnded = false;
  List<Object?> seats = [];
  List<String> userIDs = [];
  bool isLoading = false;

  Future<void> _createPolylines() async {
    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> polylineCoordinates = [];

    PointLatLng startLatLng =
        PointLatLng(_lastPosition!.latitude, _lastPosition!.longitude);
    PointLatLng destinationLatLng =
        PointLatLng(_destination!.latitude, _destination!.longitude);
    Future.delayed(Duration.zero, () {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext c) {
            return ProgressDialog(
              message: "Processing, Please wait...",
            );
          });
    });
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyDvCw3bdrvlUbjoSsW8BHYqyWNxxhTuIiY',
      startLatLng,
      destinationLatLng,
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    setState(() {
      _polylines.add(Polyline(
        polylineId: const PolylineId('polyline'),
        color: Colors.blue,
        points: polylineCoordinates,
      ));
    });
    Navigator.pop(context);
  }

  @override
 void initState() {
    super.initState();
    _getCurrentLocation().then((Position? position) {
      if (position != null) {
        _currentPosition = position;
        _mapController.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude), 16));

        _lastPosition = position;
        _destination = Position(
            latitude: double.parse(widget.trip.dropOffLatPos),
            longitude: double.parse(widget.trip.dropOffLongPos),
            altitude: 0,
            accuracy: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            timestamp: DateTime.now());

        _createPolylines();
      }
    });
    getUserIDs();

    FirebaseDatabase.instance
        .ref("trips")
        .child(widget.trip.tripID)
        .update({"accumulatedCost": '0'});

    print("_destination: $_destination");
    FirebaseDatabase.instance
        .ref("trips")
        .child(widget.trip.tripID)
        .update({"droppedOffPassengers": "0"});

    _future = Future.delayed(const Duration(seconds: 2), () => true);
  }
  Future<void> getUserIDs() async {
    final ref = FirebaseDatabase.instance.ref();
    final snapshot =
        await ref.child('trips/${widget.trip.tripID}/passengerIDs').get();
    if (snapshot.exists) {
      seats = snapshot.value as List<Object?>? ?? [];
    } else {
      const AlertDialog(semanticLabel: 'No data available.');
    }

    for(var v in seats){
      if(v.toString() != ''){
        userIDs.add(v.toString());
        print(v.toString());
      }
    }

  }
  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _tripNameController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  void _startTracking() {
    setState(() {
      _trackingActive = true;
    });
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        if (_lastPosition != null) {
          double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          _totalDistance += distance;
        }
        _lastPosition = position;
      });
    });
  }

  Future<void> _endTracking() async {
    setState(() {
      _isEnded = true;
    });
    for(var v in userIDs){
      String rID = v + widget.trip.tripID;
      FirebaseDatabase.instance
          .ref("requests")
          .child(rID)
          .update({"status": 'finished'});
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          title: const Text('Fare Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Total Fare: ' ),
            Text(_totalCost.toStringAsPrecision(2) + ' birr',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    FirebaseDatabase.instance
        .ref("trips")
        .child(widget.trip.tripID)
        .update({"status": "finished"});
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    // Cancel the Timer used for simulating movement
    _simulationTimer?.cancel();
    _simulationTimer = null;

    final CollectionReference statusCollection =
        FirebaseFirestore.instance.collection('tripStatus');

    final DocumentReference newStatusRef = await statusCollection.add({
      'title': 'Trip ended',
      'description': 'The trip has ended rate or pay the driver online',
    });
    //final CollectionReference statusCollection = FirebaseFirestore.instance.collection('trip')
  }

  void _startTrackingSimulation() {
    FirebaseDatabase.instance
        .ref("trips")
        .child(widget.trip.tripID)
        .update({"status": "in progress"});

    print("_destination: $_destination");
    int numberOfIds = int.parse(widget.trip.passengers[0]) -
        int.parse(widget.trip.availableSeats);
    List<String> passengerIDs =
        List.filled(numberOfIds, ''); // initialize the list with a fixed size
    List<Future> futures =
        []; // create a list to store the futures returned by the onValue listeners
    for (int i = 0; i < numberOfIds; i++) {
      DatabaseReference starCountRef = FirebaseDatabase.instance
          .ref('trips/${widget.trip.tripID}/passengerIDs/${i.toString()}');
      futures.add(starCountRef.onValue.first.then((event) {
        final data = event.snapshot.value;
        passengerIDs[i] = data
            .toString(); // update the element in the list at the correct index
      }));
    }
    Future.wait(futures).then((_) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      firestore
          .collection('trips') // specify the collection name
          .doc(widget.trip.tripID) // specify the document ID
          .set({
            'passengerIDs': passengerIDs
            // specify the name of the array field and the list of passenger IDs
          })
          .then((value) => print("Data written to Firestore"))
          .catchError(
              (error) => print("Failed to write data to Firestore: $error"));
    });
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_lastPosition != null && _destination != null) {
        LatLng lastPositionLatLng =
            LatLng(_lastPosition!.latitude, _lastPosition!.longitude);
        double distance = Geolocator.distanceBetween(
          lastPositionLatLng.latitude,
          lastPositionLatLng.longitude,
          _destination!.latitude,
          _destination!.longitude,
        );
        print("distance: $distance");

        if (distance < 100) {
          timer.cancel();
          return;
        }
        double bearing = Geolocator.bearingBetween(
          lastPositionLatLng.latitude,
          lastPositionLatLng.longitude,
          _destination!.latitude,
          _destination!.longitude,
        );
        double speed = 5; // 5 meters per second

        double distanceToTravel = speed;
        if (distanceToTravel > distance) {
          distanceToTravel = distance;
        }
        double lat = lastPositionLatLng.latitude +
            (distanceToTravel / 111320) * cos(bearing * pi / 180.0);
        double lng = lastPositionLatLng.longitude +
            (distanceToTravel /
                    (111320 * cos(lastPositionLatLng.latitude * pi / 180.0))) *
                sin(bearing * pi / 180.0);
        setState(() {
          LatLng newPositionLatLng = LatLng(lat, lng);
          _trackingActive = true;
          _lastPosition = Position(
              latitude: lat,
              longitude: lng,
              altitude: 0,
              accuracy: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              timestamp: DateTime.now());
          _mapController
              .animateCamera(CameraUpdate.newLatLng(newPositionLatLng));
          _addMarker(newPositionLatLng);

          if (_startTime == null) {
            _startTime = DateTime.now();
          }
          if (_lastPosition != null && _trackingActive) {
            double newDistance = Geolocator.distanceBetween(
              lastPositionLatLng.latitude,
              lastPositionLatLng.longitude,
              newPositionLatLng.latitude,
              newPositionLatLng.longitude,
            );
            print("New distance: $newDistance");
            _totalDistance += newDistance;
            print("Total distance: $_totalDistance");
            print("Last Position: $_lastPosition");
            int totalTimeInMinutes =
                DateTime.now().difference(_startTime!).inMinutes;
            _totalCost = (_totalDistance * _costPerMeter) +
                (totalTimeInMinutes * _costPerMinute);
            FirebaseDatabase.instance
                .ref("trips")
                .child(widget.trip.tripID)
                .update({"fare": _totalCost.toString()});
          }
        });
      }
    });
  }

  Marker _marker = const Marker(
    markerId: MarkerId('user'),
    position: LatLng(0, 0),
  );

  void _addMarker(LatLng position) async {
    final Uint8List markerIcon = await getBytesFromAsset('images/car.png', 50);
    final BitmapDescriptor customIcon = BitmapDescriptor.fromBytes(markerIcon);

    double rotation = 0.0;
    if (_marker.position != const LatLng(0, 0)) {
      rotation = getMarkerRotation(_marker.position.latitude,
          _marker.position.longitude, position.latitude, position.longitude);
    }

    _marker = Marker(
      markerId: const MarkerId('user'),
      position: position,
      icon: customIcon,
      rotation: rotation,
    );

    setState(() {
      _markers.clear();
      _markers.add(_marker);
    });
  }

  double getMarkerRotation(
      double startLat, double startLng, double endLat, double endLng) {
    final double bearing = atan2(
        sin(endLng - startLng) * cos(endLat),
        cos(startLat) * sin(endLat) -
            sin(startLat) * cos(endLat) * cos(endLng - startLng));
    return bearing * 180 / pi;
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui
        .instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  late String passengers;

  @override
  Widget build(BuildContext context) {
    String? currentSelectedVehicle = 'Car';
    String currentSelectedPassenger = '1 Passenger';
    Map<String, List<String>> dropdownItemsMap = {
      'Car': ['1 Passenger', '2 Passengers', '3 Passengers', '4 Passengers'],
      'Van': [
        '1 Passenger',
        '2 Passengers',
        '3 Passengers',
        '4 Passengers',
        '5 Passengers',
        '6 Passengers',
        '7 Passengers',
        '8 Passengers',
        '9 Passengers',
        '10 Passengers',
        '11 Passengers',
        '12 Passengers'
      ],
      'Mini-Van': [
        '1 Passenger',
        '2 Passengers',
        '3 Passengers',
        '4 Passengers',
        '5 Passengers',
        '6 Passengers'
      ]
    };
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Colors.greenAccent,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top:4.0),
          child: Text(
            'Start Trip',
            style: TextStyle(
                color: Colors.black),
          ),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  child: Text('Passengers'),
                  value: 'option1',
                ),
                const PopupMenuItem(
                  child: Text('Cancel Trip'),
                  value: 'option2',
                ),
              ];
            },
            onSelected: (value) {
              if (value == 'option1') {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return drawUsers();
                  },
                );
              } else if (value == 'option2') {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Cancel Trip'),
                      actions: [
                        TextButton(
                          onPressed: () => cancelTrip(context),
                          child: const Text('OK'),
                        )
                      ],
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: _currentPosition != null
                    ? CameraPosition(
                        target: LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude),
                        zoom: 16,
                      )
                    : const CameraPosition(
                        target: LatLng(0, 0),
                        zoom: 16,
                      ),
                markers: _markers,
                polylines: _polylines,
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.0),
                  topRight: Radius.circular(18.0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent,
                  blurRadius: 10.0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_destination != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.pin_drop,
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.trip.destinationLocation}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(
                  height: 25,
                ),
              //  Text(userIDs[0]),
              //  Text((userIDs[0] == 'rK4BBoQjT5c7eK34FrlgOfQKr1K3') ? 'true' : 'false'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (!_trackingActive)
                      Row(
                        children: [

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              fixedSize: const Size(100, 100),
                              shape: const CircleBorder(),
                            ),
                            onPressed:_startTrackingSimulation,
                            child: const Text(
                              'Start',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_trackingActive)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                  width: 200,
                                  // set the width of the dropdown button
                                  child: DropdownButtonFormField<String>(
                                    value: currentSelectedPassenger,
                                    items: dropdownItemsMap[
                                            currentSelectedVehicle]!
                                        .map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        currentSelectedPassenger = newValue!;
                                        this.passengers = newValue;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: "Select passengers",
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                    ),
                                    hint: const Text('Select Passengers'),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select passengers';
                                      }
                                      return null;
                                    },
                                  )),

                              // add vertical space between the dropdown button and the ElevatedButton
                              SizedBox(
                                width: 200,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.greenAccent,
                                  ),
                                  onPressed: () {
                                    //String passengers = currentSelectedPassenger;
                                    _dropOffPassenger(passengers[0], context);
                                  }, // _endTracking,
                                  child: const Text(
                                    'Drop Off',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16.0),
                          // add horizontal space between the two columns
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              fixedSize: const Size(100, 100),
                              shape: const CircleBorder(),
                              primary: Colors.redAccent,
                            ),
                            onPressed: _isEnded ? null : _endTracking,
                            child: Text(
                              _isEnded ? 'Ended' : 'End',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                /*if (_lastPosition != null)
                  Text(
                    'Last Position: ${_lastPosition!.latitude}, ${_lastPosition!
                        .longitude}',
                  ),*/
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_run_rounded,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(_totalDistance / 1000).toStringAsFixed(2)} kms',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_totalCost.toStringAsFixed(2)} br.',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_startTime != null ? DateTime.now().difference(_startTime!).inMinutes : 0} min',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  late Future<bool> _future;

  Future<void> _dropOffPassenger(String n, BuildContext context) async {
    String seat = "", availableSeats = "";
    String totalAccumulatedCost = '', droppedOffPassengers = '';

    final ref = FirebaseDatabase.instance.ref();
    final snapshot =
        await ref.child('trips/${widget.trip.tripID}/passengers').get();
    if (snapshot.exists) {
      seat = snapshot.value.toString()[0];
    } else {
      const AlertDialog(semanticLabel: 'No data available.');
    }

    final snapshot2 =
        await ref.child('trips/${widget.trip.tripID}/availableSeats').get();
    if (snapshot2.exists) {
      availableSeats = snapshot2.value.toString()[0];
    } else {
      const AlertDialog(semanticLabel: 'No data available.');
    }

    final snapshot3 = await ref
        .child('trips/${widget.trip.tripID}/droppedOffPassengers')
        .get();
    if (snapshot3.exists) {
      droppedOffPassengers = snapshot3.value.toString()[0];
    } else {
      const AlertDialog(semanticLabel: 'No data available.');
    }

    final snapshot4 =
        await ref.child('trips/${widget.trip.tripID}/accumulatedCost').get();
    if (snapshot4.exists) {
      totalAccumulatedCost = snapshot4.value.toString()[0];
    } else {
      const AlertDialog(semanticLabel: 'No data available.');
    }
    int totalSeats = int.parse(seat);
    int remainingSeats = int.parse(availableSeats);
    int reservedSeats = totalSeats - remainingSeats;
    int droppedPassengers = int.parse(droppedOffPassengers);
    double accumulatedCost = double.parse(totalAccumulatedCost);

    //String reservedSeats = (int.parse(seat) - int.parse(availableSeats)).toString();
    print('number: ' + n);
    print(droppedPassengers);
    print(accumulatedCost);
    print(totalSeats);

    //reservedSeats = (int.parse(totalSeats.toString()) - int.parse(remainingSeats)).toString();
    print('reservedSeats: ' + reservedSeats.toString());
    if (reservedSeats > droppedPassengers && (reservedSeats - droppedPassengers) >= int.parse(n)) {
      double fare =
          (_totalCost - accumulatedCost) / (reservedSeats - droppedPassengers);
      print('fare: ' + fare.toString());
      accumulatedCost = fare * int.parse(n);
      FirebaseDatabase.instance
          .ref("trips")
          .child(widget.trip.tripID)
          .update({"accumulatedCost": accumulatedCost.toString()});

      FirebaseDatabase.instance.ref("trips").child(widget.trip.tripID).update({
        "droppedOffPassengers":
            (int.parse(droppedOffPassengers.toString()) + int.parse(n))
                .toString()
      });

      return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            title: const Text('Fare Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fare: ' + fare.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text('Accumulated Fare: ' + accumulatedCost.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text('Total Fare: ' + _totalCost.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            title: const Text('Fare Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Remaining passengers are less than the specified drop off amount!'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
 drawUsers()=>Container(
   height: 100,
   child: AlertDialog(
     contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
     title: const Text('Passengers'),
     content: Column(
       mainAxisSize: MainAxisSize.min,
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Expanded(
           child: ListView.builder(
             itemCount: userIDs.length,
             itemBuilder: (context, index) {
               return buildUser(index);
             },
           ),
         ),
       ],
     ),
     actions: [
       TextButton(
         onPressed: () {
           Navigator.of(context).pop();
         },
         child: const Text('OK'),
       ),
     ],
   ),
 );

  final userRef = FirebaseDatabase.instance.ref('users');
  buildUser(int index) => StreamBuilder(
    stream: userRef.child(userIDs[index]).onValue,
    builder: (context, AsyncSnapshot snapshot) {

      if (!snapshot.hasData ||
          snapshot.data?.snapshot?.value == null) {
        return const Text("No usesrs");
      } else {
        Map<dynamic, dynamic> user = snapshot.data.snapshot.value;
        return buildUserData(index, user);
      }
    },
  );

  buildUserData(int index, Map<dynamic, dynamic> user) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(
              user['userImage'],
            ),
            radius: 25,
          ),
          Text(user['name']),
          IconButton(
            onPressed: () {
              //requestRide(trips[index]);
            },
            icon: const Icon(
              Icons.call,
              size: 30,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
      const Divider(),
    ],
  );

  cancelTrip(BuildContext context) {
    FirebaseDatabase.instance
        .ref("trips")
        .child(widget.trip.tripID)
        .update({"status": "cancelled"});
    Fluttertoast.showToast(msg: "Trip Cancelled");
    Navigator.of(context).pop();
  }
}
