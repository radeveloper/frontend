import 'package:flutter/material.dart';

class TransferOwnershipDialog extends StatefulWidget {
  final List<Map<String, dynamic>> transferees;

  const TransferOwnershipDialog({
    super.key,
    required this.transferees,
  });

  @override
  State<TransferOwnershipDialog> createState() =>
      _TransferOwnershipDialogState();

  static Future<String?> show(
      BuildContext context, List<Map<String, dynamic>> transferees) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => TransferOwnershipDialog(transferees: transferees),
    );
  }
}

class _TransferOwnershipDialogState extends State<TransferOwnershipDialog> {
  String? selectedId;

  @override
  void initState() {
    super.initState();
    selectedId = widget.transferees.firstOrNull?['id']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transfer ownership'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Select a participant to become the new owner:'),
            ),
            const SizedBox(height: 12),
            ...widget.transferees.map((p) => _buildTransfereeOption(p)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: selectedId == null
              ? null
              : () => Navigator.of(context).pop(selectedId),
          child: const Text('Transfer & Leave'),
        ),
      ],
    );
  }

  Widget _buildTransfereeOption(Map<String, dynamic> participant) {
    final pid = participant['id']?.toString() ?? '';
    final name = participant['displayName']?.toString() ?? '(unknown)';
    final isSelected = selectedId == pid;

    return InkWell(
      onTap: () => setState(() => selectedId = pid),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            _buildRadioButton(isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.bodyLarge),
                  Text(
                    (participant['isOnline'] == true) ? 'online' : 'offline',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioButton(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
          width: 2,
        ),
        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

