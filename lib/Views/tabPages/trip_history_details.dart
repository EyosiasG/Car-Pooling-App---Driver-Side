import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../Constants/widgets/loading.dart';
import '../../Models/trip.dart';
import '../assistants/assistant_methods.dart';

class TripHistoryDetails extends StatefulWidget {
  const TripHistoryDetails({Key? key, required this.item}) : super(key: key);

  final Trip item;

  @override
  State<TripHistoryDetails> createState() => _TripHistoryDetailsState();
}

class _TripHistoryDetailsState extends State<TripHistoryDetails> {
  User? currentUser;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newgoogleMapController;
  static const CameraPosition _kGooglePlex =
      CameraPosition(target: LatLng(9.1450, 40.4897), zoom: 1);

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};
  String driverImage = "";
  String name = "";

  List<Trip> trip = [];
  bool isLoading = false;

  Future<void> getPlaceDirection() async {
    var pickUpLatLng = LatLng(double.parse(widget.item.pickUpLatPos),
        double.parse(widget.item.pickUpLongPos));
    var dropOffLatLng = LatLng(double.parse(widget.item.dropOffLatPos),
        double.parse(widget.item.dropOffLongPos));
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
        color: Colors.greenAccent,
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
        infoWindow: InfoWindow(
            title: widget.item.pickUpLocation, snippet: "My location"),
        position: pickUpLatLng,
        markerId: const MarkerId(
          "pickUpId",
        ));
    Marker dropOffLocationMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
            title: widget.item.destinationLocation, snippet: "My destination"),
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

  final tripRef = FirebaseDatabase.instance.ref('trips');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            color: Colors.black,
          ),
          title: const Text(
            'Trip Details',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: Column(children: [
          Container(
            height: 250,
            child: Stack(
              children: [
                GoogleMap(
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
                    getPlaceDirection();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Image.asset(
                      "images/PickUpDestination.png",
                      width: 40,
                      height: 70,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: Text(
                            widget.item.destinationLocation,
                            style: const TextStyle(
                                fontSize: 16, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        Divider(),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: Text(
                            widget.item.pickUpLocation,
                            style: const TextStyle(
                                overflow: TextOverflow.ellipsis,
                                fontSize: 16,
                                color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Row(
                      children: [
                        const Icon(Icons.attach_money),
                        const Padding(
                          padding: EdgeInsets.only(left: 5.0),
                          child: Text(
                            "Total Fair :",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (widget.item.status == 'finished')
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: StreamBuilder(
                              stream: tripRef.child(widget.item.tripID).onValue,
                              builder: (context, AsyncSnapshot snapshot) {
                                if (!snapshot.hasData ||
                                    snapshot.data?.snapshot?.value == null) {
                                  return Container();
                                } else {
                                  Map<dynamic, dynamic> trip =
                                      snapshot.data.snapshot.value;
                                  return Text('${double.parse(trip['fare']).toStringAsPrecision(2)} birr');
                                }
                              },
                            ),
                          )
                        else
                          Text('Cancelled')
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Row(
                      children: [
                        Icon(Icons.event_seat),
                        const Padding(
                          padding: EdgeInsets.only(left: 5.0),
                          child: Text(
                            "Seats :",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text((int.parse(widget.item.passengers[0]) - int.parse(widget.item.availableSeats)).toString()),
                        )
                      ],
                    ),
                  ),
                ),
                const Divider(),
              ],
            ),
          ),
        ]));
  }
}
