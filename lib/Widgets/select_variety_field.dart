import 'package:cpi_app/models/outlet.dart';
import 'package:cpi_app/models/variety.dart';
import 'package:flutter/material.dart';
import 'package:select_dialog/select_dialog.dart';

class SelectVarietyField extends StatelessWidget {
  final List<Variety> varietyOptions;
  final Variety? selectedVariety;
  final Function onSelect;
  const SelectVarietyField(
      {Key? key,
      required this.varietyOptions,
      required this.selectedVariety,
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
          onPressed: () => selectVariety(context),
          child: Container(
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.shopping_basket),
                Flexible(
                    child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        child:
                            Text(selectedVariety?.name ?? "Select Variety"))),
                const Icon(Icons.arrow_drop_down)
              ],
            ),
          )),
    );
  }

  //Shows a dialog to select Variety to substitute From (Select Variety Dialog)
  void selectVariety(context) {
    //used to get the selected variety id even if null for null cases
    int selectedVarietyId =
        selectedVariety == null ? -1 : selectedVariety!.varietyId;

    //used for ui purposes
    Variety newVariety =
        Variety(varietyId: 0, name: "New Variety", code: "", isNew: 1);

    newVariety.brand = '';
    newVariety.quantity = null;
    newVariety.unit = null;
    newVariety.countryOfOrigin = null;
    newVariety.additionalSpecs = '';

    SelectDialog.showModal<Variety>(
      context,
      alwaysShowScrollBar: true,
      label: "Select a product variety",
      items: [...varietyOptions, newVariety],
      constraints: const BoxConstraints(maxHeight: 450),
      searchBoxDecoration: const InputDecoration(
        hintText: "Search by variety name",
      ),
      itemBuilder: (BuildContext context, Variety item, bool isSelected) {
        //This allows the user to add another variety by adding a button to the dropdown
        if (item.varietyId == 0) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: TextButton.icon(
                onPressed: () {
                  onSelect(item);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.add),
                label: const Text("ADD NEW VARIETY")),
          );
        }
        return Container(
          decoration: selectedVarietyId != item.varietyId
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
          child: ListTile(
            selected: selectedVarietyId == item.varietyId,
            title: Text(item.name),
            subtitle: Text(item.code),
          ),
        );
      },
      onChange: (Variety val) {
        onSelect(val);
      },
    );
  }
}
