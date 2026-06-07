import 'package:cpi_app/Widgets/sync_assignments.dart';
import 'package:cpi_app/Widgets/sync_outlets.dart';
import 'package:cpi_app/Widgets/sync_requested_substitutes.dart';
import 'package:cpi_app/Widgets/sync_substitutes.dart';
import 'package:cpi_app/helpers/utility_functions.dart';
import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/globals.dart';
import 'package:cpi_app/models/http_exception.dart';
import 'package:cpi_app/models/outlet.dart';
import 'package:cpi_app/models/substitute.dart';
import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:cpi_app/providers/substitutions.dart';
import 'package:cpi_app/providers/varieties.dart';
import 'package:cpi_app/screens/home_screen_.dart';
import 'package:cpi_app/screens/login_screen.dart';
import 'package:cpi_app/screens/outlet_map_screen.dart';
import 'package:cpi_app/screens/outlets_screen.dart';
import 'package:cpi_app/screens/substitution_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncScreen extends ConsumerStatefulWidget {
  static const routeName = "/sync";

  const SyncScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  bool isLoading = false;
  String loadingMessage = 'Loading';

  @override
  Widget build(BuildContext context) {
    List<Assignment> assignments = ref.read(assignmentsProvider).assignments;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.cyan.shade800,
          elevation: 0,
          bottomOpacity: 0.0,
          actions: [
            isLoading
                ? Row(
                    children: [
                      Container(
                          height: 12,
                          width: 12,
                          child: const CircularProgressIndicator()),
                      const SizedBox(width: 8),
                      Text(
                        loadingMessage,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: IconButton(
                        iconSize: 50,
                        onPressed: syncData,
                        icon: const Icon(Icons.sync)),
                  )
          ],
        ),
        body: Container(
          // padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints.expand(),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Column(
            children: [
              PanelHeading(assignments: assignments),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: const [
                    SizedBox(height: 15),
                    OutletSync(),
                    SizedBox(height: 15),
                    ProductSync(),
                    SizedBox(height: 15),
                    SubstituteSync(),
                    SizedBox(height: 15),
                    RequestSubstitutions()
                  ]),
                ),
              )
            ],
          ),
        ));
  }

  Future<void> syncData() async {
    bool? shouldDownload = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Sync Data"),
              content: const Text(
                  "Are you sure you want to Sync Data With The Server? All your current changes will be uploaded and merged with the server data."),
              actions: [
                TextButton(
                  child:
                      const Text("Yes", style: TextStyle(color: Colors.green)),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
                TextButton(
                  child: const Text("No", style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.pop(ctx, false),
                ),
              ],
            ));

    //confirmation check
    if (shouldDownload != true) {
      return;
    }

    try {
      //start loading process
      setState(() {
        isLoading = true;
        loadingMessage = 'Syncing Data';
      });

      //Verify if its a new period and if it is a new time period clear all data

      bool isNewTimePeriod = false;

      //get the current time period of the assignments if any
      int totalAssignments = ref.read(assignmentsProvider).assignments.length;

      if (totalAssignments > 0) {
        //Get the current time period from the system
        String currentTimePeriod = await Global.getCurrentTimePeriod();

        //Get the Current time period from the first assignment in the list
        String firstAssignmentTimePeriod =
            ref.read(assignmentsProvider).assignments[0].timePeriod;

        if (currentTimePeriod != firstAssignmentTimePeriod) {
          //clear all the data in the application and simply download the data
          isNewTimePeriod = true;
        }
      }

      //If it is a new time period or there are no assignments, then we clear all the data
      //otherwise we upload before downloading the data
      //NOTE: Varieties will be downloaded only once upon new Period and initial sync
      //NOTE: Outlets will always be replaced upon Sync Data

      if (isNewTimePeriod == true || totalAssignments == 0) {
        //------------------NEW PERIOD AND INITIAL SYNC ONLY-------------------------

        // clean all the substitutions
        if (mounted) {
          setState(() => loadingMessage = "Clearing Substitutions...");
        }

        await ref.read(substitutionsProvider).clearSubstitutions();

        //clean all the assignments
        if (mounted) {
          setState(() => loadingMessage = "Clearing Assignments...");
        }
        await ref.read(assignmentsProvider).clearAssignments();

        //download the varieties from the server
        if (mounted) {
          setState(() => loadingMessage = "Downloading Varieties...");
        }
        await ref.read(varietiesProvider).downloadVarieties();

        //------------------NEW PERIOD AND INITIAL SYNC ONLY-------------------------

      } else {
        //------------------DATA UPLOAD START-------------------------

        //upload the outlets to the server
        if (mounted) {
          setState(() => loadingMessage = "Uploading Outlets...");
        }

        await ref.read(outletsProvider).uploadOutlets();

        //upload the varieties to the server
        if (mounted) {
          setState(() => loadingMessage = "Uploading Varieties...");
        }

        await ref.read(varietiesProvider).uploadVarieties();

        //upload the substitutions to the server
        if (mounted) {
          setState(() => loadingMessage = "Uploading Substitutions...");
        }

        await ref.read(substitutionsProvider).uploadSubstitutions();

        //upload the assignments to the server
        if (mounted) {
          setState(() => loadingMessage = "Uploading Assignments...");
        }

        await ref.read(assignmentsProvider).uploadAssignments();

        //upload the request for substitutions to the server
        if (mounted) {
          setState(
              () => loadingMessage = "Uploading Requested Substitutions...");
        }

        await ref.read(assignmentsProvider).uploadRequestedSubstitutions();

        //------------------DATA UPLOAD END-------------------------

      }

      //------------------DATA DOWNLOAD START-------------------------

      //download the outlets from the server: create if not existing
      if (mounted) {
        setState(() => loadingMessage = "Downloading Outlets...");
      }

      await ref.read(outletsProvider).downloadOutlets();

      //download the assignments from the server: create or update if existing
      if (mounted) {
        setState(() => loadingMessage = "Downloading Assignments...");
      }
      await ref.read(assignmentsProvider).downloadAssignments();

      //------------------DATA DOWNLOAD END ---------------------------

      // REPORT SYNCING TO THE API
      if (mounted) {
        setState(() => loadingMessage = "Reporting Sync...");
      }
      await ref.read(assignmentsProvider).reportSyncToApi();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Sync was completed Successfully!",
            style: TextStyle(color: Colors.green)),
      ));

      // ERROR HANDLING INCASE OF HTTP FAILURE

    } on HttpException catch (e) {
      print(e);

      if (!mounted) return;

      //check if the user is authenticated and if not then logout
      if (e.status == 401) {
        //Clear localStorage
        UtilityFunctions().logUserOut();
        //Navigate to login page
        Navigator.of(context).popAndPushNamed(LoginScreen.routeName);

        //otherwise just show an error message
      }
      //check if the user is authenticated and if not then logout
      else if (e.status == 403) {
        //Clear localStorage
        UtilityFunctions().logUserOut();
        //Navigate to login page
        Navigator.of(context).popAndPushNamed(LoginScreen.routeName);

        //otherwise just show an error message
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("Failed to Sync Data!", style: TextStyle(color: Colors.red)),
        ));
      }

      //catch any other errors
    } catch (e) {
      print(e);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text("Failed to Sync Data!", style: TextStyle(color: Colors.red)),
      ));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        setState(() => loadingMessage = "");
      }
    }
  }
}

class PanelHeading extends StatelessWidget {
  final List<Assignment> assignments;
  const PanelHeading({Key? key, required this.assignments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.cyan.shade800,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child:
          Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        const Text("Sync Panel",
            style: TextStyle(fontSize: 30, color: Colors.white)),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              flex: 1,
              child: Column(children: [
                TextButton(
                  onPressed: () {
                    if (assignments.length > 0) {
                      Navigator.of(context).pushNamed(OutletScreen.routeName);
                    }
                  },
                  child: const Text("Outlets",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                (Consumer(
                  builder: ((context, ref, child) {
                    return Text(
                        ref.watch(outletsProvider).outlets.length.toString(),
                        style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.secondary));
                  }),
                )),
              ]),
            ),
            Expanded(
              flex: 1,
              child: Column(children: [
                TextButton(
                  onPressed: () {
                    if (assignments.length > 0) {
                      Navigator.of(context).pushNamed(HomeScreen.routeName);
                    }
                  },
                  child: const Text("Assignments",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                (Consumer(
                  builder: ((context, ref, child) {
                    return Text(
                        ref
                            .watch(assignmentsProvider)
                            .assignments
                            .length
                            .toString(),
                        style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.secondary));
                  }),
                )),
              ]),
            ),
            Expanded(
              flex: 1,
              child: Column(children: [
                TextButton(
                  onPressed: () {
                    if (assignments.length > 0) {
                      Navigator.of(context)
                          .pushNamed(SubstitutionsScreen.routeName);
                    }
                  },
                  child: const Text("Substitutes",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                (Consumer(
                  builder: ((context, ref, child) {
                    return Text(
                        ref
                            .watch(substitutionsProvider)
                            .substitutions
                            .length
                            .toString(),
                        style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.secondary));
                  }),
                )),
              ]),
            )
          ],
        ),
      ]),
    );
  }
}
