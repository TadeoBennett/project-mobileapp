import 'package:cpi_app/Widgets/outlet_custom_buttons.dart';
import 'package:cpi_app/Widgets/select_outlet_field.dart';
import 'package:cpi_app/Widgets/select_variety_field.dart';
import 'package:cpi_app/helpers/utility_functions.dart';
import 'package:cpi_app/helpers/utility_values.dart';
import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/outlet.dart';
import 'package:cpi_app/models/substitute.dart';
import 'package:cpi_app/models/variety.dart';
import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:cpi_app/providers/substitutions.dart';
import 'package:cpi_app/providers/varieties.dart';
import 'package:cpi_app/validator/new_variety_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:select_form_field/select_form_field.dart';

class SubstituteAssignment extends ConsumerStatefulWidget {
  final Assignment assignment;
  final Substitute? substitute;
  const SubstituteAssignment(
      {Key? key, required this.assignment, required this.substitute})
      : super(key: key);

  @override
  ConsumerState<SubstituteAssignment> createState() =>
      _SubstituteAssignmentState();
}

class _SubstituteAssignmentState extends ConsumerState<SubstituteAssignment> {
  //text field controllers for the form
  TextEditingController price = TextEditingController();
  TextEditingController comment = TextEditingController();
  TextEditingController brand = TextEditingController();
  TextEditingController quantity = TextEditingController();
  TextEditingController unit = TextEditingController();
  TextEditingController countryOfOrigin = TextEditingController(text: '');
  TextEditingController additionalSpecs = TextEditingController();

  //used for the form key
  final _formKey = GlobalKey<FormState>();

  //used to know if the assignment will be substituted from the same store
  bool currentStore = true;

  //used to know which outlet was selected if any
  Outlet? selectedOutlet;

  //used to know which variety was selected if any
  Variety? selectedVariety;

  //used to know when the components are still loading
  bool isLoading = false;

  //used to store the variety options for the dropdown
  List<Variety> varietyOptions = [];

  //used to store the outlets options for the dropdown
  List<Outlet> outletOptions = [];

  //overide on init state
  @override
  void initState() {
    super.initState();

    //set state to loading while the components are loading
    setState(() {
      //get the outlet and varieties options
      varietyOptions = ref
          .read(varietiesProvider)
          .getVarietiesWithSameCode(widget.assignment);

      outletOptions = ref
          .read(outletsProvider)
          .getOutletOptionsForSubstitution(widget.assignment.outletId);

      print(widget.substitute);

      //check if there is a substitute to get the current selected variety and outlet
      if (widget.substitute != null) {
        selectedVariety = ref
            .read(varietiesProvider)
            .getVarietyById(widget.substitute!.newVarietyId);

        //check if the substitute is not from the same store
        if (widget.substitute!.newOutletId != widget.assignment.outletId) {
          selectedOutlet = ref
              .read(outletsProvider)
              .getOutletById(widget.substitute!.newOutletId);
          currentStore = false;
        }

        price.text = widget.substitute!.price.toString();
        comment.text = widget.substitute!.comment;

        //set the text fields to the substitute values if the variety is new
        if (selectedVariety!.isNew == 1) {
          brand.text = selectedVariety!.brand ?? "";
          quantity.text = (selectedVariety!.quantity ?? '').toString();
          unit.text = selectedVariety!.unit ?? '';
          countryOfOrigin.text = selectedVariety!.countryOfOrigin ?? '';
          additionalSpecs.text = selectedVariety!.additionalSpecs ?? '';
        }
      }

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    //used to determine if a new variety needs to be created
    bool showCreateVariety = selectedVariety != null
        ? (selectedVariety!.isNew == 1 ? true : false)
        : false;

    bool canSubmitPrice = false;

    List<Variety> varietyOptionsFiltered = [...varietyOptions];

    //used to check if a another outlet needs to be selected
    if (currentStore) {
      //If the substitute is from same store then only need to check if a variety is selected
      canSubmitPrice = (selectedVariety != null);
    } else {
      //If the substitute is from other store then we need to check if a variety & outlet is selected
      canSubmitPrice = (selectedOutlet != null && selectedVariety != null);

      Variety currentVariety = ref
          .read(varietiesProvider)
          .getVarietyById(widget.assignment.varietyId);
      varietyOptionsFiltered.insert(0, currentVariety);
    }

    return isLoading
        ? loadingIndicator()
        : Container(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(15),
                child:
                    Text("Substitute From...", style: TextStyle(fontSize: 15)),
              ),
              CustomOutletButton(
                  currentStore: currentStore,
                  onPressed: handleChangeIsCurrentStore),
              const SizedBox(height: 5),
              if (!currentStore)
                SelectOutletField(
                    outletOptions: outletOptions,
                    selectedOutlet: selectedOutlet,
                    onSelect: handleSelectOutlet),
              const SizedBox(height: 10),
              SelectVarietyField(
                  varietyOptions: varietyOptionsFiltered,
                  selectedVariety: selectedVariety,
                  onSelect: handleSelectVariety),
              const SizedBox(height: 5),
              Form(
                key: _formKey,
                child: Column(children: [
                  if (showCreateVariety) createVarietyForm(),
                  if (canSubmitPrice) existingVarietyForm(),
                  if (canSubmitPrice) submitButton(),
                ]),
              )
            ],
          ));
  }

  void handleChangeIsCurrentStore(bool isCurrentStore) {
    setState(() {
      selectedVariety = null;
      currentStore = isCurrentStore;
    });
  }

  void handleSelectOutlet(Outlet outlet) {
    setState(() {
      selectedOutlet = outlet;
    });
  }

  void handleSelectVariety(Variety variety) {
    setState(() {
      selectedVariety = variety;

      if (variety.isNew == 1) {
        brand.text = variety.brand ?? "";
        quantity.text = (variety.quantity ?? '').toString();
        unit.text = variety.unit ?? '';
        countryOfOrigin.text = variety.countryOfOrigin ?? "";
        additionalSpecs.text = variety.additionalSpecs ?? "";
      }
    });
  }

  //used to simply collect the substitution price
  Widget existingVarietyForm() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        TextFormField(
            controller: price,
            keyboardType: TextInputType.number,
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
        TextFormField(
            controller: comment,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 3,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter a comment!';
              } else {
                return null;
              }
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.comment),
              labelText: 'Comment',
            )),
      ]),
    );
  }

  //Used to create a new variety and substitute the assignment with it
  Widget createVarietyForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: brand,
                  decoration: const InputDecoration(labelText: "Brand"),
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
                  controller: quantity,
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
                  controller: unit,
                  icon: null,
                  labelText: 'Unit',
                  items: UtilValues.measurementUnits,
                  validator: (val) =>
                      val == null ? 'Please select a Unit' : null,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SelectFormField(
                  type: SelectFormFieldType.dropdown, // or can be dialog
                  // initialValue: newVarietyCountry,
                  controller: countryOfOrigin,
                  icon: null,
                  labelText: 'Country of Origin',
                  items: UtilValues.countries,
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
                  controller: additionalSpecs,
                  decoration: const InputDecoration(
                      labelText: "Additional Specification"),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
        ],
      ),
    );
  }

  Widget submitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: ElevatedButton(
        onPressed: updatePrice,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Save'),
            Icon(Icons.check),
          ],
        ),
      ),
    );
  }

  Future<void> updatePrice() async {
    try {
      //Validate Form Fields!
      if (_formKey.currentState!.validate()) {
        // Save the form Fields
        _formKey.currentState!.save();

        Variety? newVariety;
        double newPrice = double.parse(price.text);

        // Try access Location and get the location values
        bool is_location_enabled = await UtilityFunctions().locationEnabled();

        // if the location was not enabled then return
        if (!is_location_enabled) {
          return;
        }

        //get the location
        Map<String, dynamic> location =
            await UtilityFunctions().getCurrentLocation();

        double lat = location['latitude'];
        double long = location['longitude'];

        // find an assignment with the same varietyId and outletId
        Assignment? assignmentCheck = ref
            .read(assignmentsProvider)
            .getAssignmentByOutletAndVarietyId(
                currentStore
                    ? widget.assignment.outletId
                    : selectedOutlet!.outletId,
                selectedVariety!.varietyId);

        // VERIFY IF IT WORKS
        if (assignmentCheck != null) {
          await showDuplicateErrorDialog();
          return;
        }

        //Check if the variety is a new one from the current store
        if (selectedVariety!.isNew == 1) {
          //get heading from the variety name
          String heading = widget.assignment.varietyName.split(' - ')[0];

          String countrySelectedValue =
              countryOfOrigin.text == '' ? '' : ', ${countryOfOrigin.text}';
          String additionalSpecsValue =
              ['', ' ', 0, null].contains(additionalSpecs.text) == true
                  ? ''
                  : ', ${additionalSpecs.text}';

          //create the name of the variety
          String name =
              '$heading - ${brand.text}, ${quantity.text} ${unit.text}${countrySelectedValue}${additionalSpecsValue}';

          //check if the variety has not been added to the db
          if (selectedVariety!.varietyId == 0) {
            newVariety = await ref.read(varietiesProvider).createVariety(
                selectedVariety!.varietyId,
                name,
                brand.text,
                unit.text,
                double.parse(quantity.text),
                countryOfOrigin.text,
                additionalSpecs.text,
                widget.assignment.code.substring(0, 23));
          } else {
            newVariety = await ref.read(varietiesProvider).updateVariety(
                  selectedVariety!.varietyId,
                  name,
                  brand.text,
                  unit.text,
                  double.parse(quantity.text),
                  countryOfOrigin.text,
                  additionalSpecs.text,
                );
          }
        }

        //create a substitution record with the accurate information
        await ref.read(substitutionsProvider).insert(
            widget.assignment.id,
            widget.assignment.outletId,
            currentStore
                ? widget.assignment.outletId
                : selectedOutlet!
                    .outletId, //if the substitute is from the current store, then the newOutletId is the same as the outletId  of the assignment
            selectedVariety!.varietyId == 0
                ? newVariety!.varietyId
                : selectedVariety!
                    .varietyId, //if the variety was created, then the newVarietyId is the new variety's id
            newPrice,
            comment.text,
            lat,
            long);

        String collectedAt =
            DateFormat('yyyy-MM-dd H:mm:s').format(DateTime.now());

        //set Assignment as substituted
        await ref
            .read(assignmentsProvider)
            .substitutedAssignment(widget.assignment.id, newPrice, collectedAt);

        print("CREATED SUCCESFULLY !!!!");

        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      print(e);
      print(
        "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS",
      );
      await showErrorDialog();
    }
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

  Future<void> showDuplicateErrorDialog() async {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Error"),
              content: const Text(
                  "Assignment Cannot be duplicated. Note that the assignment with the same Variety and Outlet already Exist and it cannot be duplicated!"),
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

  Widget loadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
