import 'package:cpi_app/providers/assignments.dart';
import 'package:cpi_app/providers/outlets.dart';
import 'package:cpi_app/providers/substitutions.dart';
import 'package:cpi_app/providers/varieties.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String hardSyncMessage =
    """Are you sure you want to download data from server? Your changes if any will be overwritten! 
Recommended when it's a new Time Period to start a new collection.""";

class DownloadButton extends ConsumerStatefulWidget {
  final Function setIsDownloading;
  const DownloadButton({Key? key, required this.setIsDownloading})
      : super(key: key);

  @override
  ConsumerState<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<DownloadButton> {
  //used to indicate loading
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
        icon: const Icon(Icons.cloud_download),
        // Callback that sets the selected popup menu item.
        itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              PopupMenuItem<int>(
                value: null,
                child: TextButton(
                  onPressed: loading ? null : hardDownloadFromServer,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.download_for_offline,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 8),
                      Text("Hard Sync")
                    ],
                  ),
                ),
              ),
              PopupMenuItem<int>(
                onTap: null,
                value: 1,
                child: TextButton(
                  onPressed: loading ? null : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.refresh, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Soft Sync")
                    ],
                  ),
                ),
              ),
            ]);
  }

  //this function is used to do a hard Sync operation
  Future<void> hardDownloadFromServer() async {
    try {
      //closes the opened menu buttons
      Navigator.pop(context);

      //Request Confirmations from  user
      bool? proceed = await requestConfirmation("Hard Sync", hardSyncMessage);

      //verify if should proceed
      if (proceed != true) {
        return;
      }

      //tell the parent component to show loading progress
      widget.setIsDownloading(true);
      setState(() => loading = true);

      await ref.read(substitutionsProvider).clearSubstitutions();
      await ref.read(outletsProvider).hardDownload();
      await ref.read(assignmentsProvider).hardDownload();
      await ref.read(varietiesProvider).hardDownload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Downloaded Successfully!"),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to Download Assignment Data!"),
      ));
    } finally {
      widget.setIsDownloading(false);
      setState(() => loading = false);
    }
  }

  //This Functions is used to confirm an operation
  Future<bool?> requestConfirmation(title, message) async {
    return await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  child:
                      const Text("Yes", style: TextStyle(color: Colors.green)),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
                TextButton(
                  child: const Text("No", style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.pop(ctx, false),
                ),
              ],
            ));
  }
}
