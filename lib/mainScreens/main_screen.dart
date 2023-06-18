import 'package:car_pool_driver/Views/tabPages/myTrips.dart';
import 'package:car_pool_driver/Views/tabPages/requests.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../Constants/styles/colors.dart';
import '../Views/tabPages/dashboard.dart';
import '../Views/tabPages/profile_tab.dart';
import '../Views/tabPages/trip_history_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  TabController? tabController;
  int selectedIndex = 0;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  onItemClicked(int index) {
    setState(() {
      selectedIndex = index;
      tabController!.index = selectedIndex;
    });
  }

  final CollectionReference collectionRef =
      FirebaseFirestore.instance.collection('requestStatus');
  Future<void> deleteCollection() async {
    final QuerySnapshot snapshot = await collectionRef.get();
    final List<DocumentSnapshot> documents = snapshot.docs;

    for (DocumentSnapshot document in documents) {
      await document.reference.delete();
    }
  }

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 5, vsync: this);
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings("@mipmap/ic_launcher");
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
    );
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        deleteCollection();
      },
    );
    Stream<QuerySnapshot<Map<String, dynamic>>> notificationStream =
        FirebaseFirestore.instance.collection("requestStatus").snapshots();

    notificationStream.listen((event) {
      if (event.docs.isEmpty) {
        return;
      }

      showNotification(event.docs.first);
    });
  }

  void showNotification(QueryDocumentSnapshot<Map<String, dynamic>> event) {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails("ScheduleNotification001", "Notify me",
            importance: Importance.high);
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    flutterLocalNotificationsPlugin.show(
        01, event.get('title'), event.get('description'), notificationDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: tabController,
        children: const [
          Dashboard(),
          TripHistoryTabPage(),
          MyTrips(),
          MyRequests(),
          ProfileTabPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus_filled_rounded),
            label: "Trips",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: "Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
        unselectedItemColor: ColorsConst.grey,
        selectedItemColor: ColorsConst.greenAccent,
        backgroundColor: ColorsConst.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 14),
        showUnselectedLabels: true,
        currentIndex: selectedIndex,
        onTap: onItemClicked,
      ),
    );
  }
}
