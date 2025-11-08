import 'package:flutter/material.dart';

class StarRating extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;
  final double size;
  final Color? color;
  final bool enabled;

  const StarRating({
    super.key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
    this.size = 32.0,
    this.color,
    this.enabled = true,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  void didUpdateWidget(StarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      setState(() {
        _currentRating = widget.initialRating;
      });
    }
  }

  void _setRating(double rating) {
    if (!widget.enabled) return;
    
    setState(() {
      _currentRating = rating;
    });
    widget.onRatingChanged(rating);
  }

  Color _getRatingColor(double rating) {
    if (rating == 0) return Colors.grey;
    if (rating <= 3) return Colors.red;
    if (rating <= 5) return Colors.orange;
    if (rating <= 7) return Colors.amber;
    if (rating <= 9) return Colors.lightGreen;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating number display
        Row(
          children: [
            Text(
              _currentRating > 0 ? _currentRating.toStringAsFixed(1) : '-',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _getRatingColor(_currentRating),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '/ 10',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Slider bar
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getRatingColor(_currentRating),
            inactiveTrackColor: Colors.grey[300],
            thumbColor: _getRatingColor(_currentRating),
            overlayColor: _getRatingColor(_currentRating).withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            trackHeight: 8,
            valueIndicatorColor: _getRatingColor(_currentRating),
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Slider(
            value: _currentRating,
            min: 0,
            max: 10,
            divisions: 10,
            label: _currentRating > 0 ? _currentRating.toStringAsFixed(1) : 'Not rated',
            onChanged: widget.enabled ? (value) => _setRating(value) : null,
          ),
        ),
        
        // Number indicators below slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(11, (index) {
              final isSelected = _currentRating.round() == index;
              return Text(
                '$index',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? _getRatingColor(_currentRating) : Colors.grey[600],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// Simple display-only rating bar
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool compact;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.color,
    this.compact = false,
  });

  Color _getRatingColor(double rating) {
    if (rating == 0) return Colors.grey;
    if (rating <= 3) return Colors.red;
    if (rating <= 5) return Colors.orange;
    if (rating <= 7) return Colors.amber;
    if (rating <= 9) return Colors.lightGreen;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final ratingColor = color ?? _getRatingColor(rating);
    
    if (compact) {
      // Compact version for list items
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: ratingColor,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '/ 10',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    }
    
    // Full version with bar
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: size * 1.5,
                fontWeight: FontWeight.bold,
                color: ratingColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '/ 10',
              style: TextStyle(
                fontSize: size,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 100,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: rating / 10,
            child: Container(
              decoration: BoxDecoration(
                color: ratingColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
