import 'package:car_pool_driver/Views/tabPages/startTrip_tab.dart';
import 'package:car_pool_driver/Views/tabPages/support_tab.dart';
import 'package:car_pool_driver/global/global.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

import '../../Models/trip.dart';
import '../../widgets/progress_dialog.dart';

class MyTrips extends StatefulWidget {
  const MyTrips({Key? key}) : super(key: key);

  @override
  State<MyTrips> createState() => _MyTripsState();
}

class _MyTripsState extends State<MyTrips> {
  final databaseReference = FirebaseDatabase.instance.ref('trips');
  List<Trip> trips = [];
  List<Trip> scheduledTrips = [];
  bool isLoading = false;

  Future<List<Trip>> getTrips() async {
    List<Trip> itemList = [];

    try {
      final dataSnapshot = await databaseReference
          .orderByChild('driver_id')
          .equalTo(currentFirebaseUser!.uid)
          .once();

      Map<dynamic, dynamic> values =
          dataSnapshot.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        final item = Trip(
            tripID: value['tripID'],
            driverID: value['driver_id'],
            pickUpLatPos: value['locationLatitude'],
            pickUpLongPos: value['locationLongitude'],
            dropOffLatPos: value['destinationLatitude'],
            dropOffLongPos: value['destinationLongitude'],
            pickUpDistance: 0,
            dropOffDistance: 0,
            destinationLocation: value['destinationLocation'],
            pickUpLocation: value['pickUpLocation'],
            userIDs: [],
            price: value['estimatedCost'],
            date: value['date'],
            time: value['time'],
            availableSeats: value['availableSeats'],
            passengers: value['passengers'],
            status: value['status']);
        itemList.add(item);
      });
    } catch (e) {
      AlertDialog(semanticLabel: 'Error: $e');
    }
    return itemList;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isLoading = true;
    getMyTrips().then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> getMyTrips() async {

    List<Trip> trips = await getTrips();
    setState(() {
      this.trips = trips;
      for (var trip in trips) {
        if (trip.status == 'scheduled') {
          scheduledTrips.add(trip);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor:
            (scheduledTrips.isEmpty) ? Colors.white : const Color(0xFFEDEDED),
        body: Stack(
          children: [
            if (isLoading)
              ProgressDialog(
                message: "Processing....",
              )
            else
              (scheduledTrips.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "images/noHistory.jpg",
                            height: 250,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          const Text(
                            "YOU HAVE NO BOOKED TRIPS FOR NOW!!!",
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: scheduledTrips.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => MyWidget(
                                          trip: scheduledTrips[index],
                                        )));
                          },
                          child: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(children: [
                                Row(children: [
                                  Image.asset(
                                    "images/PickUpDestination.png",
                                    width: 40,
                                    height: 50,
                                  ),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          constraints: const BoxConstraints(
                                              maxWidth: 250),
                                          child: Text(
                                            scheduledTrips[index]
                                                .destinationLocation,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const Divider(),
                                        Container(
                                          constraints: const BoxConstraints(
                                              maxWidth: 250),
                                          child: Text(
                                            scheduledTrips[index]
                                                .pickUpLocation,
                                            style: const TextStyle(
                                              color: Colors.grey,
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
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(scheduledTrips[index].time),
                                            Text(DateFormat('EEEE, MMMM d, y')
                                                .format(DateTime.parse(
                                                    scheduledTrips[index]
                                                        .date))),
                                          ],
                                        ),
                                        RatingBarIndicator(
                                          itemBuilder: (context, index) =>
                                              const Icon(
                                            Icons.person,
                                            color: Colors.amber,
                                          ),
                                          rating: double.parse(
                                                  scheduledTrips[index]
                                                      .passengers[0]) -
                                              double.parse(scheduledTrips[index]
                                                  .availableSeats),
                                          itemSize: 20,
                                          itemCount: int.parse(
                                              scheduledTrips[index]
                                                  .passengers[0]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Divider(),
                              ])),
                        );
                      }),
          ],
        ));
  }
}
