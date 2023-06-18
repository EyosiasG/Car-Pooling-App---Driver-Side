import 'dart:math';

import 'package:car_pool_driver/Constants/widgets/loading.dart';
import 'package:car_pool_driver/config_map.dart';
import 'package:car_pool_driver/global/global.dart';
import 'package:car_pool_driver/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:car_pool_driver/Constants/styles/colors.dart';
import 'package:car_pool_driver/Views/data%20handler/app_data.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../Constants/widgets/toast.dart';
import '../../widgets/progress_dialog.dart';
import '../assistants/assistant_methods.dart';
import '../trips/searchPickUp.dart';
import '../trips/search_screen.dart';

class Dashboard extends StatefulWidget {
  static const String idScreen = "dashboard";

  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  static const String idScreen = "dashboard";
  User? currentUser;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newgoogleMapController;
  static const CameraPosition _kGooglePlex =
  CameraPosition(target: LatLng(9.1450, 40.4897), zoom: 1);

  List<LatLng> pLineCoordinates = [];

  Set<Polyline> polylineSet = {};

  late Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingMap = 0;

  String? price;

  TextEditingController pickUpLocationController = TextEditingController();
  TextEditingController destinationLocationController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
  TextEditingController destinationLatitudeController = TextEditingController();
  TextEditingController destinationLongitudeController =
  TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController estimatedCostController = TextEditingController();
  Map<String, List<String>> dropdownMap = {
    'Car': ['1 Passenger', '2 Passengers', '3 Passengers', '4 Passengers'],
    'Van': [
      '1 Passenger', '2 Passengers', '3 Passengers', '4 Passengers',
      '5 Passengers', '6 Passengers', '7 Passengers', '8 Passengers',
      '9 Passengers', '10 Passengers', '11 Passengers', '12 Passengers'
    ],
    'MiniVan': ['1 Passenger', '2 Passengers', '3 Passengers', '4 Passengers', '5 Passengers', '6 Passengers', '7 Passengers']
  };

  String currentSelectedValue = '';
  List<String> dropdownItems = [];
  String? carType;


  late String passengers;
  final _formKey = GlobalKey<FormState>();
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    DatabaseReference starCountRef =
    FirebaseDatabase.instance.ref('drivers/${currentFirebaseUser!.uid}/car_type');
    starCountRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value.toString();
      carType = data;
      print("status: " + data.toString());
    });
    String currentSelectedValue = 'Car';
    dropdownItems = dropdownMap['Car']!;
  }

  void locatePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
    CameraPosition(target: latLngPosition, zoom: 20.0);
    newgoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    // ignore: use_build_context_synchronously
    String address =
    // ignore: use_build_context_synchronously
    await AssistantMethods.searchCoordinateAddress(position, context);
  }

  @override
  Widget build(BuildContext context) {
    String? pickUpLocation =
        Provider.of<AppData>(context).pickUpLocation?.placeName;
    pickUpLocationController.text = (pickUpLocation.toString() == 'null')
        ? 'Retreiving Location...'
        : pickUpLocation.toString();
    String? destination =
        Provider.of<AppData>(context).dropOffLocation?.placeName;
    destinationLocationController.text = (destination.toString() == 'null')
        ? 'Enter Destination'
        : destination.toString();
    double? locationLatitude =
        Provider.of<AppData>(context).pickUpLocation?.latitude;
    latitudeController.text = locationLatitude.toString();
    double? locationLongitude =
        Provider.of<AppData>(context).pickUpLocation?.longitude;
    longitudeController.text = locationLongitude.toString();
    double? destinationLatitude =
        Provider.of<AppData>(context).dropOffLocation?.latitude;
    destinationLatitudeController.text = destinationLatitude.toString();
    double? destinationLongitude =
        Provider.of<AppData>(context).dropOffLocation?.longitude;
    destinationLongitudeController.text = destinationLongitude.toString();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingMap),
            myLocationEnabled: true,
            polylines: polylineSet,
            zoomGesturesEnabled: true,
            markers: markersSet,
            circles: circlesSet,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newgoogleMapController = controller;
              setState(() {
                bottomPaddingMap = 300.0;
              });
              locatePosition();
            },
          ),
          Positioned(
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: Container(
                height: 250,
                decoration: const BoxDecoration(
                  color: ColorsConst.white,
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
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Row(
                        children: <Widget>[
                          Image.asset(
                            "images/PickUpDestination.png",
                            width: 20,
                            height: 160,
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 10.0, right: 15.0),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller:
                                    pickUpLocationController,
                                    decoration: const InputDecoration(

                                        enabledBorder:
                                        UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors
                                                  .greenAccent),
                                        ),
                                        focusedBorder:
                                        UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors
                                                    .greenAccent)),
                                        labelText: "Pick-Up",
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        )),

                                    style: const TextStyle(
                                        fontSize: 14.0),
                                    readOnly: true,
                                    onTap: () async {
                                      var res = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: ((context) =>
                                              const SearchPickUpScreen())));
                                      if (res ==
                                          "obtainDirection") {
                                        await getPlaceDirection();
                                      }
                                    },
                                  ),
                                  const SizedBox(
                                    height: 6.0,
                                  ),
                                  TextFormField(
                                    controller: destinationLocationController,
                                    decoration: const InputDecoration(
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.greenAccent),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.greenAccent)),
                                        labelText: 'Drop-Off',
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        )),
                                    style: const TextStyle(fontSize: 14.0),
                                    readOnly: true,
                                    onTap: () async {
                                      if (pickUpLocationController.text
                                          .toString() ==
                                          'Retrieving Location...') {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              content: const Text(
                                                  'Retrieving Location, Please wait.'),
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
                                        var res = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: ((context) =>
                                                const SearchScreen())));
                                        if (res == "obtainDirection") {
                                          await getPlaceDirection();
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 50,
                        width: 300,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Colors.greenAccent,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                //to set border radius to button
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              if (pickUpLocationController.text.toString() ==
                                  'Retrieving Location...' ||
                                  destinationLocationController.text
                                      .toString() ==
                                      'Where are you going?') {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: const Text('Fields can not be empty!'),
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
                                _saveToFirebase(context);
                              }
                              // Navigator.of(context).push(MaterialPageRoute(
                              //    builder: (context) => AvailableDrivers()));
                            },
                            child: const Text(
                             "Add Button",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            )),
                      )
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _saveToFirebase(BuildContext context) async {
    String dropdownvalue = '1 passenger';

    String? currentSelectedVehicle = carType;
    String currentSelectedPassenger = '1 Passenger';
    Map<String, List<String>> dropdownItemsMap = {
      'Car': ['1 Passenger', '2 Passengers', '3 Passengers', '4 Passengers'],
      'Van': [
        '1 Passenger', '2 Passengers', '3 Passengers', '4 Passengers',
        '5 Passengers', '6 Passengers', '7 Passengers','8 Passengers',
        '9 Passengers', '10 Passengers', '11 Passengers', '12 Passengers'
      ],
      'Mini-Van': [
        '1 Passenger', '2 Passengers', '3 Passengers', '4 Passengers',
        '5 Passengers', '6 Passengers'
      ]
    };

    estimatedCostController.text = estimateCost(
        double.parse(latitudeController.text.toString()),
        double.parse(longitudeController.text.toString()),
        double.parse(destinationLatitudeController.text.toString()),
        double.parse(destinationLongitudeController.text.toString()));
    estimatedCostController.text += ' Birr';

    var currentSelectedValue;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Center(child: Text("Add a pool")),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: pickUpLocationController,
                      enabled: false,
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.greenAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.greenAccent)),
                        labelText:'Pick-Up',
                        icon: Icon(Icons.location_on_rounded),
                      ),
                    ),
                    const SizedBox(
                      height: 13.0,
                    ),
                    TextFormField(
                      controller: destinationLocationController,
                      enabled: false,
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.greenAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.greenAccent)),
                        labelText: 'Drop-Off',
                        icon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(
                      height: 13.0,
                    ),
                    TextFormField(
                      controller: estimatedCostController,
                      enabled: false,
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.greenAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.greenAccent)),
                        labelText: 'Estimated Cost',
                        icon: Icon(Icons.money),
                      ),
                    ),
                    const SizedBox(
                      height: 13.0,
                    ),
                    DropdownButtonFormField<String>(
                      value: currentSelectedPassenger,
                      items: dropdownItemsMap[currentSelectedVehicle]!.map((String value) {
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
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      hint: Text('Select Passengers'),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select passengers';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 13.0,
                    ),
                    TextFormField(
                        readOnly: true,
                        controller: dateController,
                        decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.greenAccent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                                borderSide:
                                BorderSide(color: Colors.greenAccent)),
                            labelText: 'Date',
                            icon: Icon(Icons.calendar_month_rounded)),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2200),
                          );

                          if (pickedDate != null) {
                            setState(() {
                              dateController.text =
                                  DateFormat('yyyy-MM-dd').format(pickedDate);
                            });
                          }
                        }),
                    TextFormField(
                        readOnly: true,
                        controller: timeController,
                        decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.greenAccent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                                borderSide:
                                BorderSide(color: Colors.greenAccent)),
                            labelText: 'Time',
                            icon: Icon(Icons.alarm)),
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              final localizations =
                              MaterialLocalizations.of(context);
                              final formattedTimeOfDay =
                              localizations.formatTimeOfDay(pickedTime);
                              timeController.text = formattedTimeOfDay;
                            });
                          }
                        }),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              MaterialButton(
                color: Colors.red,
                textColor: Colors.white,
                child: const Text('Cancel'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              MaterialButton(
                color: Colors.green,
                textColor: Colors.white,
                child: const Text('Save'),
                onPressed: () {
                  setState(() {
                    _saveCarPool();
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;

    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos!.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos!.latitude, finalPos.longitude);
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            LoadingScreen(message: "Please wait...."));
    var details = await AssistantMethods.obtainDirectionDetails(
        pickUpLatLng, dropOffLatLng);

    Navigator.pop(context);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodePolylinePointsResult =
    polylinePoints.decodePolyline(details!.encodedPoints.toString());
    pLineCoordinates.clear();
    if (decodePolylinePointsResult.isNotEmpty) {
      decodePolylinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newgoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocationMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
        InfoWindow(title: initialPos.placeName, snippet: "My location"),
        position: pickUpLatLng,
        markerId: const MarkerId(
          "pickUpId",
        ));
    Marker dropOffLocationMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
        InfoWindow(title: finalPos.placeName, snippet: "My destination"),
        position: dropOffLatLng,
        markerId: const MarkerId(
          "dropOffId",
        ));

    setState(() {
      markersSet.add(pickUpLocationMarker);
      markersSet.add(dropOffLocationMarker);
    });

    Circle pickUpLocCircle = Circle(
        fillColor: Colors.blueAccent,
        center: pickUpLatLng,
        radius: 12.0,
        strokeWidth: 4,
        strokeColor: Colors.yellowAccent,
        circleId: const CircleId("pickUpId"));

    Circle dropOffLocCircle = Circle(
        fillColor: Colors.deepPurple,
        center: dropOffLatLng,
        radius: 12.0,
        strokeWidth: 4,
        strokeColor: Colors.deepPurple,
        circleId: const CircleId("dropOffId"));

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  Future<void> _saveCarPool() async {
    int index = 0;
    final _auth = FirebaseAuth.instance;
    Timer timestamp;
    String tripID = DateTime.now().microsecondsSinceEpoch.toString();
    int size = int.parse(passengers[0]); // the size of the list
    List<String> list = List.generate(size, (index) => "");


    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        Future.delayed(Duration.zero, () {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext c){
                return ProgressDialog(message: "Processing, Please wait...",);
              }
          );
        });
        await tripsRef.child(tripID).set({
          "tripID": tripID,
          "pickUpLocation": pickUpLocationController.text.toString(),
          "destinationLocation": destinationLocationController.text.toString(),
          "locationLatitude": latitudeController.text,
          "locationLongitude": longitudeController.text,
          "destinationLatitude": destinationLatitudeController.text,
          "destinationLongitude": destinationLongitudeController.text,
          "passengers": passengers,
          "driver_id": _auth.currentUser?.uid.toString(),
          "passengerIDs": list,
          "date": dateController.text.toString(),
          "time": timeController.text.toString(),
          "availableSeats": passengers[0],
          "estimatedCost": estimatedCostController.text.toString(),
          "status": "scheduled",
        });
        Navigator.pop(context);
        // ignore: use_build_context_synchronously
        displayToastMessage(
            "Congratulations,your pool has been added", context);
      } catch (ex) {
        print("Your error is $ex");
        Navigator.pop(context);
        displayToastMessage("Pool has not been added", context);
      }
    }
  }

  String estimateCost(double pickUpLat, double pickUpLong, double destLat, double  destLong){
    double baseFare = 80;
    double costPerMin = 2;
    double costPerKm = 12;

    double distance = estimateDistance(pickUpLat, pickUpLong, destLat, destLong);
    double time = estimateTime(distance);

    double cost = baseFare + (distance * costPerKm)  + (time * costPerMin);

    return cost.round().toString();
  }

  double estimateDistance(double pickUpLat, double pickUpLong, double destLat, double  destLong){

    double distance, earthRadius = 6371;
    double lat1Rad = degreesToRadians(pickUpLat);
    double lon1Rad = degreesToRadians(pickUpLong);
    double lat2Rad = degreesToRadians(destLat);
    double lon2Rad = degreesToRadians(destLong);

    double latDiff = lat2Rad - lat1Rad;
    double lonDiff = lon2Rad - lon1Rad;

    num havLat = pow(sin(latDiff / 2), 2);
    num havLon = pow(sin(lonDiff / 2), 2);

    double hav = havLat + havLon * cos(lat1Rad) * cos(lat2Rad);

    distance = 2 * earthRadius * asin(sqrt(hav));

    return distance;

  }
  double degreesToRadians(double degrees) {
    // Helper function to convert degrees to radians
    return degrees * pi / 180;
  }

  double estimateTime(double distance){
    double averageSpeed = 20;

    return distance / averageSpeed * 60;
  }
}
