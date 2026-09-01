/// Widget wrapper for permission-gated UI elements.
///
/// Shows/hides/disables content based on permission checks.
/// Handles offline state (Unknown cache) gracefully.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/permission_enforcement.dart';
import '../models/user_permissions.dart';

/// Wraps a widget with permission gating.
///
/// If user has permission: shows the child widget normally
/// If user lacks permission: shows a disabled/hidden version
/// If offline (no cache): shows "offline mode" version
///
/// Usage:
/// ```dart
/// PermissionGatedWidget(
///   requiredPermission: AppPermissions.inventoryEdit,
///   child: EditInventoryButton(),
///   onDenied: (reason) => Text('Cannot edit: $reason'),
/// )
/// ```
class PermissionGatedWidget extends ConsumerWidget {
  const PermissionGatedWidget({
    required this.requiredPermission,
    required this.child,
    this.onDenied,
    this.onUnknown,
    this.key,
  });

  final String requiredPermission;
  final Widget child;
  final Widget Function(String reason)? onDenied;
  final Widget Function(String reason)? onUnknown;
  final Key? key;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkFuture = ref.watch(canPerformActionProvider(requiredPermission));

    return checkFuture.when(
      data: (hasPermission) {
        if (hasPermission) {
          return child;
        }
        return onDenied?.call('You lack permission for this action') ??
            _defaultDeniedWidget();
      },
      loading: () => _loadingWidget(),
      error: (error, _) {
        // If error is PermissionUnknownException, show offline version
        if (error is PermissionUnknownException) {
          return onUnknown?.call(error.message) ?? _defaultUnknownWidget();
        }
        return _errorWidget(error.toString());
      },
    );
  }

  static Widget _defaultDeniedWidget() {
    return Opacity(
      opacity: 0.5,
      child: Tooltip(
        message: 'You do not have permission to perform this action',
        child: Container(
          color: Colors.grey.withOpacity(0.2),
          child: const Text(
            'No permission',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ),
    );
  }

  static Widget _defaultUnknownWidget() {
    return Tooltip(
      message: 'Offline mode: permissions unavailable',
      child: Container(
        color: Colors.orange.withOpacity(0.1),
        padding: const EdgeInsets.all(8),
        child: const Text(
          'Offline mode',
          style: TextStyle(color: Colors.orange, fontSize: 12),
        ),
      ),
    );
  }

  static Widget _loadingWidget() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  static Widget _errorWidget(String message) {
    return Tooltip(
      message: message,
      child: Container(
        color: Colors.red.withOpacity(0.1),
        child: const Text(
          'Error',
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
    );
  }
}

/// Button wrapper that disables if user lacks permission.
///
/// Usage:
/// ```dart
/// PermissionGatedButton(
///   requiredPermission: AppPermissions.posDiscount,
///   onPressed: () => applyDiscount(),
///   child: Text('Apply Discount'),
/// )
/// ```
class PermissionGatedButton extends ConsumerWidget {
  const PermissionGatedButton({
    required this.requiredPermission,
    required this.onPressed,
    required this.child,
    this.key,
  });

  final String requiredPermission;
  final VoidCallback onPressed;
  final Widget child;
  final Key? key;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkFuture = ref.watch(canPerformActionProvider(requiredPermission));

    return checkFuture.when(
      data: (hasPermission) {
        return Tooltip(
          message: hasPermission
              ? ''
              : 'You lack permission for this action',
          child: FilledButton(
            onPressed: hasPermission ? onPressed : null,
            child: child,
          ),
        );
      },
      loading: () => const FilledButton(
        onPressed: null,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) {
        // If offline, show disabled state
        if (error is PermissionUnknownException) {
          return Tooltip(
            message: 'Offline: permission check unavailable',
            child: FilledButton(
              onPressed: null,
              child: child,
            ),
          );
        }
        return FilledButton(
          onPressed: null,
          child: child,
        );
      },
    );
  }
}

/// Screen wrapper that checks permission before allowing access.
///
/// Usage:
/// ```dart
/// PermissionGatedScreen(
///   requiredPermission: AppPermissions.inventoryEdit,
///   child: EditInventoryScreen(),
///   onDenied: (reason) => PermissionDeniedScreen(reason),
/// )
/// ```
class PermissionGatedScreen extends ConsumerWidget {
  const PermissionGatedScreen({
    required this.requiredPermission,
    required this.child,
    this.onDenied,
    this.onUnknown,
    this.key,
  });

  final String requiredPermission;
  final Widget child;
  final Widget Function(String reason)? onDenied;
  final Widget Function(String reason)? onUnknown;
  final Key? key;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkFuture = ref.watch(canPerformActionProvider(requiredPermission));

    return checkFuture.when(
      data: (hasPermission) {
        if (hasPermission) {
          return child;
        }
        return onDenied?.call('You lack permission to access this screen') ??
            _deniedScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) {
        if (error is PermissionUnknownException) {
          return onUnknown?.call(error.message) ?? _unknownScreen();
        }
        return _errorScreen(error.toString());
      },
    );
  }

  static Widget _deniedScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'You do not have permission to access this screen.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  static Widget _unknownScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Mode')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Permission check unavailable while offline.\n'
            'This feature may be disabled in offline mode.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  static Widget _errorScreen(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Permission check failed: $message',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
