import 'dart:async';

import 'package:cpi_app/Widgets/new_outlet.dart';
import 'package:cpi_app/Widgets/outlet_item.dart';
import 'package:cpi_app/helpers/auth.dart';
import 'package:cpi_app/models/outlet.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OutletScreen extends ConsumerStatefulWidget {
  static String routeName = '/outlets';

  const OutletScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OutletScreen> createState() => _OutletScreenState();
}

class _OutletScreenState extends ConsumerState<OutletScreen> {
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
    List<Outlet> outlets =
        ref.watch(outletsProvider).getOutletsWithAssignmentsOrNew();

    outlets = outlets.where((element) {
      return element.estName.toLowerCase().contains(search.toLowerCase());
    }).toList();

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Outlets'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                createNewOutlet(context);
              },
            ),
          ],
        ),
        body: Container(
          decoration:
              BoxDecoration(color: Theme.of(context).colorScheme.primary),
          child: Column(
            children: [
              Container(
                  margin: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: TextField(
                    decoration: const InputDecoration(
                      label: Text("Search"),
                      icon: Icon(Icons.search),
                    ),
                    onChanged: _onSearchChanged,
                  )),
              Expanded(
                child: ListView.builder(
                  itemCount: outlets.length,
                  itemBuilder: ((cxt, index) {
                    return OutletItem(outlet: outlets[index]);
                  }),
                ),
              ),
            ],
          ),
        ));
  }

  void createNewOutlet(BuildContext context) {
    //used to create a new outlet
    Outlet placeHolder = Outlet(
        areaId: UserAuth().user()!.areaId,
        outletId: 0,
        address: '',
        estName: '',
        isNew: 1,
        isUploaded: 0,
        failedAutoSync: 0,
        isEdited: 0,
        isCompleted: 0,
        phone: '0');

    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (cxt) => NewOutletForm(placeHolder));
  }
}
