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

  double _dragPosition = 0.0;
  bool _isDragging = false;

  static const double _editThreshold = 70.0;
  static const double _completeThreshold = 70.0;
  static const double _maxDragDistance = 120.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
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
      _dragPosition = _dragPosition.clamp(-_maxDragDistance, _maxDragDistance);
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          // Clean background without colored areas
          Container(
            margin: EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFF0A0A0B), // Same as app background
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Left side - Complete/Uncomplete icon area (Right swipe)
                Container(
                  width: 80,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _dragPosition > 5
                          ? (_dragPosition / _completeThreshold).clamp(0.3, 1.0)
                          : 0.0,
                      duration: Duration(milliseconds: 100),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  (widget.transaction.isCompleted
                                          ? Color(0xFFFF1744)
                                          : Color(0xFF00C853))
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    (widget.transaction.isCompleted
                                            ? Color(0xFFFF1744)
                                            : Color(0xFF00C853))
                                        .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              widget.transaction.isCompleted
                                  ? Icons.close_outlined
                                  : Icons.check_outlined,
                              color: widget.transaction.isCompleted
                                  ? Color(0xFFFF1744)
                                  : Color(0xFF00C853),
                              size: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.transaction.isCompleted ? 'Undo' : 'Done',
                            style: TextStyle(
                              color: widget.transaction.isCompleted
                                  ? Color(0xFFFF1744)
                                  : Color(0xFF00C853),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(child: SizedBox()),

                // Right side - Edit icon area (Left swipe)
                Container(
                  width: 80,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _dragPosition < -5
                          ? (_dragPosition.abs() / _editThreshold).clamp(
                              0.3,
                              1.0,
                            )
                          : 0.0,
                      duration: Duration(milliseconds: 100),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF00C853).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFF00C853).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF00C853),
                              size: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Color(0xFF00C853),
                              fontSize: 10,
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

          // Main card with smooth translation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_dragPosition, 0),
                child: Transform.scale(
                  scale: _isDragging ? 0.99 : 1.0, // Subtle scale effect
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isDragging
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: widget.child,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
