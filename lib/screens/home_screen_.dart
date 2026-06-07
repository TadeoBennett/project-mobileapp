import 'package:cpi_app/Widgets/download_button.dart';
import 'package:cpi_app/helpers/auth.dart';
import 'package:cpi_app/helpers/utility_functions.dart';
import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/user.dart';
import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:cpi_app/providers/substitutions.dart';
import 'package:cpi_app/providers/varieties.dart';
import 'package:cpi_app/screens/login_screen.dart';
import 'package:cpi_app/screens/outlet_map_screen.dart';
import 'package:cpi_app/screens/outlets_screen.dart';
import 'package:cpi_app/screens/substitution_screen.dart';
import 'package:cpi_app/screens/sync_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = "/home-screen";

  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  bool isDownloading = false;

  UserAuth userAuth = UserAuth();

  @override
  void initState() {
    super.initState();

    setState(() => isDownloading = true);
    initializeData().catchError((err) {
      print(err);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text("Failed to Initialize Assignment Data! Download Data Again!"),
      ));
      setState(() => isDownloading = false);
    });
  }

  Future<void> initializeData() async {
    await ref.read(outletsProvider).initialize();
    await ref.read(assignmentsProvider).initialize();
    await ref.read(varietiesProvider).initialize();
    await ref.read(substitutionsProvider).initialize();
    setState(() => isDownloading = false);
  }

  void setIsDownloading(bool loading) {
    setState(() => isDownloading = loading);
  }

  Future<bool?> showMyDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    'Please be aware that you will lose all information. it is highly recommended to sync your information before signing out. '),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Proceed'),
              onPressed: () {
                Navigator.of(ctx).pop(true);
              },
            ),
            TextButton(
              child: const Text('cancel'),
              onPressed: () {
                Navigator.of(ctx).pop(false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalAssignment = ref.watch(assignmentsProvider).assignments.length;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        bottomOpacity: 0.0,
        actions: [
          PopupMenuButton(
              onCanceled: () => {},
              onSelected: (value) async {
                if (value == 'logout') {
                  print("Logged out");

                  bool? proceed = await showMyDialog();

                  print("LOOADOASDASDASDASD");

                  if (proceed != true) {
                    return;
                  }

                  // clear data and user information and navigate out
                  // Clear user information
                  UserAuth().clearUserInformation();

                  // delete all the current assignments
                  await ref.read(assignmentsProvider).clearAssignments();
                  // delete all current substitutions
                  await ref.read(substitutionsProvider).clearSubstitutions();
                  // delete all current varieties
                  await ref.read(varietiesProvider).clearVarieties();
                  // delete all current outlets
                  await ref.read(outletsProvider).clearOutlets();

                  if (mounted) {
                    Navigator.of(context)
                        .popAndPushNamed(LoginScreen.routeName);
                  }
                }
              },
              itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: "logout",
                      child: Row(children: const [
                        Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 3),
                        Text("Log Out")
                      ]),
                    )
                  ])
        ],
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              ...welcomeMessage(totalAssignment),
              ...(totalAssignment > 0 ? dashboardButtons(context) : []),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> welcomeMessage(totalAssignment) {
    User? user = userAuth.user();
    String? userName = user?.username ?? "";

    return [
      const SizedBox(
        height: 10,
      ),
      Text(
        "Welcome, $userName",
        style: const TextStyle(
          color: Colors.white,
          fontFamily: "LobsterTwo",
          fontSize: 30,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(
        height: 20,
      ),
      totalAssignment == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Please Download your assignments to Proceed!",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(SyncScreen.routeName);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(180, 120),
                      primary: Colors.black12,
                      // put the width and height you want
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_sync,
                          color: Colors.blue.shade200,
                          size: 50,
                        ),
                        const Text('Data Sync')
                      ],
                    ),
                  ),
                )
              ],
            )
          : const SizedBox(height: 0),
    ];
  }

  List<Widget> dashboardButtons(BuildContext context) {
    return [statistics(), dashButtons(), mapViewButton()];
  }

  Widget statistics() {
    List<Assignment> assignments = ref.watch(assignmentsProvider).assignments;

    int completedAssignments = assignments
        .where((assignment) =>
            assignment.newPrice != null || assignment.isSubstituted == 1)
        .length;

    int products = assignments.length;
    int completed = completedAssignments;
    int pending = products - completedAssignments;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <
          Widget>[
        statItem(Colors.amber.shade300, "Products", Icons.category, products),
        statItem(
            Colors.lightGreen.shade300, "Completed", Icons.done_all, completed),
        statItem(Colors.redAccent.shade100, "Pending", Icons.pending_actions,
            pending),
      ]),
    );
  }

  Widget statItem(Color color, String category, IconData icon, int amount) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        // color: color,
      ),
      child: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(
            category,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
          Text(amount.toString(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))
        ],
      )),
    );
  }

  Widget dashButtons() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                NavigationButton(
                    color: Colors.amberAccent.shade200,
                    icon: Icons.business_center,
                    label: 'Outlets',
                    routeName: OutletScreen.routeName),
                NavigationButton(
                    color: Colors.blue.shade200,
                    icon: Icons.cloud_sync,
                    label: 'Data Sync',
                    routeName: SyncScreen.routeName),
              ]),
          Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
            NavigationButton(
                color: Colors.red.shade200,
                icon: Icons.swap_horiz_rounded,
                label: 'Substitutions',
                routeName: SubstitutionsScreen.routeName),
          ])
        ],
      ),
    );
  }

  //used upon trying to access the map
  Future<void> openMap() async {
    //Verifies if location access is enabled. If not, prompts user to enable it.
    bool isLocationEnabled = await UtilityFunctions().locationEnabled();
    if (mounted && isLocationEnabled) {
      Navigator.of(context).pushNamed(OutletMapScreen.routeName);
    }
  }

  Widget mapViewButton() {
    return InkWell(
      onTap: openMap,
      child: Container(
        height: 150,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black,
          image: const DecorationImage(
              image: AssetImage("lib/assets/images/mapshot.png"),
              fit: BoxFit.cover),
        ),
      ),
      // splashColor: Colors.black,
    );
  }
}

class NavigationButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String routeName;

  const NavigationButton(
      {Key? key,
      required this.color,
      required this.icon,
      required this.label,
      required this.routeName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed(routeName);
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(180, 120),
            primary: Colors.black12,
            // put the width and height you want
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 50,
              ),
              Text(label)
            ],
          ),
        ),
      ),
    );
  }
}
