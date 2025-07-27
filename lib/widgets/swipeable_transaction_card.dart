import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../screens/edit_transaction_screen.dart';

class SwipeableTransactionCard extends StatefulWidget {
  final Widget child;
  final Transaction transaction;
  final int index;
  final String boxType;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleComplete;

  const SwipeableTransactionCard({
    super.key,
    required this.child,
    required this.transaction,
    required this.index,
    required this.boxType,
    this.onEdit,
    this.onToggleComplete,
  });

  @override
  State<SwipeableTransactionCard> createState() =>
      _SwipeableTransactionCardState();
}

class _SwipeableTransactionCardState extends State<SwipeableTransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  double _dragPosition = 0.0;
  bool _isDragging = false;

  static const double _editThreshold = 80.0;
  static const double _completeThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _animationController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition += details.delta.dx;
      _dragPosition = _dragPosition.clamp(-120.0, 120.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    if (_dragPosition.abs() < 30.0) {
      // Small swipe, return to center
      _resetPosition();
      return;
    }

    if (_dragPosition < -_editThreshold) {
      // Left swipe - Edit
      _showEditAction();
    } else if (_dragPosition > _completeThreshold) {
      // Right swipe - Toggle complete
      _showCompleteAction();
    } else {
      _resetPosition();
    }
  }

  void _resetPosition() {
    _animationController.reset();
    setState(() {
      _dragPosition = 0.0;
    });
  }

  void _showEditAction() {
    _animationController.forward().then((_) {
      _resetPosition();
      _handleEdit();
    });
  }

  void _showCompleteAction() {
    _animationController.forward().then((_) {
      _resetPosition();
      _handleToggleComplete();
    });
  }

  void _handleEdit() async {
    if (widget.onEdit != null) {
      widget.onEdit!();
    } else {
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => EditTransactionScreen(
            transaction: widget.transaction,
            index: widget.index,
            boxType: widget.boxType,
          ),
        ),
      );
    }
  }

  void _handleToggleComplete() {
    if (widget.onToggleComplete != null) {
      widget.onToggleComplete!();
    }
  }

  Color _getLeftActionColor() {
    double opacity = (_dragPosition.abs() / _editThreshold).clamp(0.0, 1.0);
    return Color(0xFF00C853).withValues(alpha: opacity);
  }

  Color _getRightActionColor() {
    double opacity = (_dragPosition.abs() / _completeThreshold).clamp(0.0, 1.0);
    return (widget.transaction.isCompleted
            ? Color(0xFFFF1744)
            : Color(0xFF00C853))
        .withValues(alpha: opacity);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          // Background actions
          Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Left action (Edit)
                if (_dragPosition < -10)
                  Expanded(
                    flex: _dragPosition < -_editThreshold ? 2 : 1,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getLeftActionColor(),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                Spacer(),

                // Right action (Complete/Uncomplete)
                if (_dragPosition > 10)
                  Expanded(
                    flex: _dragPosition > _completeThreshold ? 2 : 1,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getRightActionColor(),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.transaction.isCompleted
                                  ? Icons.undo_outlined
                                  : Icons.check_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.transaction.isCompleted
                                  ? 'Undo'
                                  : 'Complete',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Main card
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_dragPosition, 0),
                child: Transform.scale(
                  scale: _isDragging ? 0.98 : _scaleAnimation.value,
                  child: widget.child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
