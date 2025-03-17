// lib/widgets/custom_popup_dialog.dart

import 'package:flutter/material.dart';

class CustomPopupDialog extends StatefulWidget {
  final Widget child;
  final double width;
  final double? height;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final EdgeInsets contentPadding;
  final bool barrierDismissible;
  final Color barrierColor;
  final Function? onDismiss;

  const CustomPopupDialog({
    Key? key,
    required this.child,
    this.width = 0.85,
    this.height,
    this.backgroundColor = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.contentPadding = EdgeInsets.zero,
    this.barrierDismissible = true,
    this.barrierColor = Colors.black54,
    this.onDismiss,
  }) : super(key: key);

  @override
  _CustomPopupDialogState createState() => _CustomPopupDialogState();

  /// Método estático para mostrar el diálogo
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double width = 0.85,
    double? height,
    Color backgroundColor = Colors.white,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    EdgeInsets contentPadding = EdgeInsets.zero,
    bool barrierDismissible = true,
    Color barrierColor = Colors.black54,
    Function? onDismiss,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        final ThemeData theme = Theme.of(context);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return WillPopScope(
              onWillPop: () async {
                if (onDismiss != null) {
                  onDismiss();
                }
                return barrierDismissible;
              },
              child: SafeArea(
                child: Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: width is double && width <= 1
                          ? MediaQuery.of(context).size.width * width
                          : width,
                      height: height,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: borderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10.0,
                            offset: const Offset(0.0, 10.0),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: contentPadding,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}

class _CustomPopupDialogState extends State<CustomPopupDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(0),
      elevation: 0,
      child: Container(
        width: widget.width is double && widget.width <= 1
            ? MediaQuery.of(context).size.width * widget.width
            : widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Padding(
          padding: widget.contentPadding,
          child: widget.child,
        ),
      ),
    );
  }
}
