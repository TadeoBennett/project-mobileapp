import 'package:cpi_app/helpers/auth.dart';
import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:cpi_app/providers/substitutions.dart';
import 'package:cpi_app/providers/varieties.dart';
import 'package:cpi_app/screens/home_screen_.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  String username = '';
  String password = '';

  bool _isLoading = false;
  String _errorMessage = '';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(color: Colors.white10)),
      child: Form(
        key: _formKey,
        child: Column(children: [
          userNameField(),
          passwordField(),
          submitButton(),
          errorMessage()
        ]),
      ),
    );
  }

  Widget userNameField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: "Username"),
      textInputAction: TextInputAction.next,
      onSaved: (value) => {setState(() => username = value ?? '')},
    );
  }

  Widget passwordField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: "Password"),
      textInputAction: TextInputAction.done,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      onSaved: (value) => {setState(() => password = value ?? '')},
    );
  }

  Widget submitButton() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
                handleSubmit();
              },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50), // NEW
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Colors.white12,
              )
            : const Text('Login'),
      ),
    );
  }

  Widget errorMessage() {
    return Text(
      _errorMessage,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }

  void handleSubmit() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _isLoading = true);
        _formKey.currentState!.save();
        Map<String, dynamic> loginAppData =
            await UserAuth().authenticateUser(username, password);

        if (loginAppData['lastLoginUserId'] != loginAppData['currentUserId']) {
          // delete all the current assignments
          await ref.read(assignmentsProvider).clearAssignments();
          // delete all current substitutions
          await ref.read(substitutionsProvider).clearSubstitutions();
          // delete all current varieties
          await ref.read(varietiesProvider).clearVarieties();
          // delete all current outlets
          await ref.read(outletsProvider).clearOutlets();
        }

        //FirebaseMessaging get token and send to server
        String? token = await FirebaseMessaging.instance.getToken();

        if (token != null && loginAppData['currentUserType'] != 'HQ') {
          await UserAuth().sendFCMTokenToServer(token);
        }

        setState(() {
          _isLoading = false;
          _errorMessage = "";
        });

        if (!mounted) return;
        Navigator.of(context).popAndPushNamed(HomeScreen.routeName);
      }
    } catch (e) {
      print(e);

      setState(() => _isLoading = false);

      if (e.toString() != 'Invalid Credentials!') {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(content: Text(e.toString())));
      } else {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }
}
