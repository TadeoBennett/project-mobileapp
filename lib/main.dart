import 'package:cpi_app/helpers/auth.dart';
import 'package:cpi_app/screens/edit_assignment_screen.dart';
import 'package:cpi_app/screens/home_screen_.dart';
import 'package:cpi_app/screens/login_screen.dart';
import 'package:cpi_app/screens/outlet_assignments_screen.dart';
import 'package:cpi_app/screens/outlet_map_screen.dart';
import 'package:cpi_app/screens/outlets_screen.dart';
import 'package:cpi_app/screens/substitution_screen.dart';
import 'package:cpi_app/screens/sync_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  'This channel is used for important notifications.', // description
  importance: Importance.max,
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

// used to handle messages when the app is in the foreground
Future<void> onMessageHandler(RemoteMessage message) async {
  // RemoteNotification? notification = message.notification;
  // AndroidNotification? android = message.notification?.android;

  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();

  // await flutterLocalNotificationsPlugin
  //     .resolvePlatformSpecificImplementation<
  //         AndroidFlutterLocalNotificationsPlugin>()
  //     ?.createNotificationChannel(channel);

  // print("NOTIFICATION");
  // print(notification);
  // print(android);

  // if (notification != null) {
  //   flutterLocalNotificationsPlugin.show(
  //       notification.hashCode,
  //       notification.title,
  //       notification.body,
  //       NotificationDetails(
  //         android: AndroidNotificationDetails(
  //           channel.id, channel.name, channel.description,
  //           icon: android?.smallIcon,
  //           //  priority: Priority.high
  //           // other properties...
  //         ),
  //       ));

  // show notification on screen

  // }
}

Future<void> setupFirebaseMessaging() async {
  // Wait for Firebase to initialize and set `_initialized` state to true
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // on background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // on open app message handler
  FirebaseMessaging.onMessage.listen(onMessageHandler);
}

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Used for local get_storage
  await GetStorage.init();

  await setupFirebaseMessaging();

  //Scope used for RiverPod state management
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.

  @override
  void initState() {
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage: $message");
      if (message.notification != null && navigatorKey.currentContext != null) {
        showDialog(
            context: navigatorKey.currentContext as BuildContext,
            builder: (_) => AlertDialog(
                  title: Text(message.notification!.title!),
                  content: Text(message.notification!.body!),
                ));
      }
    });

    super.initState();
    
  }

  @override
  Widget build(BuildContext context) {
    print("STARTING MAIN");

    return MaterialApp(
      title: 'CPI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: Colors.amber[500],
          primary: const Color.fromRGBO(2, 70, 72, 1),
        ),
        backgroundColor: Colors.white,
        primaryTextTheme: const TextTheme(
          bodyText2: TextStyle(
            fontFamily: "OpenSans",
            color: Colors.white,
            fontSize: 22,
          ),
          headline6: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          color: Color.fromRGBO(2, 70, 72, 1),
          elevation: 2,
          iconTheme: IconThemeData(color: Colors.white),
          toolbarTextStyle: TextStyle(
            fontFamily: "OpenSans",
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      navigatorKey: navigatorKey,
      home: UserAuth().user() == null ? LoginScreen() : const HomeScreen(),
      initialRoute: '/',
      routes: {
        LoginScreen.routeName: (context) => LoginScreen(),
        OutletScreen.routeName: ((context) => const OutletScreen()),
        HomeScreen.routeName: ((context) => const HomeScreen()),
        OutletScreen.routeName: ((context) => const OutletScreen()),
        OutletAssignmentsScreen.routeName: ((context) =>
            const OutletAssignmentsScreen()),
        SyncScreen.routeName: ((context) => const SyncScreen()),
        SubstitutionsScreen.routeName: ((context) =>
            const SubstitutionsScreen()),
        OutletMapScreen.routeName: ((context) => const OutletMapScreen()),
      },
    );
  }
}
