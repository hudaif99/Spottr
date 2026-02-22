import 'package:volt/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/set_log.dart';

class SetRow extends StatefulWidget {
  final int index;
  final SetLog setLog;
  final void Function(SetLog updatedSet) onChanged;
  final VoidCallback onComplete;
  final VoidCallback onRemove;

  const SetRow({
    super.key,
    required this.index,
    required this.setLog,
    required this.onChanged,
    required this.onComplete,
    required this.onRemove,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;

  String _formatNumber(double num) {
    if (num <= 0) return '';
    return num == num.truncateToDouble()
        ? num.toInt().toString()
        : num.toString();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.setLog.isCompleted ? 1.02 : 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _weightCtrl = TextEditingController(
      text: _formatNumber(widget.setLog.weight),
    );
    _repsCtrl = TextEditingController(
      text: widget.setLog.reps > 0 ? widget.setLog.reps.toString() : '',
    );

    if (widget.setLog.isCompleted) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.setLog.isCompleted && widget.setLog.isCompleted) {
      _controller.forward().then((_) => _controller.reverse());
    }

    // Update weight text if changed externally (e.g. from copy previous best)
    if (oldWidget.setLog.weight != widget.setLog.weight) {
      final formatted = _formatNumber(widget.setLog.weight);
      if (_weightCtrl.text != formatted) {
        _weightCtrl.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.setLog.isCompleted;
    final bgColor = isCompleted
        ? context.colors.success.withValues(alpha: 0.05)
        : context.colors.surface;

    final contentOpacity = isCompleted ? 0.4 : 1.0;

    return Dismissible(
      key: Key(widget.setLog.id),
      direction: isCompleted
          ? DismissDirection.none
          : DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: context.colors.success,
        child: Icon(Icons.check, color: context.colors.background, size: 32),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: context.colors.error,
        child: Icon(
          Icons.delete_outline,
          color: context.colors.background,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.heavyImpact();
          widget.onComplete();
          // Returning false prevents the Dismissible from removing the widget from the tree,
          // which fixes the "dismissed widget is still part of the tree" error since we are
          // only updating the 'isCompleted' state without removing the entity from the list.
          return false;
        } else if (direction == DismissDirection.endToStart) {
          HapticFeedback.heavyImpact();
          widget.onRemove();
          // We are actually deleting the widget from the list, so we can return true.
          return true;
        }
        return false;
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: isCompleted
                ? Border.all(
                    color: context.colors.success.withValues(alpha: 0.5),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Opacity(
              opacity: contentOpacity,
              child: Row(
                children: [
                  // Set Number
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${widget.index + 1}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: isCompleted
                                ? context.colors.success
                                : context.colors.secondaryText,
                          ),
                    ),
                  ),

                  // Weight
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.transparent
                            : context.colors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isCompleted
                                  ? context.colors.success.withValues(
                                      alpha: 0.5,
                                    )
                                  : context.colors.primaryText,
                            ),
                        decoration: InputDecoration(
                          hintText: '-',
                          hintStyle: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: context.colors.secondaryText.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          final weight = double.tryParse(val) ?? 0.0;
                          widget.onChanged(
                            widget.setLog.copyWith(weight: weight),
                          );
                        },
                        enabled: !isCompleted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'kg',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isCompleted
                          ? context.colors.success
                          : context.colors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Reps
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.transparent
                            : context.colors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _repsCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isCompleted
                                  ? context.colors.success.withValues(
                                      alpha: 0.5,
                                    )
                                  : context.colors.primaryText,
                            ),
                        decoration: InputDecoration(
                          hintText: '-',
                          hintStyle: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: context.colors.secondaryText.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          final reps = int.tryParse(val) ?? 0;
                          widget.onChanged(widget.setLog.copyWith(reps: reps));
                        },
                        enabled: !isCompleted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'reps',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isCompleted
                          ? context.colors.success
                          : context.colors.secondaryText,
                    ),
                  ),

                  // Checkbox / Uncheck
                  IconButton(
                    icon: Icon(
                      isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: isCompleted
                          ? context.colors.success
                          : context.colors.secondaryText,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (!isCompleted) {
                        _controller.forward().then(
                          (_) => _controller.reverse(),
                        );
                        widget.onComplete();
                      } else {
                        widget.onChanged(
                          widget.setLog.copyWith(isCompleted: false),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
