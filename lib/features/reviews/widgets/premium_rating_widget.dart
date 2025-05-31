// lib/features/reviews/widgets/premium_rating_widget.dart

import 'package:flutter/material.dart';

class PremiumRatingWidget extends StatefulWidget {
  final int selectedRating;
  final Function(int) onRatingChanged;
  

  const PremiumRatingWidget({
    Key? key,
    required this.selectedRating,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  State<PremiumRatingWidget> createState() => _PremiumRatingWidgetState();
}

class _PremiumRatingWidgetState extends State<PremiumRatingWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final int _isSmallScreen= 600;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return Colors.red[400]!;
      case 3:
        return Colors.orange[400]!;
      case 4:
      case 5:
        return Colors.green[400]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding:MediaQuery.of(context).size.width >= _isSmallScreen ? const EdgeInsets.all(40) : const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Rate your experience',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = rating <= widget.selectedRating;
              
              return GestureDetector(
                onTap: () {
                  widget.onRatingChanged(rating);
                  _animationController.forward().then((_) {
                    _animationController.reverse();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isSelected && rating == widget.selectedRating
                            ? _scaleAnimation.value
                            : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.amber[100]
                                : Colors.transparent,
                          ),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: MediaQuery.of(context).size.width >= _isSmallScreen ? 60:30,
                            color: isSelected
                                ? Colors.amber[600]
                                : Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 24),
          
          // Rating Text
          if (widget.selectedRating > 0) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(widget.selectedRating),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _getRatingColor(widget.selectedRating).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getRatingColor(widget.selectedRating).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getRatingText(widget.selectedRating),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _getRatingColor(widget.selectedRating),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}