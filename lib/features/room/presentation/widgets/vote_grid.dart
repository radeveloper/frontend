import 'package:flutter/material.dart';

class VoteGrid extends StatelessWidget {
  final String deckType;
  final void Function(String value) onVote;
  final String? selectedValue;
  final bool enabled;

  const VoteGrid({
    super.key,
    required this.deckType,
    required this.onVote,
    this.selectedValue,
    this.enabled = true,
  });

  List<String> get _values {
    switch (deckType) {
      case 'tshirt':
        return const ['XS', 'S', 'M', 'L', 'XL', '?'];
      case 'fibonacci':
      default:
        return const ['0', '1/2', '1', '2', '3', '5', '8', '13', '?'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _values.map((v) {
        final bool isSelected = selectedValue == v;
        return OutlinedButton(
          onPressed: enabled ? () => onVote(v) : null,
          style: OutlinedButton.styleFrom(
            side: isSelected ? const BorderSide(color: Colors.white) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                size: 16,
                color: isSelected ? Colors.white : null,
              ),
              const SizedBox(width: 6),
              Text(
                v,
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
