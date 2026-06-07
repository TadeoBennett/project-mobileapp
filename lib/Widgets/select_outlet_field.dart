import 'package:cpi_app/models/outlet.dart';
import 'package:flutter/material.dart';
import 'package:select_dialog/select_dialog.dart';

class SelectOutletField extends StatelessWidget {
  final List<Outlet> outletOptions;
  final Outlet? selectedOutlet;
  final Function onSelect;
  const SelectOutletField(
      {Key? key,
      required this.outletOptions,
      required this.selectedOutlet,
      required this.onSelect})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      width: double.infinity,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              onPrimary: Colors.white, primary: Colors.blue),
          onPressed: () => selectOtherOutlet(context),
          child: Container(
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.business_center),
                Flexible(
                    child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        child:
                            Text(selectedOutlet?.estName ?? "Select Outlet"))),
                const Icon(Icons.arrow_drop_down)
              ],
            ),
          )),
    );
  }

  //Shows a dialog to select Outlet to substitute From (Select Outlet Dialog)
  void selectOtherOutlet(context) {
    int selectedOutletId =
        selectedOutlet == null ? -1 : selectedOutlet!.outletId;

    SelectDialog.showModal<Outlet>(
      context,
      alwaysShowScrollBar: true,
      label: "Select Outlet to substitute From",
      // items: outletOptions,
      items: outletOptions,
      constraints: const BoxConstraints(maxHeight: 450),
      searchBoxDecoration: const InputDecoration(
        hintText: "Search by outlet name",
      ),
      itemBuilder: (BuildContext context, Outlet item, bool isSelected) {
        return Container(
          decoration: !isSelected
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
          child: ListTile(
            selected: selectedOutletId == item.outletId,
            title: Text(item.estName),
            subtitle: Text(item.address ?? ''),
          ),
        );
      },
      onChange: (Outlet outlet) {
        onSelect(outlet);
      },
    );
  }
}
