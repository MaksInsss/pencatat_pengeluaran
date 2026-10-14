import 'package:flutter/material.dart';

class MonthSelector extends StatelessWidget {
  final String monthText;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthSelector({
    super.key,
    required this.monthText,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(
            Icons.chevron_left,
          ),
        ),

        Text(
          monthText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        IconButton(
          onPressed: onNext,
          icon: const Icon(
            Icons.chevron_right,
          ),
        ),
      ],
    );
  }
}