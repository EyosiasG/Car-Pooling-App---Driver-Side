import 'dart:async';

import 'package:car_pool_driver/global/global.dart';
import 'package:car_pool_driver/widgets/progress_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Constants/styles/colors.dart';
import '../../Models/requests.dart';

class GetRequests {
  final databaseReference = FirebaseDatabase.instance.ref('requests');

  Future<List<Request>> getRequests(String driverID) async {
    List<Request> itemList = [];

    try {

      final dataSnapshot = await databaseReference
          .orderByChild('driverID')
          .equalTo(driverID)
          .once();

      Map<dynamic, dynamic> values =
      dataSnapshot.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        final item = Request(
            requestID: value['requestID'],
            tripID: value['tripID'],
            driverID: value['driverID'],
            userID: value['userID'],
            status: value['status']);
        itemList.add(item);
      });
    } catch (e) {
      AlertDialog(semanticLabel: 'Error: $e');
    }
    return itemList;
  }
}

class MyRequests extends StatefulWidget {
  const MyRequests({Key? key}) : super(key: key);

  @override
  State<MyRequests> createState() => _MyRequestsState();
}

class _MyRequestsState extends State<MyRequests> {
  final GetRequests getRequests = GetRequests();
  List<Request> pendingRequest = [];
  List<Request> requests = [];
  List<bool> _isAcceptButtonClickedList = [];
  List<bool> _isDenyButtonClickedList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    getMyRequests().then((_) {
      isLoading = false;
    });
  }

  Future<void> getMyRequests() async {
    List<Request> requests =
    await getRequests.getRequests(currentFirebaseUser!.uid.toString());
    setState(() {
      this.requests = requests;
      _isAcceptButtonClickedList = List.filled(requests.length, false);
      _isDenyButtonClickedList = List.filled(requests.length, false);
      for (var r in requests) {
        if (r.status == 'pending') pendingRequest.add(r);
      }
    });
  }

  final ref = FirebaseDatabase.instance.ref('users');
  final tripRef = FirebaseDatabase.instance.ref('trips');
  int userCnt = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: (pendingRequest.isNotEmpty)
          ? const Color(0xFFEDEDED)
          : ColorsConst.white,
      body: Stack(
        children: [
          if (isLoading)
            Center(
              child: ProgressDialog(
                message: "Retrieving Requests...",
              ),
            )
          else
            (pendingRequest.isEmpty)
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    "images/noRequests.jpg",
                    height: 300,
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        "It seems like you have no ride requests for now!!! ",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: ColorsConst.blueGrey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: pendingRequest.length,
              itemBuilder: (context, index) {
                return buildUser(index);
              },
            ),
          if (isLoading && pendingRequest.isNotEmpty)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildUser(int index) => StreamBuilder(
    stream: ref.child(pendingRequest[index].userID).onValue,
    builder: (context, AsyncSnapshot snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting &&
          userCnt == 0) {
        userCnt++;
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else if (!snapshot.hasData ||
          snapshot.data?.snapshot?.value == null) {
        return Text(pendingRequest.length.toString());
      } else {
        Map<dynamic, dynamic> user = snapshot.data.snapshot.value;
        return buildTripData(index, user);
      }
    },
  );

  Widget buildTripData(int index, Map<dynamic, dynamic> user) => StreamBuilder(
    stream: tripRef.child(pendingRequest[index].tripID).onValue,
    builder: (context, AsyncSnapshot snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting &&
          userCnt == 0) {
        return Container();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else if (!snapshot.hasData ||
          snapshot.data?.snapshot?.value == null) {
        return Container();
      } else {
        Map<dynamic, dynamic> trip = snapshot.data.snapshot.value;
        return buildRequestCard(index, user, trip);
      }
    },
  );

  Widget buildRequestCard(
      int index, Map<dynamic, dynamic> user, Map<dynamic, dynamic> trip) =>
      Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: ColorsConst.white, borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Row(children: [
            Image.asset(
              "images/PickUpDestination.png",
              width: 40,
              height: 50,
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Text(
                  trip['destinationLocation'],
                  style: const TextStyle(
                    fontSize: 16,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Divider(),
              Container(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Text(
                  trip['pickUpLocation'],
                  style: const TextStyle(
                    color: ColorsConst.grey,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            ])
          ]),
          const SizedBox(
            height: 30,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip['time']),
                  Text(DateFormat('EEEE, MMMM d, y')
                      .format(DateTime.parse(
                      trip['date']))),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          const Divider(),
          Row(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      user['userImage'],
                    ),
                    radius: 25,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Text(user['name'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0.0, 0, 3.0, 0),
                          child: Text(user['phone']),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  SizedBox(
                    height: 40,
                    width: 115,
                    child: ElevatedButton(
                      onPressed:
                      //acceptRequest(requests[index]);
                      _isAcceptButtonClickedList[index]
                          ? null
                          : () => _onAcceptButtonPressed(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsConst.greenAccent,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _isAcceptButtonClickedList[index]
                            ? 'Accepted'
                            : 'Accept',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    height: 40,
                    width: 115,
                    child: ElevatedButton(
                      onPressed: _isDenyButtonClickedList[index]
                          ? null
                          : () => _onDenyButtonPressed(index),
                      //denyRequest(requests[index]);

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _isDenyButtonClickedList[index] ? 'Denied' : 'Deny',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ]),
      );

  Future<void> acceptRequest(Request request) async {
    String availableSeats;
    final ref = FirebaseDatabase.instance.ref();
    final snapshot =
    await ref.child('trips/${request.tripID}/availableSeats').get();
    if (snapshot.exists) {
      availableSeats = snapshot.value.toString();
      updateAvailableSeats(request, availableSeats);
    } else {
      const AlertDialog(semanticLabel: 'No data available.');
    }

    FirebaseDatabase.instance
        .ref("requests")
        .child(request.requestID)
        .update({"status": "accepted"});
  }

  Future<void> updateAvailableSeats(Request request, String data) async {
    String seat = "";
    final ref = FirebaseDatabase.instance.ref();
    final snapshot =
    await ref.child('trips/${request.tripID}/passengers').get();
    if (snapshot.exists) {
      seat = snapshot.value.toString()[0];
    } else {
      const AlertDialog(semanticLabel: 'No data available.');
    }

    FirebaseDatabase.instance
        .ref("trips")
        .child(request.tripID)
        .update({"availableSeats": (int.parse(data) - 1).toString()});

    FirebaseDatabase.instance
        .ref("trips")
        .child(request.tripID)
        .child("passengerIDs")
        .update({"${int.parse(seat) - int.parse(data)}": request.userID});
  }

  Future<void> denyRequest(Request request) async {
    List<Object?> seats = [];
    final ref = FirebaseDatabase.instance.ref();
    final snapshot =
    await ref.child('trips/${request.tripID}/passengerIDs').get();
    if (snapshot.exists) {
      seats = snapshot.value as List<Object?>? ?? [];
    } else {
      const AlertDialog(semanticLabel: 'No data available.');
    }
    String availableSeats;
    int i = 0;
    for (var seat in seats) {
      if (seat == request.userID) {
        final snapshot =
        await ref.child('trips/${request.tripID}/availableSeats').get();
        if (snapshot.exists) {
          availableSeats = snapshot.value.toString();
          FirebaseDatabase.instance.ref("trips").child(request.tripID).update(
              {"availableSeats": (int.parse(availableSeats) + 1).toString()});
          FirebaseDatabase.instance
              .ref("trips")
              .child(request.tripID)
              .child("passengerIDs")
              .update({"$i": ""});
        } else {
          const AlertDialog(semanticLabel: 'No data available.');
        }
      }
    }
    FirebaseDatabase.instance
        .ref("requests")
        .child(request.requestID)
        .update({"status": "rejected"});
  }

  final CollectionReference statusCollection =
  FirebaseFirestore.instance.collection('poolStatus');
  void _onAcceptButtonPressed(int index) async {
    setState(() {
      _isAcceptButtonClickedList[index] = true;
      _isDenyButtonClickedList[index] = false;
    });

    acceptRequest(pendingRequest[index]);

    final DocumentReference newStatusRef = await statusCollection.add({
      'title': 'Accepted',
      'description': 'Your car pooling request has been accepted',
    });
  }

  void _onDenyButtonPressed(int index) async {
    setState(() {
      _isDenyButtonClickedList[index] = true;
      _isAcceptButtonClickedList[index] = false;
    });

    denyRequest(pendingRequest[index]);

    final DocumentReference newStatusRef = await statusCollection.add({
      'title': 'Declined',
      'description':
      'Unfortunately, your car pooling request has been declined',
    });
  }
}