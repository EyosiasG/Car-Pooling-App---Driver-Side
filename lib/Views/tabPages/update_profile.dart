import 'package:car_pool_driver/Constants/styles/colors.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../main.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key, required this.userKey});

  final String userKey;

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final carMakeController = TextEditingController();
  final carModelController = TextEditingController();
  final carColorController = TextEditingController();
  final carPlateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    DataSnapshot userUpdateRef = await driversRef.child(widget.userKey).get();
    Map userData = userUpdateRef.value as Map;
    nameController.text = userData['name'];
    phoneController.text = userData['phone'];
    carMakeController.text = userData['car_make'];
    carModelController.text = userData['car_model'];
    carColorController.text = userData['car_color'];
    carPlateController.text = userData['car_plateNo'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorsConst.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
          color: ColorsConst.black,
        ),
        title: const Text(
          "Update your profile",
          style: TextStyle(color: ColorsConst.black),
        ),
        elevation: 0,
      ),
      body: textFields(context),
    );
  }

  Widget textFields(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        child: Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 10.0),
          child: Column(
            children: [
              TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: ColorsConst.grey),
                  decoration: InputDecoration(
                    labelText: "Name",
                    hintText: "Name",
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsConst.grey),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsConst.grey)),
                    hintStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 10,
                    ),
                    labelStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 16,
                    ),
                  )),
              const SizedBox(
                height: 15.0,
              ),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                    labelText: "Phone",
                    hintText: "Phone",
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsConst.grey),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsConst.grey)),
                    hintStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 10,
                    ),
                    labelStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 16,
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: carColorController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                    labelText: "Car color",
                    hintText: "Car color",
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsConst.grey),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsConst.grey)),
                    hintStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 10,
                    ),
                    labelStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 16,
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: carMakeController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                    labelText: "Car make",
                    hintText: "Car make",
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsConst.grey),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsConst.grey)),
                    hintStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 10,
                    ),
                    labelStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 16,
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: carModelController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                    labelText: "Car model",
                    hintText: "Car model",
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsConst.grey),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsConst.grey)),
                    hintStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 10,
                    ),
                    labelStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 16,
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: carPlateController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: ColorsConst.grey),
                decoration: InputDecoration(
                    labelText: "Plate number",
                    hintText: "Plate number",
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsConst.grey),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsConst.grey)),
                    hintStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 10,
                    ),
                    labelStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 16,
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                onPressed: () {
                  Map<String, String> users = {
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'car_color': carColorController.text,
                    'car_make': carMakeController.text,
                    'car_model': carModelController.text,
                    'car_plateNo': carPlateController.text,
                  };
                  try {
                    driversRef
                        .child(widget.userKey)
                        .update(users)
                        .then((value) => {
                              Fluttertoast.showToast(
                                  msg: "Driver information updated"),
                              Navigator.pop(context)
                            });
                  } catch (exp) {
                    Fluttertoast.showToast(msg: "Error updating $exp");
                  }
                },
                child: const Text("Update my profile"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
