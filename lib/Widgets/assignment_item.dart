import 'package:cpi_app/Widgets/edit_assignment.dart';
import 'package:cpi_app/helpers/auth.dart';
import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/substitute.dart';
import 'package:cpi_app/models/user.dart';
import 'package:cpi_app/models/variety.dart';
import 'package:cpi_app/providers/substitutions.dart';
import 'package:cpi_app/providers/varieties.dart';
import 'package:cpi_app/screens/edit_assignment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssignmentItem extends ConsumerWidget {
  final Assignment assignment;
  final bool showOutletName;

  const AssignmentItem(
      {Key? key, required this.assignment, this.showOutletName = false})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? user = UserAuth().user();

    Substitute? substitute;
    String substituteMessage = '';

    Widget leadingWidget = assignment.canSubstitute == 1
        ? const Icon(
            Icons.swap_vertical_circle_outlined,
            color: Colors.red,
          )
        : const Text(
            "Missing",
            style: TextStyle(color: Colors.red),
          );

    if (assignment.canSubstitute == 0 &&
        assignment.requestSubstitute == 1 &&
        assignment.newPrice == null) {
      leadingWidget = const Icon(
        Icons.sync_lock,
        color: Colors.amber,
      );
    }

    //if there is a substitution it means that the assignment was substituted
    if (assignment.isSubstituted == 1) {
      substitute =
          ref.read(substitutionsProvider).getSubstitution(assignment.id);
      // print(substitute!.newVarietyId);

      Variety newVariety =
          ref.read(varietiesProvider).getVarietyById(substitute!.newVarietyId);

      substituteMessage = 'Substituted: ${newVariety.name}';
      leadingWidget = Text('\$${substitute.price.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.green));
    } else {
      //The assignment was not substituted so we must check if the assignment has a new price
      if (assignment.newPrice != null) {
        leadingWidget = Text('\$${assignment.newPrice!.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green));
      }
    }

    if (user != null && user.userType == "HQ") {
      if (assignment.substitutionVarietyName != null) {
        substituteMessage =
            "- Substituted at: ${assignment.substitutionOutletName} \n"
            "- New variety: ${assignment.substitutionVarietyName}";
      }
      substituteMessage += "\n- Collected: ${assignment.collectorCollectedAt}";
    }

    bool isApproved = assignment.isApprovedByHQ == 1;

    return InkWell(
      onTap: isApproved
          ? null
          : () {
              _openEditForm(context);
            },
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: isApproved ? Colors.green.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [leadingWidget],
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showOutletName)
                  Text(
                    assignment.outletName ?? "",
                    textAlign: TextAlign.start,
                    // assignment.collectedAt ?? "DDD",
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                Text(
                  assignment.varietyName,
                  // assignment.collectedAt ?? "DDD",
                  textAlign: TextAlign.start,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            subtitle: Text(substituteMessage,
                style: const TextStyle(
                    color: Color.fromARGB(255, 145, 137, 129), fontSize: 12)),
            trailing: isApproved
                ? null
                : Material(
                    color: Colors.white,
                    child: IconButton(
                        onPressed: isApproved
                            ? null
                            : () {
                                // Navigator.of(context).pushNamed(EditAssignmentScreen.routeName, arguments:  assignment );
                                _openEditForm(context);
                              },
                        icon: const Icon(Icons.edit)),
                  )),
      ),
    );
  }

  void _openEditForm(BuildContext context) {
    print("Selected value: 123123");
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => EditAssignmentWidget(assignment: assignment));
    // builder: (ctx) => EditAssignmentScreen(assignment: assignment));
  }
}
