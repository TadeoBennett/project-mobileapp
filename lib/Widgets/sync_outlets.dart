import 'package:cpi_app/providers/outlets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OutletSync extends StatefulWidget {
  const OutletSync({
    Key? key,
  }) : super(key: key);

  @override
  State<OutletSync> createState() => _OutletSyncState();
}

class _OutletSyncState extends State<OutletSync> {
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
        color: Colors.blueGrey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.store, color: Colors.white),
                Text(" Outlets",
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
                    int addedOutlets =
                        ref.watch(outletsProvider).addedOutletsForSync().length;
                    int editedOutlets = ref
                        .watch(outletsProvider)
                        .editedOutletsForSync()
                        .length;

                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Added Outlets:  $addedOutlets",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white)),
                          const SizedBox(height: 5),
                          Text("Modified Outlets: $editedOutlets",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white)),
                          const SizedBox(height: 5),
                        ]);
                  })),
              // Expanded(
              //     flex: 1,
              //     child: Column(children: [
              //       Consumer(builder: (ctx, ref, child) {
              //         return Material(
              //           borderRadius: BorderRadius.circular(20),
              //           color: Colors.blueGrey.shade400,
              //           child: InkWell(
              //               borderRadius: BorderRadius.circular(20),
              //               radius: 50,
              //               onTap: () async {
              //                 setState(() {
              //                   loading = true;
              //                 });
              //                 try {
              //                   await ref.read(outletsProvider).uploadOutlets();
              //                   if (!mounted) return;
              //                   showSnackbar(context, false, "Uploaded Outlets",
              //                       "Outlets were uploaded successfully!");
              //                 } catch (e) {
              //                   showSnackbar(context, true, "Uploaded Failed",
              //                       "Failed to upload Outlets, Please try again later!");
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
