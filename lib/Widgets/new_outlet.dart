import 'package:cpi_app/helpers/auth.dart';
import 'package:cpi_app/helpers/utility_functions.dart';
import 'package:cpi_app/models/outlet.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:cpi_app/validator/new_variety_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewOutletForm extends ConsumerStatefulWidget {
  final Outlet outlet;

  const NewOutletForm(this.outlet, {Key? key}) : super(key: key);

  @override
  ConsumerState<NewOutletForm> createState() => _NewOutletFormState();
}

class _NewOutletFormState extends ConsumerState<NewOutletForm> {
  String estName = '';
  String address = '';
  String phone = '';
  String email = '';
  String? openingTime;
  String? closingTime;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    openingTime = widget.outlet.openingTime;
    closingTime = widget.outlet.closingTime;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || !value.contains(':')) {
      return null;
    }
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  //Function used to save the state of the outlet
  Future<void> submitForm() async {
    try {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        double? lat;
        double? long;

        // if widget is new then add location
        if (widget.outlet.isNew == 1) {
          // Try access Location and get the location values
          bool is_location_enabled = await UtilityFunctions().locationEnabled();

          // if the location was not enabled then return
          if (!is_location_enabled) {
            return;
          }

          //get the location
          Map<String, dynamic> location =
              await UtilityFunctions().getCurrentLocation();

          print(location);

          lat = location['latitude'];
          long = location['longitude'];
        }

        Outlet currentOutlet = Outlet(
            outletId: widget.outlet.outletId,
            areaId: UserAuth().user()!.areaId,
            address: address,
            estName: estName,
            phone: phone,
            isNew: widget.outlet.isNew,
            isUploaded: 0,
            failedAutoSync: 0,
            isEdited: (widget.outlet.outletId == 0 ? 0 : 1),
            isCompleted: 0,
            lat: lat,
            long: long,
            email: email,
            openingTime: openingTime,
            closingTime: closingTime,
            photoLocalPath: widget.outlet.photoLocalPath,
            photoUrl: widget.outlet.photoUrl,
            photoUpdatedAt: widget.outlet.photoUpdatedAt,
            photoNeedsSync: widget.outlet.photoNeedsSync);

        await ref.read(outletsProvider).insertOrUpdate(currentOutlet);

        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                actions: [
                  TextButton(
                      child: const Text('Ok'),
                      onPressed: () {
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      })
                ],
                title: const Text('Error!'),
                content: const Text("Something went wrong, please try again!"),
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          right: 20,
          left: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              newOutletFields(),
            ]),
      ),
    );
  }

  //Displays widget create new Outlet (Create New Outlet)
  Widget newOutletFields() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Text("Outlet Details",
                    style: Theme.of(context).textTheme.headline6)
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration:
                        const InputDecoration(labelText: "Establishment Name"),
                    initialValue: widget.outlet.estName,
                    textInputAction: TextInputAction.next,
                    onSaved: (val) {
                      setState(() {
                        estName = val ?? '';
                      });
                    },
                    validator: (val) {
                      return (val?.isEmpty ?? true
                          ? 'Please enter the establishment name'
                          : null);
                    },
                  ),
                ),
              ],
            ),
            Row(children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: "Address"),
                  textInputAction: TextInputAction.next,
                  initialValue: widget.outlet.address,
                  onSaved: (val) {
                    setState(() {
                      address = val ?? '';
                    });
                  },
                  validator: (val) {
                    return (val?.isEmpty ?? true
                        ? 'Please enter an Address!'
                        : null);
                  },
                ),
              ),
            ]),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: "Phone"),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                    initialValue: widget.outlet.phone == "0"
                        ? ''
                        : widget.outlet.phone.toString(),
                    textInputAction: TextInputAction.next,
                    onSaved: (val) {
                      setState(() {
                        phone = val ?? '';
                      });
                    },
                    validator: (val) {
                      return (val?.isEmpty ?? true
                          ? 'Please enter a Phone Number!'
                          : null);
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration:
                        const InputDecoration(labelText: "Email (optional)"),
                    initialValue:
                        widget.outlet.email == null ? '' : widget.outlet.email,
                    textInputAction: TextInputAction.done,
                    onSaved: (val) {
                      setState(() {
                        email = val ?? '';
                      });
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: "Opening Time",
                        suffixIcon: Icon(Icons.access_time)),
                    controller: TextEditingController(text: openingTime ?? ''),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime:
                            _parseTime(openingTime) ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          openingTime = _formatTimeOfDay(picked);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: "Closing Time",
                        suffixIcon: Icon(Icons.access_time)),
                    controller: TextEditingController(text: closingTime ?? ''),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime:
                            _parseTime(closingTime) ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          closingTime = _formatTimeOfDay(picked);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                ElevatedButton(
                  child: Row(children: const [
                    Text('  Save   '),
                    Icon(Icons.save_outlined)
                  ]),
                  onPressed: () async {
                    await submitForm();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
