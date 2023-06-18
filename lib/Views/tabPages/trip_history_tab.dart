import 'dart:core';
import 'package:car_pool_driver/Views/tabPages/trip_history_details.dart';
import 'package:car_pool_driver/widgets/progress_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../Constants/styles/colors.dart';
import '../../Models/trip.dart';
import '../../global/global.dart';

class TripHistoryTabPage extends StatefulWidget {
  const TripHistoryTabPage({Key? key}) : super(key: key);

  @override
  State<TripHistoryTabPage> createState() => _TripHistoryTabPageState();
}

class _TripHistoryTabPageState extends State<TripHistoryTabPage> {
  List<Trip> trips = [];
  List<Trip> historyTrips = [];
  bool isLoading = false;
  final databaseReference = FirebaseDatabase.instance.ref('trips');

  @override
  void initState() {
    super.initState();
    isLoading = true;
    getTrip().then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<List<Trip>> getTrips(String driverId) async {
    List<Trip> itemList = [];
    // Get a reference to the Firebase database

    try {
      final dataSnapshot = await databaseReference
          .orderByChild('driver_id')
          .equalTo(driverId)
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
      // Log the error and return an empty list
     // Fluttertoast.showToast(msg: e.toString());
    }
    return itemList;
  }

  Future<void> getTrip() async {
    List<Trip> trips = await getTrips(currentFirebaseUser!.uid.toString());
    setState(() {
      this.trips = trips;
      for (var t in trips) {
        if (t.status == 'finished' || t.status == 'cancelled') {
          historyTrips.add(t);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: (historyTrips.isEmpty) ? Colors.white : const Color(0xFFEDEDED),
      body: Stack(
        children: [
          if (isLoading)
            ProgressDialog(
              message: "Processing....",
            )
          else
            (historyTrips.isEmpty)
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
                          "YOU HAVE NO PAST BOOKED TRIPS !!!",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: historyTrips.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                historyTrips[index].destinationLocation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w100,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    '${DateFormat('EEEE, MMMM d, y')
                                        .format(DateTime.parse(
                                        historyTrips[index]
                                            .date))} at ${historyTrips[index].time}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    historyTrips[index].status.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: (historyTrips[index].status ==
                                                'finished')
                                            ? Colors.greenAccent
                                            : Colors.redAccent),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.navigate_next),
                              onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => TripHistoryDetails(item:trips[index])
                                 ));
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Divider(
                                color: ColorsConst.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
        ],
      ),
    );
    /* body: Column(
        children: [
          Text(itemList.length.toString()),


          ListView.builder(
              shrinkWrap: true,
              itemCount: itemList.length,
              scrollDirection: Axis.vertical,
              itemBuilder: (BuildContext context, int index){
                final item = itemList[index];
                return Card(
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListTile(
                    title : Text(itemList[index].pickUp.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),),
                    subtitle:RichText(
                        text: const TextSpan(
                            text: "4th April , 2023 at 10:37AM",
                            style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins',
                                color: Colors.black,
                                fontSize: 15),
                            children: <TextSpan>[
                              TextSpan(
                                  text: "\nFinished",
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.green,
                                      fontSize: 15)
                              )
                            ])
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: (){
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => TripHistoryDetails(item:item),
                      ));
                    },
                  ),
                ),

                );
              }

              ),
        ],
      ),*/
  }
}
