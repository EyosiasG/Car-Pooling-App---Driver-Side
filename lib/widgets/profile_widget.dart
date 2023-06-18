import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  final String imagePath;

  const ProfileWidget({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Stack(
      children: [
        buildImage(),
      ],
    ));
  }

  Widget buildImage() {
    final image = NetworkImage(imagePath);

    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: Ink.image(
          image: image,
          fit: BoxFit.cover,
          width: 132,
          height: 132,
        ),
      ),
    );
  }

  Widget buildCircle({
    required Widget child,
    required Color color,
  }) =>
      ClipOval(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          color: color,
          child: child,
        ),
      );
}
