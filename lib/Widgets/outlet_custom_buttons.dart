import 'package:flutter/material.dart';

class CustomOutletButton extends StatelessWidget {
  final bool currentStore;
  final Function onPressed;
  const CustomOutletButton(
      {Key? key, required this.currentStore, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unSelectedButton = ElevatedButton.styleFrom(
        onPrimary: Colors.blue, primary: Colors.grey.shade300);

    final selectedButton = ElevatedButton.styleFrom(
        onPrimary: Colors.white, primary: Colors.amber);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: ElevatedButton(
                onPressed: () {
                  if (currentStore) return;
                  onPressed(true);
                },
                style: currentStore ? selectedButton : unSelectedButton,
                child: const Text("Current Store")),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
                onPressed: () {
                  if (!currentStore) return;
                  onPressed(false);
                },
                style: !currentStore ? selectedButton : unSelectedButton,
                child: const Text("Other Store")),
          ),
        ],
      ),
    );
  }
}
