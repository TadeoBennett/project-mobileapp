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

class SubstitutionsScreen extends ConsumerStatefulWidget {
  static String routeName = '/substitutions';
  const SubstitutionsScreen({Key? key}) : super(key: key);

  @override
  SubstitutionsScreenState createState() => SubstitutionsScreenState();
}

class SubstitutionsScreenState extends ConsumerState<SubstitutionsScreen> {
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
    //Get the current assignments that are to be substituted
    List<Assignment> outletAssignments =
        ref.watch(assignmentsProvider).assignments.where((assignment) {
      return (assignment.canSubstitute == 1 ||
              assignment.requestSubstitute == 1) &&
          ("${assignment.varietyName} ${assignment.outletName}")
              .toLowerCase()
              .contains(search.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Substitutions"),
      ),
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
        child: Column(
          children: [
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
            Expanded(
              child: outletAssignments.isEmpty
                  ? emptyOutlet(context)
                  : ListView.builder(
                      itemCount: outletAssignments.length,
                      itemBuilder: ((cxt, index) {
                        return AssignmentItem(
                          assignment: outletAssignments[index],
                          showOutletName: true,
                        );
                      })),
            )
          ],
        ),
      ),
    );
  }

  Widget emptyOutlet(BuildContext context) {
    return Center(
      child: Text(
        'No Substitution Available!',
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary),
      ),
    );
  }
}
