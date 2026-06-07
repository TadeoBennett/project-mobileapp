import 'package:cpi_app/helpers/auth.dart';
import 'package:cpi_app/helpers/utility_functions.dart';
import 'package:cpi_app/models/assignment.dart';
import 'package:cpi_app/models/user.dart';
import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/substitutions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class UpdateAssignmentPrice extends ConsumerStatefulWidget {
  final Assignment assignment;
  const UpdateAssignmentPrice({Key? key, required this.assignment})
      : super(key: key);

  @override
  ConsumerState<UpdateAssignmentPrice> createState() =>
      _UpdateAssignmentPriceState();
}

class _UpdateAssignmentPriceState extends ConsumerState<UpdateAssignmentPrice> {
  User? user = UserAuth().user();

  //Used to store the new price of the assignment
  String price = '';

  //used to store the comment of the assignment
  String comment = '';

  //comment is empty flag
  bool commentIsEmpty = false;

  //comment is empty error
  String commentError = '';

  //used to tell if the assignment is being updated
  bool isLoading = false;

  //used to store the price inconsistency
  double priceInconsistency = 0;

  //used to store the form key
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    String commentIsRequiredMessage =
        "Comment is required to update this price!";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      child: Form(
        key: _formKey,
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
                setState(() => price = val ?? '');
              },
              validator: (val) {
                print("SADASDADASDASDASDASD1");

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
                // helperText: commentIsEmpty ? commentIsRequiredMessage : null,
                // helperStyle: const TextStyle(color: Colors.red),
              )),
          const SizedBox(height: 15),
          TextFormField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp('[\u0020-\u007e\u00a0-\u00ff\u0152\u0153\u0178]'))
              ],
              autofocus: true,
              initialValue: widget.assignment.comment == null
                  ? ''
                  : widget.assignment.comment.toString(),
              onSaved: (val) {
                setState(() => comment = val ?? '');
              },
              maxLines: 5,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.comment),
                labelText: 'Comment',
                helperText: commentError != '' ? commentError : null,
                helperStyle: const TextStyle(color: Colors.red),
              )),
          const SizedBox(
            height: 15,
          ),
          ElevatedButton(
            onPressed: updatePrice,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Save'),
                Icon(Icons.check),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  //verifies if the price is inconsistent with the previous price
  bool isPriceInconsistent() {
    //simply alias for the previous price
    double previousPrice = widget.assignment.previousPrice ?? 0;

    //if the previous price is null or 0, then the price is consistent
    if ([0, null].contains(widget.assignment.previousPrice)) {
      return true;
    }

    double parsedPrice = double.parse(price);

    //if the price is inconsistent, then return false
    final priceDifference = parsedPrice - previousPrice;
    final percentageDifference = ((priceDifference / previousPrice) * 100);

    setState(() {
      priceInconsistency = percentageDifference;
    });

    return percentageDifference > 25 || percentageDifference < -25;
  }

  //updates the price of the assignment
  Future<void> updatePrice() async {
    setState(() => commentIsEmpty = false);

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      setState(() {
        commentError = "";
      });

      try {
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

        double lat = location['latitude'];
        double long = location['longitude'];

        print(long);
        print(lat);

        // if the price is not consistent then this field must be required
        //verify if the assignment new price is inconsistent
        // Verify if it is a HQ and just make it optional!

        if (user != null && user?.userType != 'HQ') {
          bool? isInconsistent = isPriceInconsistent();

          if (isInconsistent == true) {
            //if the price is inconsistent, then verify if a comment was added
            if (comment == '') {
              setState(() {
                commentIsEmpty = true;
                commentError =
                    "Price is inconsistent by ${priceInconsistency.toStringAsFixed(2)}%, field is required!";
              });

              return;
            }
          }
        }

        //parse the price to double
        double parsedPrice = double.parse(price);

        String collectedAt =
            DateFormat('yyyy-MM-dd H:mm:s').format(DateTime.now());

        //update the price of the assignment
        await ref.read(assignmentsProvider).updateAssignmentPrice(
            widget.assignment.id, parsedPrice, comment, collectedAt, lat, long);

        //clear substitution if any already existed
        await ref
            .read(substitutionsProvider)
            .clearSubstitution(widget.assignment.id);

        if (!mounted) return;

        Navigator.pop(context);
      } catch (error) {
        print(error);
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Something went wrong! Please try again later."),
          ),
        );
      }
    }
  }

  //asks the user to enter a comment if the price is inconsistent
//   Future<bool?> requestPriceComment() async {
//     return await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Comment Request"),
//         content: Container(
//             margin: const EdgeInsets.all(8),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                         child: Text(
//                             "The Price you Entered is ${priceInconsistency.toStringAsFixed(2)}% different from the previous Price!\nPlease enter a comment to explain the difference.")),
//                   ],
//                 ),
//                 TextField(
//                     maxLines: 5,
//                     minLines: 1,
//                     autofocus: true,
//                     keyboardType: TextInputType.multiline,
//                     decoration: const InputDecoration(
//                       labelText: "Comment",
//                       hintText: "Please enter a comment",
//                     ),
//                     onChanged: (value) {
//                       setState(() => comment = value);
//                     })
//               ],
//             )),
//         actions: <Widget>[
//           TextButton(
//             onPressed: () {
//               if (!mounted) return;
//               Navigator.of(context).pop(false);
//             },
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () {
//               if (!mounted) return;
//               Navigator.of(context).pop(true);
//             },
//             child: const Text("Continue"),
//           ),
//         ],
//       ),
//     );
//   }

}
