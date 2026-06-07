import 'package:cpi_app/helpers/utility_functions.dart';
import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/outlet.dart';
import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:cpi_app/screens/outlet_assignments_screen.dart';
import 'package:cpi_app/screens/outlet_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/route_manager.dart';

final missingCoordinateValue = [0, '', '0', null];

class OutletItem extends ConsumerStatefulWidget {
  final Outlet outlet;

  const OutletItem({
    Key? key,
    required this.outlet,
  }) : super(key: key);

  @override
  ConsumerState<OutletItem> createState() => _OutletItemState();
}

class _OutletItemState extends ConsumerState<OutletItem> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final outletProvider = ref.read(outletsProvider);

    bool missingCoordinates = false;

    if (missingCoordinateValue.contains(widget.outlet.lat) ||
        missingCoordinateValue.contains(widget.outlet.long)) {
      missingCoordinates = true;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(OutletAssignmentsScreen.routeName,
            arguments: widget.outlet.outletId);
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), color: Colors.white),
        child: Consumer(builder: ((context, ref, child) {
          List<Assignment> assignments =
              ref.watch(assignmentsProvider).assignments;

          int pending = assignments
              .where((assignment) =>
                  (assignment.newPrice == null) &&
                  assignment.isSubstituted == 0 &&
                  (assignment.outletId == widget.outlet.outletId))
              .toList()
              .length;

          Widget subtitle = Text(
            'Pending assignments: $pending',
            style: const TextStyle(color: Colors.red),
          );

          Icon icon = const Icon(Icons.chevron_right);

          if (pending == 0) {
            if (widget.outlet.isNew == 0) {
              icon = const Icon(
                Icons.done,
                size: 40,
                color: Colors.green,
              );
            }

            subtitle = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon(Icons.done, color: Colors.green),
                const SizedBox(width: 2),
                if (widget.outlet.isNew == 1)
                  const Text(
                    'New Outlet!',
                    style: TextStyle(color: Colors.green),
                  ),
              ],
            );
          }

          return ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.white,
                  child: IconButton(
                      icon: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        bool isLocationEnabled =
                            await UtilityFunctions().locationEnabled();
                        if (mounted && isLocationEnabled) {
                          Navigator.of(context).pushNamed(
                              OutletMapScreen.routeName,
                              arguments: widget.outlet.outletId);
                        }
                      }),
                ),
                Material(
                  color: Colors.white,
                  child: IconButton(
                      icon: isLoading
                          ? const CircularProgressIndicator()
                          : Icon(
                              missingCoordinates
                                  ? Icons.add_location_alt
                                  : Icons.edit_location_alt,
                              color: Colors.amber),
                      onPressed: isLoading
                          ? null
                          : () async {
                              bool? shouldProceed = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Update Coordinates'),
                                  content: const Text(
                                      'Are you sure you want to update the coordinates of this outlet?'),
                                  actions: [
                                    TextButton(
                                      child: const Text('Yes'),
                                      onPressed: () {
                                        Navigator.of(ctx).pop(true);
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('No'),
                                      onPressed: () {
                                        Navigator.of(ctx).pop(false);
                                      },
                                    ),
                                  ],
                                ),
                              );

                              if ([null, false].contains(shouldProceed)) {
                                return;
                              }

                              setState(() {
                                isLoading = true;
                              });

                              try {
                                await outletProvider
                                    .updateLocation(widget.outlet.outletId);

                                if (!mounted) return;
                                showSuccessSnackbar(context);
                              } catch (e) {
                                if (!mounted) return;
                                showChangeLocationErrorMessage(e, context);
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            }),
                ),
              ],
            ),
            title: Text(
              widget.outlet.estName,
            ),
            subtitle: subtitle,
            trailing: Material(
              color: Colors.white,
              child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                        OutletAssignmentsScreen.routeName,
                        arguments: widget.outlet.outletId);
                  },
                  icon: icon),
            ),
          );
        })),
      ),
    );
  }

  void showChangeLocationErrorMessage(e, ctx) {
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text('Location Error'),
        content: Text(e.toString()),
        actions: [
          FlatButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void showSuccessSnackbar(ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Location updated successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
