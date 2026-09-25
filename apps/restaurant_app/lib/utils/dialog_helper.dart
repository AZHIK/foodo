import 'package:flutter/material.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  return showDialog<T>(
    context: context,
    builder: builder,
    fullscreenDialog: true,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
  );
}

Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    useRootNavigator: true,
  );
}
