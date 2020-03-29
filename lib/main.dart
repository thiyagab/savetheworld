import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:simple_animations_example_app/particle_background.dart';
import 'package:firebase/firebase.dart';
import 'package:simple_animations_example_app/widgets/testscreen.dart';

void main() {
  if (apps==null || apps.isEmpty) {
    initializeApp(
        apiKey: "AIzaSyCtJuYTWGby_AZWjKuWVGRXqlJgMOwxIbA",
        authDomain: "kill-corona-virus.firebaseapp.com",
        databaseURL: "https://kill-corona-virus.firebaseio.com",
        projectId: "kill-corona-virus",
        storageBucket: "kill-corona-virus.appspot.com",
        messagingSenderId: "659058448757"
    );
  }
  runApp(HomeScreen());
}

class HomeScreen extends StatelessWidget {



  @override
  Widget build(BuildContext context) {


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Kill the virus",
      home: ParticleBackgroundApp(),
      theme: _theme(),
    );
  }

  ThemeData _theme() {
    var lightTheme = ThemeData.light();

    return lightTheme.copyWith(
        textTheme: lightTheme.textTheme.copyWith(
            body1: lightTheme.textTheme.body1.copyWith(height: 1.25),
            body2: lightTheme.textTheme.body2
                .copyWith(height: 1.25, fontWeight: FontWeight.w800)),
        appBarTheme: AppBarTheme(color: Color.fromARGB(255, 30, 30, 30)));
  }
}
