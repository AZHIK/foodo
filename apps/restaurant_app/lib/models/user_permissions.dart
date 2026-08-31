/// Result type for querying current user's cached permissions.
///
/// Explicitly distinguishes three states:
/// - Known: Cache exists and its age is known (may be fresh or stale)
/// - Unknown: Cache never populated (user data missing offline)
library;

/// Permission cache result: online or offline, fresh or stale.
///
/// This is NOT a gating mechanism (that belongs to enforcement, later);
/// this is strictly "what do we know about the current user's permissions
/// right now?" Callers use this to understand whether they're reading
/// current data, stale data, or no data at all.
sealed class UserPermissionsResult {
  const UserPermissionsResult();

  /// Cache is available and we know its freshness. Permissions may be
  /// current (fresh) or outdated (stale), but they exist locally.
  factory UserPermissionsResult.known({
    required Set<String> permissions,
    required bool isStale,
  }) = _Known;

  /// Cache does not exist for this user and business context.
  /// Offline, or online but never cached (e.g., invited staff who switched
  /// context before their PIN setup completed). No permissions to read.
  factory UserPermissionsResult.unknown() = _Unknown;

  T when<T>({
    required T Function(Set<String> permissions, bool isStale) onKnown,
    required T Function() onUnknown,
  }) {
    return switch (this) {
      _Known(permissions: final p, isStale: final s) => onKnown(p, s),
      _Unknown() => onUnknown(),
    };
  }

  /// Convenience: true if we have any permission data (fresh or stale).
  bool get isKnown => this is _Known;

  /// Convenience: extract permissions if known, or empty set if not.
  Set<String> get permissionsOrEmpty {
    return when(
      onKnown: (perms, _) => perms,
      onUnknown: () => {},
    );
  }
}

final class _Known extends UserPermissionsResult {
  const _Known({
    required this.permissions,
    required this.isStale,
  });

  final Set<String> permissions;
  final bool isStale;

  @override
  String toString() => 'UserPermissionsResult.known('
      'permissions: $permissions, '
      'isStale: $isStale)';
}

final class _Unknown extends UserPermissionsResult {
  const _Unknown();

  @override
  String toString() => 'UserPermissionsResult.unknown()';
}
