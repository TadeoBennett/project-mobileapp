// import 'package:CPI/screens/home_screen.dart';
// import '../helpers/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/login';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0.1, 0.4, 0.7, 0.9],
            colors: [
              Color.fromRGBO(2, 70, 72, 1),
              Color.fromRGBO(2, 70, 72, 0.90),
              Color.fromRGBO(2, 70, 72, 0.80),
              Color.fromRGBO(2, 70, 72, 0.75),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                height: 110,
                child: SvgPicture.asset('lib/assets/images/sib-logo-small.svg',
                    semanticsLabel: 'Acme Logo'),
              ),
              const Text(
                "CPI Collector",
                style: TextStyle(
                  fontFamily: "Raleway",
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
              const Text(
                "Please sign in",
                style: TextStyle(
                  fontFamily: "Raleway",
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const LoginForm(), //LOGIN FORM WIDGET WITH ALL LOGIN LOGIC
            ],
          ),
        ),
      ),
    );
  }
}
