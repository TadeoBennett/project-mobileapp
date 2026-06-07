import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/globals.dart';
import 'package:cpi_app/models/outlet.dart';
import 'package:cpi_app/models/substitute.dart';
import 'package:cpi_app/models/variety.dart';
import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:cpi_app/providers/substitutions.dart';
import 'package:cpi_app/providers/varieties.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:select_dialog/select_dialog.dart';
import 'package:select_form_field/select_form_field.dart';
import '../validator/new_variety_validator.dart';
import 'package:cpi_app/helpers/utility_values.dart';

class EditAssignmentScreen extends ConsumerStatefulWidget {
  Assignment assignment;

  EditAssignmentScreen({Key? key, required this.assignment}) : super(key: key);

  @override
  ConsumerState<EditAssignmentScreen> createState() =>
      _EditAssignmentScreenState();
}

class _EditAssignmentScreenState extends ConsumerState<EditAssignmentScreen> {
  double newPrice = 0; //used to get the new price (Perfect match)
  String newComment = ""; //used to get the new price (Perfect match)
  double priceDifferencePercentage =
      0; //used to get the new price (Perfect match)

  bool requestedSubstitute = false;

  bool isSubstitute =
      false; //used to determine if the assignment is substituted or not
  String substituteFrom =
      ""; //used to determine from where the assignment is coming from current/other store
  int?
      selectedVarietyId; //used to determine to which variety was selected by Id
  Variety? selectedVariety; //used to determine to which variety was selected
  int? selectedOutletId; //used to determine to which variety was selected by Id
  Outlet? selectedOutlet; //used to determine to which outlet was selected
  bool createNewVariety =
      false; //used to determine if new variety should be created

  //state variables for new variety form items
  TextEditingController newVarietyProduct = TextEditingController(text: '');
  TextEditingController newVarietyBrand = TextEditingController(text: '');
  TextEditingController newVarietySpecification =
      TextEditingController(text: '');
  TextEditingController newVarietyMeasurement = TextEditingController(text: '');
  TextEditingController newVarietyUnit = TextEditingController(text: '');
  TextEditingController newVarietyPrice = TextEditingController(text: '');
  TextEditingController newVarietyCountry = TextEditingController(text: '');

  //state variables for new outlet
  String? estName;
  String? address;
  String? phone;

  List<Variety> varietyOptions = [];
  List<Outlet> outletOptions = [];

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); //used to manage the form

  @override
  void initState() {
    setState(() {
      varietyOptions = ref
          .read(varietiesProvider)
          .getVarietiesWithSameCode(widget.assignment);

      List<Outlet> tempOutlets = ref.read(outletsProvider).outlets;

      tempOutlets.removeWhere(
          (element) => element.outletId == widget.assignment.outletId);

      outletOptions = tempOutlets;

      //populate the form based on assignment defaults
      newPrice = widget.assignment.newPrice ?? 0;

      if (widget.assignment.requestSubstitute == 1) {
        requestedSubstitute = true;
      }

      //check if assignment has been substituted
      if (widget.assignment.isSubstituted == 1) {
        //find substitute which relates to this assignment
        Substitute? substitute = ref
            .read(substitutionsProvider)
            .getSubstitution(widget.assignment.id);

        //if the assignment has been substituted then the substitution should be presented
        if (substitute != null) {
          setState(() {
            isSubstitute = true;
            selectedVarietyId = substitute.newVarietyId;
            selectedVariety = ref
                .read(varietiesProvider)
                .getVarietyById(substitute.newVarietyId);

            // We need to get the form values from the selected variety if new
            if (selectedVariety!.isNew == 1) {
              print(selectedVariety!.brand);
              print(
                  "selectedVariety!.brandselectedVariety!.brandselectedVariety!.brand");

              // newVarietyProduct = selectedVariety!.name;
              newVarietyBrand.text = selectedVariety!.brand ?? '';
              newVarietySpecification.text =
                  selectedVariety!.additionalSpecs ?? '';
              newVarietyMeasurement.text =
                  (selectedVariety!.quantity ?? '').toString();
              newVarietyUnit.text = selectedVariety!.unit ?? '';
              newVarietyPrice.text = substitute.price.toString();
              newVarietyCountry.text = selectedVariety!.countryOfOrigin ?? '';

              // opens the form to create a new variety
              createNewVariety = true;
            }

            selectedOutletId = substitute.newOutletId;
            selectedOutlet =
                ref.read(outletsProvider).getOutletById(substitute.newOutletId);
            substituteFrom = substitute.newOutletId == substitute.outletSourceId
                ? "currentStore"
                : "otherStore";
          });
        }
      }
    });

    super.initState();
  }

  Future<bool?> requestPriceComment() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Comment Request"),
        content: Container(
            margin: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(
                            "The Price you Entered is ${priceDifferencePercentage.toStringAsFixed(2)}% different from the previous Price!\nPlease enter a comment to explain the difference.")),
                  ],
                ),
                TextFormField(
                    maxLines: 5,
                    minLines: 1,
                    autofocus: true,
                    keyboardType: TextInputType.multiline,
                    initialValue: widget.assignment.comment ?? '',
                    decoration: const InputDecoration(
                      labelText: "Comment",
                      hintText: "Please enter a comment",
                    ),
                    onChanged: (value) {
                      newComment = value;
                    })
              ],
            )),
        actions: <Widget>[
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text("Continue"),
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  bool isPriceInconsistent() {
    final previousPrice = (widget.assignment.previousPrice ?? 0);

    if (previousPrice == 0) {
      return false;
    } //There is no previous Price so return false

    final priceDifference = newPrice - previousPrice;
    final percentageDifference = ((priceDifference / previousPrice) * 100);

    setState(() {
      priceDifferencePercentage = percentageDifference;
    });

    return priceDifferencePercentage > 25 || priceDifferencePercentage < -25;
  }

  Future<void> showErrorDialog() async {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Error"),
              content:
                  const Text("Something went wrong. Please try again later."),
              actions: [
                TextButton(
                    onPressed: () {
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text("ok"))
              ],
            ));
  }

  //Used to change the price with a (Perfect Match)
  Future<void> updatePrice() async {
    try {
      //Validate Form Fields!
      if (_formKey.currentState!.validate()) {
        // Save the form Fields
        _formKey.currentState!.save();

        print("Saving Value!");

        //Check if the comment is required!
        if (isPriceInconsistent()) {
          //show modal to get comments
          bool? proceed = await requestPriceComment();

          if ([null, false].contains(proceed) || newComment.isEmpty) {
            return;
          }
        }

        //Update the price  of the assignment
        await ref.read(assignmentsProvider).updateAssignmentAndSubstitutePrice(
            widget.assignment,
            newPrice,
            newComment,
            0 //isSubstituted shall be zero for the assignments that are not substituted
            );

        //Remove the substitute if any associated with the assignment
        if (widget.assignment.isSubstituted != 0) {
          await ref
              .read(substitutionsProvider)
              .removeSubstitute(widget.assignment.id);
        }

        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("SOMETHING WENT WRONG");
      print(e);
      await showErrorDialog();
    }
  }

  Future<void> substituteAndUpdatePrice() async {
    try {
      //Validate Form Fields!
      if (_formKey.currentState!.validate()) {
        // Save the form Fields
        _formKey.currentState!.save();

        Variety? newVariety;
        double price = newPrice;

        //Check if the variety is a new one from the current store
        if (createNewVariety && selectedVariety != null) {
          //get heading from the variety name
          String heading = widget.assignment.varietyName.split(' - ')[0];
          //create new variety

          //create the name of the variety
          String name =
              '$heading - ${newVarietyBrand.text}, ${newVarietyUnit.text}, ${newVarietyMeasurement.text}, ${newVarietyCountry.text}, ${newVarietySpecification.text}';

          if (selectedVariety!.varietyId == 0) {
            newVariety = await ref.read(varietiesProvider).createVariety(
                selectedVariety!.varietyId,
                name,
                newVarietyBrand.text,
                newVarietyUnit.text,
                double.parse(newVarietyMeasurement.text),
                newVarietyCountry.text,
                newVarietySpecification.text,
                widget.assignment.code.substring(0, 23));
          } else {
            newVariety = await ref.read(varietiesProvider).updateVariety(
                  selectedVariety!.varietyId,
                  name,
                  newVarietyBrand.text,
                  newVarietyUnit.text,
                  double.parse(newVarietyMeasurement.text),
                  newVarietyCountry.text,
                  newVarietySpecification.text,
                );
          }

          price = double.parse(newVarietyPrice.text);
        }

        //create a substitution record with the accurate information
        // Substitute substitute = await ref.read(substitutionsProvider).insert(
        //     widget.assignment.id,
        //     widget.assignment.outletId,
        //     substituteFrom == 'currentStore'
        //         ? widget.assignment.outletId
        //         : selectedOutletId!, //if the substitute is from the current store, then the newOutletId is the same as the outletId  of the assignment
        //     createNewVariety
        //         ? newVariety!.varietyId
        //         : selectedVarietyId!, //if the variety was created, then the newVarietyId is the new variety's id
        //     price,
        //     'SUBSTITUTED');

        //Substitute and Update the price  of the assignment
        await ref.read(assignmentsProvider).updateAssignmentAndSubstitutePrice(
            widget.assignment, price, newComment, 1);

        print("CREATED SUCCESFULLY !!!!");

        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      print(e);
      await showErrorDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
          padding: EdgeInsets.only(
            right: 20,
            left: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.assignment.canSubstitute == 1
                  ? Container(child: substituteItemButton())
                  : Container(child: requestSubstituteButton()),
              Container(
                  child: Form(
                      key: _formKey,
                      child: isSubstitute
                          ? substituteProduct()
                          : getPriceWidgets())),
            ],
          )),
    );
  }

  //switch used to determine if the assignment is substituted or not
  Widget substituteItemButton() {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Switch(
            onChanged: (value) {
              setState(() {
                isSubstitute = value;
              });
            },
            value: isSubstitute,
          ),
          const Text("Substitute this item"),
        ],
      ),
    );
  }

//switch used to mark as request Substitution
  Widget requestSubstituteButton() {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Switch(
            onChanged: (value) {
              setState(() {
                // requestedSubstitute = value;
                ref
                    .read(assignmentsProvider)
                    .requestSubstitution(widget.assignment.id, value ? 1 : 0);
              });
            },
            value: widget.assignment.requestSubstitute == 1 ? true : false,
          ),
          const Text("Request Substitution"),
        ],
      ),
    );
  }

  //This Widget Function is used to get the price of the product (Perfect Match)
  Widget getPriceWidgets() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(widget.assignment.varietyName,
            style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        TextFormField(
            autofocus: true,
            initialValue: widget.assignment.newPrice == null
                ? ''
                : widget.assignment.newPrice.toString(),
            onSaved: (val) {
              setState(() => newPrice =
                  double.parse(val == null || val == '' ? '0' : val));
            },
            validator: (val) {
              try {
                final tempPrice = double.parse(val ?? '');
                if (tempPrice < 0) {
                  return 'Price cannot be Less than 0!';
                }
                return null;
              } catch (e) {
                return 'Please enter a valid price';
              }
            },
            keyboardType: const TextInputType.numberWithOptions(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.attach_money),
              labelText: 'New Price',
              hintText: widget.assignment.previousPrice == null
                  ? ''
                  : widget.assignment.previousPrice.toString(),
            )),
        const SizedBox(
          height: 15,
        ),
        ElevatedButton(
          onPressed: () {
            updatePrice().then((value) {}).catchError((error) {
              print(error);
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Save'),
              Icon(Icons.check),
            ],
          ),
        ),
      ]),
    );
  }

  //Used to substitute the product (Substitute Item)
  Widget substituteProduct() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(15),
          child: Text("Substitute From...", style: TextStyle(fontSize: 15)),
        ),
        customRadioButton(),
        substituteFrom == "currentStore"
            ? currentStore()
            : const SizedBox(
                height: 15,
              ),
        substituteFrom == "otherStore"
            ? otherStore()
            : const SizedBox(
                height: 15,
              ),
      ],
    );
  }

  //Displays the store buttons (Buttons for current store and other store)
  Widget customRadioButton() {
    final unSelectedButton = ElevatedButton.styleFrom(
        onPrimary: Colors.blue, primary: Colors.grey.shade300);

    final selectedButton = ElevatedButton.styleFrom(
        onPrimary: Colors.white, primary: Colors.amber);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: ElevatedButton(
                onPressed: () {
                  if (substituteFrom == "currentStore") return;
                  setState(() {
                    substituteFrom = 'currentStore';
                  });
                },
                style: substituteFrom == 'currentStore'
                    ? selectedButton
                    : unSelectedButton,
                child: const Text("Current Store")),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
                onPressed: () {
                  if (substituteFrom == "otherStore") return;
                  setState(() {
                    substituteFrom = 'otherStore';
                  });
                },
                style: substituteFrom == 'otherStore'
                    ? selectedButton
                    : unSelectedButton,
                child: const Text("Other Store")),
          ),
        ],
      ),
    );
  }

  //Display select Variety Button
  Widget selectVarietyButton() {
    return Container(
      margin: const EdgeInsets.all(25),
      width: double.infinity,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              onPrimary: Colors.white, primary: Colors.blue),
          onPressed: selectVariety,
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

  //Displays The select Outlet Buttons
  Widget selectOutletButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      width: double.infinity,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              onPrimary: Colors.white, primary: Colors.blue),
          onPressed: () => selectOtherOutlet(),
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

  //Displays the CURRENT store options (Layout for CURRENT store Changes)
  Widget currentStore() {
    Widget formDetails = const SizedBox(height: 10);

    if (selectedVarietyId != null && selectedVariety != null) {
      formDetails = selectedVariety!.isNew == 1 && createNewVariety
          ? newVarietyFields()
          : existingVarietyFields();
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 15,
          ),
          selectVarietyButton(),
          formDetails
        ]);
  }

  //Displays the OTHER store options (Layout for OTHER store Changes)
  Widget otherStore() {
    Widget formDetails = SizedBox(height: 10);

    if (selectedVarietyId != null && selectedVariety != null) {
      formDetails = selectedVariety!.isNew == 1 && createNewVariety
          ? newVarietyFields()
          : existingVarietyFields();
    }

    bool allowSubmission = selectedOutlet != null && selectedVariety != null;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 15,
          ),
          selectOutletButton(),
          selectVarietyButton(),
          allowSubmission ? formDetails : const SizedBox(height: 10),
        ]);
  }

  //Displays the substitute and save button
  Widget substituteAndSaveButton() {
    return ElevatedButton(
      onPressed: () async {
        await substituteAndUpdatePrice();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Save'),
          Icon(Icons.check),
        ],
      ),
    );
  }

  //Displays widget to enter price of an existing variety selected (Simply Enter Price)
  Widget existingVarietyFields() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(25),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        TextFormField(
            initialValue: widget.assignment.newPrice == null
                ? ''
                : widget.assignment.newPrice.toString(),
            keyboardType: TextInputType.number,
            onSaved: (val) {
              setState(() => newPrice =
                  double.parse(val == null || val == '' ? '0' : val));
            },
            validator: (val) {
              try {
                final tempPrice = double.parse(val ?? '');
                if (tempPrice < 0) {
                  return 'Price cannot be Less than 0!';
                }
                return null;
              } catch (e) {
                return 'Please enter a valid price';
              }
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.attach_money),
              labelText: 'New Price',
              hintText: widget.assignment.previousPrice == null
                  ? ''
                  : widget.assignment.previousPrice.toString(),
            )),
        const SizedBox(
          height: 15,
        ),
        substituteAndSaveButton(),
      ]),
    );
  }

  //Displays widget to enter price of a new variety which should be created (Create New Variety With Price)
  Widget newVarietyFields() {
    print(newVarietyBrand.text);
    print("newVarietyBrand.textnewVarietyBrand.textnewVarietyBrand.text");

    return Container(
      margin: const EdgeInsets.all(25),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: newVarietyBrand,
                  decoration: const InputDecoration(labelText: "Brand"),
                  onSaved: (val) {
                    // setState(() {
                    //   newVarietyBrand = val == null ? '' : val.toUpperCase();
                    // });
                  },
                  validator: NewVarietyValidator().brandValidator,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: "Quantity/Size"),
                  // initialValue: (newVarietyMeasurement ?? '').toString(),
                  controller: newVarietyMeasurement,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (val) {
                    // setState(() {
                    //   newVarietyMeasurement = double.parse(val ?? '');
                    // });
                  },
                  validator: NewVarietyValidator().measurementValidator,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: SelectFormField(
                  type: SelectFormFieldType.dropdown, // or can be dialog
                  // initialValue: newVarietyUnit,
                  controller: newVarietyUnit,
                  icon: null,
                  labelText: 'Unit',
                  items: UtilValues.measurementUnits,
                  onChanged: (val) => print(val),
                  onSaved: (val) {
                    // setState(() {
                    //   newVarietyUnit = val;
                    // });
                  },
                  validator: (val) =>
                      val == null ? 'Please select a Unit' : null,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  // initialValue: newVarietyPrice.text,
                  controller: newVarietyPrice,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSaved: (val) {
                    // setState(() => newPrice =
                    //     double.parse(val == null || val == '' ? '0' : val));
                  },
                  validator: (val) {
                    try {
                      final tempPrice = double.parse(val ?? '');
                      if (tempPrice < 0) {
                        return 'Price cannot be Less than 0!';
                      }
                      return null;
                    } catch (e) {
                      return 'Please enter a valid price';
                    }
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: SelectFormField(
                  type: SelectFormFieldType.dropdown, // or can be dialog
                  // initialValue: newVarietyCountry,
                  controller: newVarietyCountry,
                  icon: null,
                  labelText: 'Country of Origin',
                  items: UtilValues.countries,
                  onChanged: (val) => print("RASSS"),

                  onSaved: (val) {
                    // setState(() {
                    //   newVarietyCountry = val;
                    // });
                  },
                  validator: (val) =>
                      val == null ? 'Please select a Country of Origin' : null,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  // initialValue: (newVarietySpecification.text == '' ? ,
                  controller: newVarietySpecification,
                  decoration: const InputDecoration(
                      labelText: "Additional Specification"),
                  onSaved: (val) {
                    setState(() {
                      // newVarietySpecification = val;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          substituteAndSaveButton(),
        ],
      ),
    );
  }

  //Shows a dialog to select current store variety to substitute (Select Variety Dialog)
  void selectVariety() {
    Variety newVariety = Variety(
        varietyId: 0,
        name: "New Variety",
        code: "",
        isNew: 1); //used for ui purposes

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
                  setState(() {
                    selectedVarietyId = item.varietyId;
                    selectedVariety = item;
                    newVarietyBrand.text = item.brand ?? '';
                    newVarietyMeasurement.text =
                        (item.quantity ?? '').toString();
                    newVarietyUnit.text = item.unit ?? '';
                    // newVarietyPrice.text = '';
                    newVarietyCountry.text = item.countryOfOrigin ?? '';
                    newVarietySpecification.text = item.additionalSpecs ?? '';
                    createNewVariety = true;
                  });
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
        setState(() {
          selectedVariety = val;
          selectedVarietyId = val.varietyId;

          if (val.isNew == 1) {
            newVarietyBrand.text = val.brand ?? '';
            newVarietyMeasurement.text = (val.quantity ?? '').toString();
            newVarietyUnit.text = val.unit ?? '';
            // newVarietyPrice.text = '';
            newVarietyCountry.text = val.countryOfOrigin ?? '';
            newVarietySpecification.text = val.additionalSpecs ?? '';
            createNewVariety = true;
          }
        });
      },
    );
  }

  //Shows a dialog to select Outlet to substitute From (Select Outlet Dialog)
  void selectOtherOutlet() {
    SelectDialog.showModal<Outlet>(
      context,
      alwaysShowScrollBar: true,
      label: "Select Outlet to substitute From",
      items: outletOptions,
      constraints: const BoxConstraints(maxHeight: 450),
      searchBoxDecoration: const InputDecoration(
        hintText: "Search by outlet name",
      ),
      itemBuilder: (BuildContext context, Outlet item, bool isSelected) {
        return Container(
          decoration: selectedOutletId != item.outletId
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
      onChange: (Outlet val) {
        setState(() {
          selectedOutlet = val;
          selectedOutletId = val.outletId;
        });
      },
    );
  }
}
