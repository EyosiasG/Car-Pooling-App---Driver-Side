// ignore_for_file: sized_box_for_whitespace

import 'package:car_pool_driver/Models/place_predictions.dart';
import 'package:car_pool_driver/Views/assistants/request_assistant.dart';
import 'package:car_pool_driver/Views/data%20handler/app_data.dart';
import 'package:car_pool_driver/Views/trips/trips_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Constants/styles/colors.dart';
import '../../Constants/styles/styles.dart';
import '../../config_map.dart';

// ignore: must_be_immutable
class SearchTrip extends StatefulWidget {
  const SearchTrip({Key? key}) : super(key: key);

  @override
  State<SearchTrip> createState() => _SearchTripState();
}

class _SearchTripState extends State<SearchTrip> {
  TextEditingController pickUpTextEditingController = TextEditingController();

  TextEditingController destinationTextEditingController =
      TextEditingController();

  List<PlacePredictions> placePredictionList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Align(
            alignment: const Alignment(-2.4, 2.5),
            child: searchBar(context),
          ),
        ),
        (placePredictionList.isNotEmpty)
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListView.separated(
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    return PredictionTile(
                        placePredictions: placePredictionList[index]);
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(),
                  itemCount: placePredictionList.length,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                ),
              )
            : Container(),
      ],
    ));
  }

  Widget searchBar(BuildContext context) {
    String? placeAddress =
        Provider.of<AppData>(context).pickUpLocation?.placeName;
    pickUpTextEditingController.text = placeAddress!;
    return Container(
      alignment: const Alignment(1, 1),
      height: 250,
      width: double.maxFinite,
      padding: const EdgeInsets.only(left: 18.0, right: 18.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 10.0,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 15.0, 8.0, 8.0),
            child: TextFormField(
              enabled: false,
              decoration: InputDecoration(
                  disabledBorder: StylesConst.textBorder,
                  fillColor: ColorsConst.grey100,
                  filled: true,
                  label: Text(pickUpTextEditingController.text.toString()),
                  labelStyle: StylesConst.labelStyle,
                  hintStyle: StylesConst.hintStyle),
              style: const TextStyle(fontSize: 17.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 3.0, 8.0, 8.0),
            child: TextFormField(
              onChanged: (val) {
                findPlace(val);
              },
              decoration: InputDecoration(
                enabledBorder: StylesConst.textBorder,
                focusedBorder: StylesConst.textBorder,
                filled: true,
                label: const Text(
                  "Destination",
                  style: TextStyle(fontSize: 17),
                ),
                labelStyle: StylesConst.labelStyle,
              ),
              controller: destinationTextEditingController,
              textInputAction: TextInputAction.done,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                  padding: const EdgeInsets.all(0),
                  height: 60,
                  width: double.infinity,
                  child: ElevatedButton(
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.all(4.0),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.blue[700]),
                      ),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, TripList.idScreen, (route) => false);
                      },
                      child: const Text(
                        "Search",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ))),
            ),
          ),
          const SizedBox(height: 10.0),
        ]),
      ),
    );
  }

  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:et";

      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if (res == "failed") {
        return;
      }

      if (res["status"] == "OK") {
        var predictions = res["predictions"];

        var placesList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();

        setState(() {
          placePredictionList = placesList;
        });
      }
    }
  }
}

class PredictionTile extends StatelessWidget {
  final PlacePredictions placePredictions;
  const PredictionTile({Key? key, required this.placePredictions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Column(children: [
        const SizedBox(
          width: 10.0,
        ),
        Row(
          children: [
            const Icon(Icons.add_location),
            const SizedBox(
              width: 14.0,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 8.0,
                  ),
                  Text(placePredictions.main_text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16.0)),
                  const SizedBox(
                    height: 2.0,
                  ),
                  // Text(placePredictions.secondary_text,
                  //     style: const TextStyle(
                  //         fontSize: 12.0,
                  //         overflow: TextOverflow.ellipsis,
                  //         color: ColorsConst.grey)),
                  //         const SizedBox(
                  //   height: 8.0,
                  // ),
                ],
              ),
            )
          ],
        ),
        const SizedBox(
          width: 10.0,
        ),
      ]),
    );
  }
}
