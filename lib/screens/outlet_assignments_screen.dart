import 'dart:async';

import 'package:cpi_app/Widgets/assignment_item.dart';
import 'package:cpi_app/Widgets/new_outlet.dart';
import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/outlet.dart';
import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/route_manager.dart';

class OutletAssignmentsScreen extends ConsumerStatefulWidget {
  static String routeName = '/outlet-assignments';
  const OutletAssignmentsScreen({Key? key}) : super(key: key);

  @override
  OutletAssignmentsScreenState createState() => OutletAssignmentsScreenState();
}

class OutletAssignmentsScreenState
    extends ConsumerState<OutletAssignmentsScreen> {
//used to create/edit a new outlet
  void editOutlet(BuildContext context) {
    //Get the current outletId From Route Arguments
    final int outletId = ModalRoute.of(context)!.settings.arguments as int;
    Outlet? outlet = ref.watch(outletsProvider).getOutletById(outletId);

    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (cxt) => NewOutletForm(outlet));
  }

  // String That is used to search Filter the outlets
  String search = "";

  // Search Feature START
  Timer? _debounce;

  _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        search = query;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
  // Search Feature END

  @override
  Widget build(BuildContext context) {
    //Get the current outletId From Route Arguments
    final int outletId = ModalRoute.of(context)!.settings.arguments as int;
    Outlet? outlet = ref.watch(outletsProvider).getOutletById(outletId);

    //Get the current assignments for the current outlet
    List<Assignment> outletAssignments =
        ref.watch(assignmentsProvider).assignments.where((assignment) {
      return assignment.outletId == outlet.outletId &&
          assignment.varietyName.toLowerCase().contains(search.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        // title: Text(outlet.estName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              editOutlet(context);
            },
          ),
        ],
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.end,
            children: [
              storeDetails(context, outlet),
              storeStatistics(context, outlet),
              Container(
                  margin: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: TextField(
                    decoration: const InputDecoration(
                      label: Text("Search"),
                      icon: Icon(
                        Icons.search,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  )),
              outletAssignments.isEmpty
                  ? emptyOutlet(context)
                  : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: outletAssignments.length,
                      itemBuilder: ((cxt, index) {
                        return AssignmentItem(
                            assignment: outletAssignments[index]);
                      })),
            ],
          ),
        ),
      ),
    );
  }

  Widget emptyOutlet(BuildContext context) {
    return Center(
      child: Text(
        'No Assignments Available!',
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary),
      ),
    );
  }

  Widget storeDetails(BuildContext context, Outlet outlet) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 35,
        right: 10,
        top: 10,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 25),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.amber[300],
              child: Icon(
                Icons.store,
                size: 55,
                color: Theme.of(context).primaryColor,
              ),
              // backgroundColor: Colors.amber[300],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      outlet.estName,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        outlet.address ?? 'No Address',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.phone, color: Colors.white, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        ['0', '', null].contains(outlet.phone)
                            ? ' No Phone'
                            : outlet.phone,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget storeStatistics(BuildContext context, outlet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Consumer(
        builder: ((context, ref, child) {
          //Get the current assignments for the current outlet
          List<Assignment> outletAssignments = ref
              .watch(assignmentsProvider)
              .assignments
              .where((assignment) => assignment.outletId == outlet.outletId)
              .toList();

          print(outletAssignments);

          //total number of assignments
          int totalAssignments = outletAssignments.length;

          //total number of assignments completed
          int completedAssignments = outletAssignments
              .where((assignment) =>
                  assignment.newPrice != null || assignment.isSubstituted == 1)
              .length;

          //total number of assignments pending
          int pendingAssignments = totalAssignments - completedAssignments;

          return Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Items',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '$totalAssignments',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 15),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Completed',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '$completedAssignments',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 15),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pending',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    '$pendingAssignments',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 15),
                  ),
                ],
              )
            ],
          );
        }),
      ),
    );
  }
}
