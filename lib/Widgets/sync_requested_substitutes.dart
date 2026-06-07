import 'package:cpi_app/providers/assignments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RequestSubstitutions extends StatefulWidget {
  const RequestSubstitutions({
    Key? key,
  }) : super(key: key);

  @override
  State<RequestSubstitutions> createState() => _RequestSubstitutionsState();
}

class _RequestSubstitutionsState extends State<RequestSubstitutions> {
  bool loading = false;

  void showSnackbar(ctx, failed, title, message) {
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: title,
          textColor: failed ? Colors.red : Colors.green,
          onPressed: () {
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade600,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.price_change_outlined, color: Colors.white),
                Text(" Request Substitutions",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold))
              ]),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 1,
                child: Consumer(builder: (ctx, ref, child) {
                  int requestedSubstitutes = ref
                      .watch(assignmentsProvider)
                      .requestedSubstitutionAssignments()
                      .length;

                  int uploadedRequestedSubstitutions = ref
                      .watch(assignmentsProvider)
                      .uploadedRequestedSubstitutionAssignments()
                      .length;

                  int grantedRequestedSubstitutions = ref
                      .watch(assignmentsProvider)
                      .grantedRequestedSubstitutions()
                      .length;

                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Require Uploaded: $requestedSubstitutes",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white)),
                        const SizedBox(height: 5),
                        Text("Pending Request: $uploadedRequestedSubstitutions",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white)),
                        const SizedBox(height: 5),
                        Text("Granted Request: $grantedRequestedSubstitutions",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white)),
                      ]);
                }),
              ),
              // Expanded(
              //     flex: 1,
              //     child: Column(children: [
              //       Consumer(builder: (ctx, ref, child) {
              //         return Material(
              //           borderRadius: BorderRadius.circular(20),
              //           color: Colors.blueGrey.shade600,
              //           child: InkWell(
              //               borderRadius: BorderRadius.circular(20),
              //               radius: 50,
              //               onTap: () async {
              //                 setState(() {
              //                   loading = true;
              //                 });
              //                 try {
              //                   await ref
              //                       .read(assignmentsProvider)
              //                       .uploadRequestedSubstitutions();
              //                   if (!mounted) return;
              //                   showSnackbar(
              //                       context,
              //                       false,
              //                       "Request Substitutions",
              //                       "Request were made successfully!");
              //                 } catch (e) {
              //                   showSnackbar(
              //                       context,
              //                       true,
              //                       "Request Substitutions",
              //                       "Failed to Request Substitutions, Please try again later!");
              //                 } finally {
              //                   setState(() {
              //                     loading = false;
              //                   });
              //                 }
              //               },
              //               child: loading
              //                   ? const CircularProgressIndicator()
              //                   : const Icon(Icons.cloud_upload,
              //                       color: Colors.white, size: 50)),
              //         );
              //       }),
              //     ]))
            ],
          ),
          const SizedBox(height: 15),
          // const Text("Last Sync: never",
          //     style: TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}
