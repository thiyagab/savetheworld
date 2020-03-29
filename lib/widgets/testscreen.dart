import 'package:flutter/material.dart';
import 'package:simple_animations_example_app/particle_background.dart';

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[ConstrainedBox(
        constraints: BoxConstraints(maxHeight: double.infinity,maxWidth: double.infinity),
            child: Container(
        decoration: const BoxDecoration(color: Colors.red),
    )),ConstrainedBox(
          constraints: BoxConstraints.expand(height: 30),
          child: Center(child:Text("Hiiisgjh  sdgkhsdghsjdghskdjg sdghksdj ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900,decoration: TextDecoration.none),
              textScaleFactor: 0.3)),

        ),],
    );

  }
}
