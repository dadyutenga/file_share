import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UploadsScreen extends StatefulWidget {
  const UploadsScreen({Key? key}) : super(key: key);

  @override
  State<UploadsScreen> createState() => _UploadsScreenState();
}

class _UploadsScreenState extends State<UploadsScreen> {
  final List<_UploadItem> _uploads = [];

  Future<void> _refresh() async {
    // Simulate network refresh
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      // In a real app you'd re-fetch items here.
      // For demo: simply ensure list exists (no-op).
    });
  }

  void _addUpload(String name) {
    setState(() {
      _uploads.insert(
        0,
        _UploadItem(
          name: name,
          sizeBytes: (500 + _uploads.length * 100).toDouble(),
          uploadedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add upload (demo)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'File name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) _addUpload(result);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uploads'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _uploads.isEmpty
            ? ListView(
                // ListView so RefreshIndicator works when empty
                children: [
                  SizedBox(height: 120),
                  const Icon(Icons.cloud_upload, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No uploads yet.\nTap + to add a demo upload.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _uploads.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  final item = _uploads[index];
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      setState(() => _uploads.removeAt(index));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${item.name} removed')),
                      );
                    },
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(item.name),
                      subtitle: Text('${dateFmt.format(item.uploadedAt)} • ${_formatBytes(item.sizeBytes)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.download),
                                    title: const Text('Download'),
                                    onTap: () => Navigator.of(ctx).pop(),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.share),
                                    title: const Text('Share'),
                                    onTap: () => Navigator.of(ctx).pop(),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.info_outline),
                                    title: const Text('Details'),
                                    onTap: () {
                                      Navigator.of(ctx).pop();
                                      showDialog(
                                        context: context,
                                        builder: (dctx) => AlertDialog(
                                          title: Text(item.name),
                                          content: Text('Size: ${_formatBytes(item.sizeBytes)}\nUploaded: ${dateFmt.format(item.uploadedAt)}'),
                                          actions: [TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('OK'))],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add upload',
      ),
    );
  }
}

class _UploadItem {
  final String id;
  final String name;
  final double sizeBytes;
  final DateTime uploadedAt;

  _UploadItem({
    String? id,
    required this.name,
    required this.sizeBytes,
    required this.uploadedAt,
  }) : id = id ?? UniqueKey().toString();
}

String _formatBytes(double bytes, [int decimals = 1]) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  var i = 0;
  var value = bytes;
  while (value >= 1024 && i < suffixes.length - 1) {
    value /= 1024;
    i++;
  }
  return '${value.toStringAsFixed(decimals)} ${suffixes[i]}';
}