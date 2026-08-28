// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalUserProfilesTable extends LocalUserProfiles
    with TableInfo<$LocalUserProfilesTable, LocalUserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinSaltMeta = const VerificationMeta(
    'pinSalt',
  );
  @override
  late final GeneratedColumn<String> pinSalt = GeneratedColumn<String>(
    'pin_salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleLabelMeta = const VerificationMeta(
    'roleLabel',
  );
  @override
  late final GeneratedColumn<String> roleLabel = GeneratedColumn<String>(
    'role_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSignedInAtMeta = const VerificationMeta(
    'lastSignedInAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSignedInAt =
      GeneratedColumn<DateTime>(
        'last_signed_in_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _failedPinAttemptsMeta = const VerificationMeta(
    'failedPinAttempts',
  );
  @override
  late final GeneratedColumn<int> failedPinAttempts = GeneratedColumn<int>(
    'failed_pin_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lockedUntilMeta = const VerificationMeta(
    'lockedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> lockedUntil = GeneratedColumn<DateTime>(
    'locked_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastRevocationCheckAtMeta =
      const VerificationMeta('lastRevocationCheckAt');
  @override
  late final GeneratedColumn<DateTime> lastRevocationCheckAt =
      GeneratedColumn<DateTime>(
        'last_revocation_check_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    pinHash,
    pinSalt,
    roleLabel,
    lastSignedInAt,
    failedPinAttempts,
    lockedUntil,
    createdAt,
    updatedAt,
    lastRevocationCheckAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalUserProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    } else if (isInserting) {
      context.missing(_pinHashMeta);
    }
    if (data.containsKey('pin_salt')) {
      context.handle(
        _pinSaltMeta,
        pinSalt.isAcceptableOrUnknown(data['pin_salt']!, _pinSaltMeta),
      );
    } else if (isInserting) {
      context.missing(_pinSaltMeta);
    }
    if (data.containsKey('role_label')) {
      context.handle(
        _roleLabelMeta,
        roleLabel.isAcceptableOrUnknown(data['role_label']!, _roleLabelMeta),
      );
    }
    if (data.containsKey('last_signed_in_at')) {
      context.handle(
        _lastSignedInAtMeta,
        lastSignedInAt.isAcceptableOrUnknown(
          data['last_signed_in_at']!,
          _lastSignedInAtMeta,
        ),
      );
    }
    if (data.containsKey('failed_pin_attempts')) {
      context.handle(
        _failedPinAttemptsMeta,
        failedPinAttempts.isAcceptableOrUnknown(
          data['failed_pin_attempts']!,
          _failedPinAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('locked_until')) {
      context.handle(
        _lockedUntilMeta,
        lockedUntil.isAcceptableOrUnknown(
          data['locked_until']!,
          _lockedUntilMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_revocation_check_at')) {
      context.handle(
        _lastRevocationCheckAtMeta,
        lastRevocationCheckAt.isAcceptableOrUnknown(
          data['last_revocation_check_at']!,
          _lastRevocationCheckAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalUserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUserProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
      )!,
      pinSalt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_salt'],
      )!,
      roleLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_label'],
      ),
      lastSignedInAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_signed_in_at'],
      ),
      failedPinAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_pin_attempts'],
      )!,
      lockedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_until'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastRevocationCheckAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_revocation_check_at'],
      ),
    );
  }

  @override
  $LocalUserProfilesTable createAlias(String alias) {
    return $LocalUserProfilesTable(attachedDatabase, alias);
  }
}

class LocalUserProfile extends DataClass
    implements Insertable<LocalUserProfile> {
  /// Staff member's UUID from Identity Service (primary key).
  final String id;

  /// Display name, cached for the Profile Picker.
  final String displayName;

  /// Salted hash of the PIN (HMAC-SHA256).
  final String pinHash;

  /// Per-profile random salt for PIN hashing.
  final String pinSalt;

  /// Cached display-only role name.
  final String? roleLabel;

  /// Last successful sign-in timestamp.
  final DateTime? lastSignedInAt;

  /// Consecutive failed PIN attempts (persisted so lockout survives restart).
  final int failedPinAttempts;

  /// When the current lockout ends, or null when not locked out.
  final DateTime? lockedUntil;

  /// Row creation timestamp.
  final DateTime createdAt;

  /// Row last-updated timestamp.
  final DateTime updatedAt;

  /// When this profile's server-side role/existence was last confirmed via
  /// a revocation check (active-profile-only on reconnect, all-profiles on
  /// Profile Picker open). Null means never checked since local creation.
  final DateTime? lastRevocationCheckAt;
  const LocalUserProfile({
    required this.id,
    required this.displayName,
    required this.pinHash,
    required this.pinSalt,
    this.roleLabel,
    this.lastSignedInAt,
    required this.failedPinAttempts,
    this.lockedUntil,
    required this.createdAt,
    required this.updatedAt,
    this.lastRevocationCheckAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['pin_hash'] = Variable<String>(pinHash);
    map['pin_salt'] = Variable<String>(pinSalt);
    if (!nullToAbsent || roleLabel != null) {
      map['role_label'] = Variable<String>(roleLabel);
    }
    if (!nullToAbsent || lastSignedInAt != null) {
      map['last_signed_in_at'] = Variable<DateTime>(lastSignedInAt);
    }
    map['failed_pin_attempts'] = Variable<int>(failedPinAttempts);
    if (!nullToAbsent || lockedUntil != null) {
      map['locked_until'] = Variable<DateTime>(lockedUntil);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastRevocationCheckAt != null) {
      map['last_revocation_check_at'] = Variable<DateTime>(
        lastRevocationCheckAt,
      );
    }
    return map;
  }

  LocalUserProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalUserProfilesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      pinHash: Value(pinHash),
      pinSalt: Value(pinSalt),
      roleLabel: roleLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(roleLabel),
      lastSignedInAt: lastSignedInAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSignedInAt),
      failedPinAttempts: Value(failedPinAttempts),
      lockedUntil: lockedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedUntil),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastRevocationCheckAt: lastRevocationCheckAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRevocationCheckAt),
    );
  }

  factory LocalUserProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUserProfile(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      pinHash: serializer.fromJson<String>(json['pinHash']),
      pinSalt: serializer.fromJson<String>(json['pinSalt']),
      roleLabel: serializer.fromJson<String?>(json['roleLabel']),
      lastSignedInAt: serializer.fromJson<DateTime?>(json['lastSignedInAt']),
      failedPinAttempts: serializer.fromJson<int>(json['failedPinAttempts']),
      lockedUntil: serializer.fromJson<DateTime?>(json['lockedUntil']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastRevocationCheckAt: serializer.fromJson<DateTime?>(
        json['lastRevocationCheckAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'pinHash': serializer.toJson<String>(pinHash),
      'pinSalt': serializer.toJson<String>(pinSalt),
      'roleLabel': serializer.toJson<String?>(roleLabel),
      'lastSignedInAt': serializer.toJson<DateTime?>(lastSignedInAt),
      'failedPinAttempts': serializer.toJson<int>(failedPinAttempts),
      'lockedUntil': serializer.toJson<DateTime?>(lockedUntil),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastRevocationCheckAt': serializer.toJson<DateTime?>(
        lastRevocationCheckAt,
      ),
    };
  }

  LocalUserProfile copyWith({
    String? id,
    String? displayName,
    String? pinHash,
    String? pinSalt,
    Value<String?> roleLabel = const Value.absent(),
    Value<DateTime?> lastSignedInAt = const Value.absent(),
    int? failedPinAttempts,
    Value<DateTime?> lockedUntil = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastRevocationCheckAt = const Value.absent(),
  }) => LocalUserProfile(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    pinHash: pinHash ?? this.pinHash,
    pinSalt: pinSalt ?? this.pinSalt,
    roleLabel: roleLabel.present ? roleLabel.value : this.roleLabel,
    lastSignedInAt: lastSignedInAt.present
        ? lastSignedInAt.value
        : this.lastSignedInAt,
    failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
    lockedUntil: lockedUntil.present ? lockedUntil.value : this.lockedUntil,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastRevocationCheckAt: lastRevocationCheckAt.present
        ? lastRevocationCheckAt.value
        : this.lastRevocationCheckAt,
  );
  LocalUserProfile copyWithCompanion(LocalUserProfilesCompanion data) {
    return LocalUserProfile(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      pinSalt: data.pinSalt.present ? data.pinSalt.value : this.pinSalt,
      roleLabel: data.roleLabel.present ? data.roleLabel.value : this.roleLabel,
      lastSignedInAt: data.lastSignedInAt.present
          ? data.lastSignedInAt.value
          : this.lastSignedInAt,
      failedPinAttempts: data.failedPinAttempts.present
          ? data.failedPinAttempts.value
          : this.failedPinAttempts,
      lockedUntil: data.lockedUntil.present
          ? data.lockedUntil.value
          : this.lockedUntil,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastRevocationCheckAt: data.lastRevocationCheckAt.present
          ? data.lastRevocationCheckAt.value
          : this.lastRevocationCheckAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUserProfile(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('pinHash: $pinHash, ')
          ..write('pinSalt: $pinSalt, ')
          ..write('roleLabel: $roleLabel, ')
          ..write('lastSignedInAt: $lastSignedInAt, ')
          ..write('failedPinAttempts: $failedPinAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastRevocationCheckAt: $lastRevocationCheckAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    pinHash,
    pinSalt,
    roleLabel,
    lastSignedInAt,
    failedPinAttempts,
    lockedUntil,
    createdAt,
    updatedAt,
    lastRevocationCheckAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUserProfile &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.pinHash == this.pinHash &&
          other.pinSalt == this.pinSalt &&
          other.roleLabel == this.roleLabel &&
          other.lastSignedInAt == this.lastSignedInAt &&
          other.failedPinAttempts == this.failedPinAttempts &&
          other.lockedUntil == this.lockedUntil &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastRevocationCheckAt == this.lastRevocationCheckAt);
}

class LocalUserProfilesCompanion extends UpdateCompanion<LocalUserProfile> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> pinHash;
  final Value<String> pinSalt;
  final Value<String?> roleLabel;
  final Value<DateTime?> lastSignedInAt;
  final Value<int> failedPinAttempts;
  final Value<DateTime?> lockedUntil;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastRevocationCheckAt;
  final Value<int> rowid;
  const LocalUserProfilesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.pinSalt = const Value.absent(),
    this.roleLabel = const Value.absent(),
    this.lastSignedInAt = const Value.absent(),
    this.failedPinAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastRevocationCheckAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUserProfilesCompanion.insert({
    required String id,
    required String displayName,
    required String pinHash,
    required String pinSalt,
    this.roleLabel = const Value.absent(),
    this.lastSignedInAt = const Value.absent(),
    this.failedPinAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastRevocationCheckAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       pinHash = Value(pinHash),
       pinSalt = Value(pinSalt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalUserProfile> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? pinHash,
    Expression<String>? pinSalt,
    Expression<String>? roleLabel,
    Expression<DateTime>? lastSignedInAt,
    Expression<int>? failedPinAttempts,
    Expression<DateTime>? lockedUntil,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastRevocationCheckAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (pinHash != null) 'pin_hash': pinHash,
      if (pinSalt != null) 'pin_salt': pinSalt,
      if (roleLabel != null) 'role_label': roleLabel,
      if (lastSignedInAt != null) 'last_signed_in_at': lastSignedInAt,
      if (failedPinAttempts != null) 'failed_pin_attempts': failedPinAttempts,
      if (lockedUntil != null) 'locked_until': lockedUntil,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastRevocationCheckAt != null)
        'last_revocation_check_at': lastRevocationCheckAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUserProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? pinHash,
    Value<String>? pinSalt,
    Value<String?>? roleLabel,
    Value<DateTime?>? lastSignedInAt,
    Value<int>? failedPinAttempts,
    Value<DateTime?>? lockedUntil,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastRevocationCheckAt,
    Value<int>? rowid,
  }) {
    return LocalUserProfilesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      pinHash: pinHash ?? this.pinHash,
      pinSalt: pinSalt ?? this.pinSalt,
      roleLabel: roleLabel ?? this.roleLabel,
      lastSignedInAt: lastSignedInAt ?? this.lastSignedInAt,
      failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastRevocationCheckAt:
          lastRevocationCheckAt ?? this.lastRevocationCheckAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (pinSalt.present) {
      map['pin_salt'] = Variable<String>(pinSalt.value);
    }
    if (roleLabel.present) {
      map['role_label'] = Variable<String>(roleLabel.value);
    }
    if (lastSignedInAt.present) {
      map['last_signed_in_at'] = Variable<DateTime>(lastSignedInAt.value);
    }
    if (failedPinAttempts.present) {
      map['failed_pin_attempts'] = Variable<int>(failedPinAttempts.value);
    }
    if (lockedUntil.present) {
      map['locked_until'] = Variable<DateTime>(lockedUntil.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastRevocationCheckAt.present) {
      map['last_revocation_check_at'] = Variable<DateTime>(
        lastRevocationCheckAt.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('pinHash: $pinHash, ')
          ..write('pinSalt: $pinSalt, ')
          ..write('roleLabel: $roleLabel, ')
          ..write('lastSignedInAt: $lastSignedInAt, ')
          ..write('failedPinAttempts: $failedPinAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastRevocationCheckAt: $lastRevocationCheckAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceConfigTable extends DeviceConfig
    with TableInfo<$DeviceConfigTable, DeviceConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => 0,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessLocationIdMeta =
      const VerificationMeta('businessLocationId');
  @override
  late final GeneratedColumn<String> businessLocationId =
      GeneratedColumn<String>(
        'business_location_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceLabelMeta = const VerificationMeta(
    'deviceLabel',
  );
  @override
  late final GeneratedColumn<String> deviceLabel = GeneratedColumn<String>(
    'device_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _provisionedAtMeta = const VerificationMeta(
    'provisionedAt',
  );
  @override
  late final GeneratedColumn<DateTime> provisionedAt =
      GeneratedColumn<DateTime>(
        'provisioned_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    businessLocationId,
    businessName,
    deviceLabel,
    provisionedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_config';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceConfigData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('business_location_id')) {
      context.handle(
        _businessLocationIdMeta,
        businessLocationId.isAcceptableOrUnknown(
          data['business_location_id']!,
          _businessLocationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessLocationIdMeta);
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessNameMeta);
    }
    if (data.containsKey('device_label')) {
      context.handle(
        _deviceLabelMeta,
        deviceLabel.isAcceptableOrUnknown(
          data['device_label']!,
          _deviceLabelMeta,
        ),
      );
    }
    if (data.containsKey('provisioned_at')) {
      context.handle(
        _provisionedAtMeta,
        provisionedAt.isAcceptableOrUnknown(
          data['provisioned_at']!,
          _provisionedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_provisionedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceConfigData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceConfigData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      businessLocationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_location_id'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      )!,
      deviceLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_label'],
      ),
      provisionedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}provisioned_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DeviceConfigTable createAlias(String alias) {
    return $DeviceConfigTable(attachedDatabase, alias);
  }
}

class DeviceConfigData extends DataClass
    implements Insertable<DeviceConfigData> {
  /// Singleton key (always 0).
  final int id;

  /// Business UUID this device is locked to.
  final String businessId;

  /// Business location UUID this device is locked to.
  final String businessLocationId;

  /// Cached business name for offline use (receipts, headers).
  final String businessName;

  /// Optional device label (e.g., "Front counter").
  final String? deviceLabel;

  /// When this device was provisioned.
  final DateTime provisionedAt;

  /// Last provisioning update timestamp.
  final DateTime updatedAt;
  const DeviceConfigData({
    required this.id,
    required this.businessId,
    required this.businessLocationId,
    required this.businessName,
    this.deviceLabel,
    required this.provisionedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['business_id'] = Variable<String>(businessId);
    map['business_location_id'] = Variable<String>(businessLocationId);
    map['business_name'] = Variable<String>(businessName);
    if (!nullToAbsent || deviceLabel != null) {
      map['device_label'] = Variable<String>(deviceLabel);
    }
    map['provisioned_at'] = Variable<DateTime>(provisionedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DeviceConfigCompanion toCompanion(bool nullToAbsent) {
    return DeviceConfigCompanion(
      id: Value(id),
      businessId: Value(businessId),
      businessLocationId: Value(businessLocationId),
      businessName: Value(businessName),
      deviceLabel: deviceLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceLabel),
      provisionedAt: Value(provisionedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DeviceConfigData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceConfigData(
      id: serializer.fromJson<int>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      businessLocationId: serializer.fromJson<String>(
        json['businessLocationId'],
      ),
      businessName: serializer.fromJson<String>(json['businessName']),
      deviceLabel: serializer.fromJson<String?>(json['deviceLabel']),
      provisionedAt: serializer.fromJson<DateTime>(json['provisionedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'businessId': serializer.toJson<String>(businessId),
      'businessLocationId': serializer.toJson<String>(businessLocationId),
      'businessName': serializer.toJson<String>(businessName),
      'deviceLabel': serializer.toJson<String?>(deviceLabel),
      'provisionedAt': serializer.toJson<DateTime>(provisionedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DeviceConfigData copyWith({
    int? id,
    String? businessId,
    String? businessLocationId,
    String? businessName,
    Value<String?> deviceLabel = const Value.absent(),
    DateTime? provisionedAt,
    DateTime? updatedAt,
  }) => DeviceConfigData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    businessLocationId: businessLocationId ?? this.businessLocationId,
    businessName: businessName ?? this.businessName,
    deviceLabel: deviceLabel.present ? deviceLabel.value : this.deviceLabel,
    provisionedAt: provisionedAt ?? this.provisionedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DeviceConfigData copyWithCompanion(DeviceConfigCompanion data) {
    return DeviceConfigData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      businessLocationId: data.businessLocationId.present
          ? data.businessLocationId.value
          : this.businessLocationId,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      deviceLabel: data.deviceLabel.present
          ? data.deviceLabel.value
          : this.deviceLabel,
      provisionedAt: data.provisionedAt.present
          ? data.provisionedAt.value
          : this.provisionedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceConfigData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('businessName: $businessName, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('provisionedAt: $provisionedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    businessLocationId,
    businessName,
    deviceLabel,
    provisionedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceConfigData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.businessLocationId == this.businessLocationId &&
          other.businessName == this.businessName &&
          other.deviceLabel == this.deviceLabel &&
          other.provisionedAt == this.provisionedAt &&
          other.updatedAt == this.updatedAt);
}

class DeviceConfigCompanion extends UpdateCompanion<DeviceConfigData> {
  final Value<int> id;
  final Value<String> businessId;
  final Value<String> businessLocationId;
  final Value<String> businessName;
  final Value<String?> deviceLabel;
  final Value<DateTime> provisionedAt;
  final Value<DateTime> updatedAt;
  const DeviceConfigCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.businessLocationId = const Value.absent(),
    this.businessName = const Value.absent(),
    this.deviceLabel = const Value.absent(),
    this.provisionedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DeviceConfigCompanion.insert({
    this.id = const Value.absent(),
    required String businessId,
    required String businessLocationId,
    required String businessName,
    this.deviceLabel = const Value.absent(),
    required DateTime provisionedAt,
    required DateTime updatedAt,
  }) : businessId = Value(businessId),
       businessLocationId = Value(businessLocationId),
       businessName = Value(businessName),
       provisionedAt = Value(provisionedAt),
       updatedAt = Value(updatedAt);
  static Insertable<DeviceConfigData> custom({
    Expression<int>? id,
    Expression<String>? businessId,
    Expression<String>? businessLocationId,
    Expression<String>? businessName,
    Expression<String>? deviceLabel,
    Expression<DateTime>? provisionedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (businessLocationId != null)
        'business_location_id': businessLocationId,
      if (businessName != null) 'business_name': businessName,
      if (deviceLabel != null) 'device_label': deviceLabel,
      if (provisionedAt != null) 'provisioned_at': provisionedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DeviceConfigCompanion copyWith({
    Value<int>? id,
    Value<String>? businessId,
    Value<String>? businessLocationId,
    Value<String>? businessName,
    Value<String?>? deviceLabel,
    Value<DateTime>? provisionedAt,
    Value<DateTime>? updatedAt,
  }) {
    return DeviceConfigCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      businessName: businessName ?? this.businessName,
      deviceLabel: deviceLabel ?? this.deviceLabel,
      provisionedAt: provisionedAt ?? this.provisionedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (businessLocationId.present) {
      map['business_location_id'] = Variable<String>(businessLocationId.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (deviceLabel.present) {
      map['device_label'] = Variable<String>(deviceLabel.value);
    }
    if (provisionedAt.present) {
      map['provisioned_at'] = Variable<DateTime>(provisionedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceConfigCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('businessName: $businessName, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('provisionedAt: $provisionedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PendingSalesTable extends PendingSales
    with TableInfo<$PendingSalesTable, PendingSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientSaleIdMeta = const VerificationMeta(
    'clientSaleId',
  );
  @override
  late final GeneratedColumn<String> clientSaleId = GeneratedColumn<String>(
    'client_sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessLocationIdMeta =
      const VerificationMeta('businessLocationId');
  @override
  late final GeneratedColumn<String> businessLocationId =
      GeneratedColumn<String>(
        'business_location_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> discountAmount =
      GeneratedColumn<String>(
        'discount_amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('0'),
      ).withConverter<Decimal>($PendingSalesTable.$converterdiscountAmount);
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceSequenceMeta = const VerificationMeta(
    'deviceSequence',
  );
  @override
  late final GeneratedColumn<int> deviceSequence = GeneratedColumn<int>(
    'device_sequence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidOrRefundReasonMeta =
      const VerificationMeta('voidOrRefundReason');
  @override
  late final GeneratedColumn<String> voidOrRefundReason =
      GeneratedColumn<String>(
        'void_or_refund_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localOrderIdMeta = const VerificationMeta(
    'localOrderId',
  );
  @override
  late final GeneratedColumn<String> localOrderId = GeneratedColumn<String>(
    'local_order_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncAttemptCountMeta = const VerificationMeta(
    'syncAttemptCount',
  );
  @override
  late final GeneratedColumn<int> syncAttemptCount = GeneratedColumn<int>(
    'sync_attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientSaleId,
    status,
    businessLocationId,
    discountAmount,
    paymentMethod,
    occurredAt,
    deviceSequence,
    voidOrRefundReason,
    localOrderId,
    syncStatus,
    syncError,
    syncAttemptCount,
    lastAttemptAt,
    syncedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_sale_id')) {
      context.handle(
        _clientSaleIdMeta,
        clientSaleId.isAcceptableOrUnknown(
          data['client_sale_id']!,
          _clientSaleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientSaleIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('business_location_id')) {
      context.handle(
        _businessLocationIdMeta,
        businessLocationId.isAcceptableOrUnknown(
          data['business_location_id']!,
          _businessLocationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessLocationIdMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('device_sequence')) {
      context.handle(
        _deviceSequenceMeta,
        deviceSequence.isAcceptableOrUnknown(
          data['device_sequence']!,
          _deviceSequenceMeta,
        ),
      );
    }
    if (data.containsKey('void_or_refund_reason')) {
      context.handle(
        _voidOrRefundReasonMeta,
        voidOrRefundReason.isAcceptableOrUnknown(
          data['void_or_refund_reason']!,
          _voidOrRefundReasonMeta,
        ),
      );
    }
    if (data.containsKey('local_order_id')) {
      context.handle(
        _localOrderIdMeta,
        localOrderId.isAcceptableOrUnknown(
          data['local_order_id']!,
          _localOrderIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('sync_attempt_count')) {
      context.handle(
        _syncAttemptCountMeta,
        syncAttemptCount.isAcceptableOrUnknown(
          data['sync_attempt_count']!,
          _syncAttemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientSaleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_sale_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      businessLocationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_location_id'],
      )!,
      discountAmount: $PendingSalesTable.$converterdiscountAmount.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}discount_amount'],
        )!,
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      deviceSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_sequence'],
      ),
      voidOrRefundReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_or_refund_reason'],
      ),
      localOrderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_order_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      syncAttemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempt_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingSalesTable createAlias(String alias) {
    return $PendingSalesTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterdiscountAmount =
      const DecimalConverter();
}

class PendingSale extends DataClass implements Insertable<PendingSale> {
  /// Local row ID (autoincrement).
  final int id;

  /// Client-side idempotency key (UUID v4, unique).
  final String clientSaleId;

  /// Sale status: `completed`, `voided`, or `refunded`.
  /// The sale arrives in its final state; there is no "open/in-progress".
  final String status;

  /// Location this sale belongs to.
  final String businessLocationId;

  /// Discount applied to the whole sale.
  final Decimal discountAmount;

  /// Payment method used.
  final String paymentMethod;

  /// When the sale occurred (device time, UTC).
  final DateTime occurredAt;

  /// Optional monotonic device counter for the sale.
  final int? deviceSequence;

  /// Reason for voiding or refunding (required app-side iff status is
  /// voided/refunded, mirroring the backend's Pydantic validator).
  final String? voidOrRefundReason;

  /// Joins back to the existing UI `Order.id` (e.g., "ORD-0042") so the receipt
  /// can find both local and synced records without data duplication.
  /// No enforced FK (different ID space from `PendingSales.id`).
  final String? localOrderId;

  /// Local sync state: `pending`, `syncing`, `failed`, `synced`.
  /// `syncing` is a row-claim marker used for cross-isolate concurrency safety.
  final String syncStatus;

  /// Error message from the last sync attempt, if any.
  final String? syncError;

  /// Number of times this sale has been attempted.
  final int syncAttemptCount;

  /// Timestamp of the last sync attempt.
  final DateTime? lastAttemptAt;

  /// When the sale was successfully synced to the backend.
  final DateTime? syncedAt;

  /// Local row creation timestamp.
  final DateTime createdAt;
  const PendingSale({
    required this.id,
    required this.clientSaleId,
    required this.status,
    required this.businessLocationId,
    required this.discountAmount,
    required this.paymentMethod,
    required this.occurredAt,
    this.deviceSequence,
    this.voidOrRefundReason,
    this.localOrderId,
    required this.syncStatus,
    this.syncError,
    required this.syncAttemptCount,
    this.lastAttemptAt,
    this.syncedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_sale_id'] = Variable<String>(clientSaleId);
    map['status'] = Variable<String>(status);
    map['business_location_id'] = Variable<String>(businessLocationId);
    {
      map['discount_amount'] = Variable<String>(
        $PendingSalesTable.$converterdiscountAmount.toSql(discountAmount),
      );
    }
    map['payment_method'] = Variable<String>(paymentMethod);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || deviceSequence != null) {
      map['device_sequence'] = Variable<int>(deviceSequence);
    }
    if (!nullToAbsent || voidOrRefundReason != null) {
      map['void_or_refund_reason'] = Variable<String>(voidOrRefundReason);
    }
    if (!nullToAbsent || localOrderId != null) {
      map['local_order_id'] = Variable<String>(localOrderId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['sync_attempt_count'] = Variable<int>(syncAttemptCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingSalesCompanion toCompanion(bool nullToAbsent) {
    return PendingSalesCompanion(
      id: Value(id),
      clientSaleId: Value(clientSaleId),
      status: Value(status),
      businessLocationId: Value(businessLocationId),
      discountAmount: Value(discountAmount),
      paymentMethod: Value(paymentMethod),
      occurredAt: Value(occurredAt),
      deviceSequence: deviceSequence == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceSequence),
      voidOrRefundReason: voidOrRefundReason == null && nullToAbsent
          ? const Value.absent()
          : Value(voidOrRefundReason),
      localOrderId: localOrderId == null && nullToAbsent
          ? const Value.absent()
          : Value(localOrderId),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      syncAttemptCount: Value(syncAttemptCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      createdAt: Value(createdAt),
    );
  }

  factory PendingSale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSale(
      id: serializer.fromJson<int>(json['id']),
      clientSaleId: serializer.fromJson<String>(json['clientSaleId']),
      status: serializer.fromJson<String>(json['status']),
      businessLocationId: serializer.fromJson<String>(
        json['businessLocationId'],
      ),
      discountAmount: serializer.fromJson<Decimal>(json['discountAmount']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      deviceSequence: serializer.fromJson<int?>(json['deviceSequence']),
      voidOrRefundReason: serializer.fromJson<String?>(
        json['voidOrRefundReason'],
      ),
      localOrderId: serializer.fromJson<String?>(json['localOrderId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      syncAttemptCount: serializer.fromJson<int>(json['syncAttemptCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientSaleId': serializer.toJson<String>(clientSaleId),
      'status': serializer.toJson<String>(status),
      'businessLocationId': serializer.toJson<String>(businessLocationId),
      'discountAmount': serializer.toJson<Decimal>(discountAmount),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'deviceSequence': serializer.toJson<int?>(deviceSequence),
      'voidOrRefundReason': serializer.toJson<String?>(voidOrRefundReason),
      'localOrderId': serializer.toJson<String?>(localOrderId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'syncAttemptCount': serializer.toJson<int>(syncAttemptCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingSale copyWith({
    int? id,
    String? clientSaleId,
    String? status,
    String? businessLocationId,
    Decimal? discountAmount,
    String? paymentMethod,
    DateTime? occurredAt,
    Value<int?> deviceSequence = const Value.absent(),
    Value<String?> voidOrRefundReason = const Value.absent(),
    Value<String?> localOrderId = const Value.absent(),
    String? syncStatus,
    Value<String?> syncError = const Value.absent(),
    int? syncAttemptCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? createdAt,
  }) => PendingSale(
    id: id ?? this.id,
    clientSaleId: clientSaleId ?? this.clientSaleId,
    status: status ?? this.status,
    businessLocationId: businessLocationId ?? this.businessLocationId,
    discountAmount: discountAmount ?? this.discountAmount,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    occurredAt: occurredAt ?? this.occurredAt,
    deviceSequence: deviceSequence.present
        ? deviceSequence.value
        : this.deviceSequence,
    voidOrRefundReason: voidOrRefundReason.present
        ? voidOrRefundReason.value
        : this.voidOrRefundReason,
    localOrderId: localOrderId.present ? localOrderId.value : this.localOrderId,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingSale copyWithCompanion(PendingSalesCompanion data) {
    return PendingSale(
      id: data.id.present ? data.id.value : this.id,
      clientSaleId: data.clientSaleId.present
          ? data.clientSaleId.value
          : this.clientSaleId,
      status: data.status.present ? data.status.value : this.status,
      businessLocationId: data.businessLocationId.present
          ? data.businessLocationId.value
          : this.businessLocationId,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      deviceSequence: data.deviceSequence.present
          ? data.deviceSequence.value
          : this.deviceSequence,
      voidOrRefundReason: data.voidOrRefundReason.present
          ? data.voidOrRefundReason.value
          : this.voidOrRefundReason,
      localOrderId: data.localOrderId.present
          ? data.localOrderId.value
          : this.localOrderId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      syncAttemptCount: data.syncAttemptCount.present
          ? data.syncAttemptCount.value
          : this.syncAttemptCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSale(')
          ..write('id: $id, ')
          ..write('clientSaleId: $clientSaleId, ')
          ..write('status: $status, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('deviceSequence: $deviceSequence, ')
          ..write('voidOrRefundReason: $voidOrRefundReason, ')
          ..write('localOrderId: $localOrderId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('syncAttemptCount: $syncAttemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientSaleId,
    status,
    businessLocationId,
    discountAmount,
    paymentMethod,
    occurredAt,
    deviceSequence,
    voidOrRefundReason,
    localOrderId,
    syncStatus,
    syncError,
    syncAttemptCount,
    lastAttemptAt,
    syncedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSale &&
          other.id == this.id &&
          other.clientSaleId == this.clientSaleId &&
          other.status == this.status &&
          other.businessLocationId == this.businessLocationId &&
          other.discountAmount == this.discountAmount &&
          other.paymentMethod == this.paymentMethod &&
          other.occurredAt == this.occurredAt &&
          other.deviceSequence == this.deviceSequence &&
          other.voidOrRefundReason == this.voidOrRefundReason &&
          other.localOrderId == this.localOrderId &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.syncAttemptCount == this.syncAttemptCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.syncedAt == this.syncedAt &&
          other.createdAt == this.createdAt);
}

class PendingSalesCompanion extends UpdateCompanion<PendingSale> {
  final Value<int> id;
  final Value<String> clientSaleId;
  final Value<String> status;
  final Value<String> businessLocationId;
  final Value<Decimal> discountAmount;
  final Value<String> paymentMethod;
  final Value<DateTime> occurredAt;
  final Value<int?> deviceSequence;
  final Value<String?> voidOrRefundReason;
  final Value<String?> localOrderId;
  final Value<String> syncStatus;
  final Value<String?> syncError;
  final Value<int> syncAttemptCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> createdAt;
  const PendingSalesCompanion({
    this.id = const Value.absent(),
    this.clientSaleId = const Value.absent(),
    this.status = const Value.absent(),
    this.businessLocationId = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.deviceSequence = const Value.absent(),
    this.voidOrRefundReason = const Value.absent(),
    this.localOrderId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.syncAttemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingSalesCompanion.insert({
    this.id = const Value.absent(),
    required String clientSaleId,
    required String status,
    required String businessLocationId,
    this.discountAmount = const Value.absent(),
    required String paymentMethod,
    required DateTime occurredAt,
    this.deviceSequence = const Value.absent(),
    this.voidOrRefundReason = const Value.absent(),
    this.localOrderId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.syncAttemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    required DateTime createdAt,
  }) : clientSaleId = Value(clientSaleId),
       status = Value(status),
       businessLocationId = Value(businessLocationId),
       paymentMethod = Value(paymentMethod),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt);
  static Insertable<PendingSale> custom({
    Expression<int>? id,
    Expression<String>? clientSaleId,
    Expression<String>? status,
    Expression<String>? businessLocationId,
    Expression<String>? discountAmount,
    Expression<String>? paymentMethod,
    Expression<DateTime>? occurredAt,
    Expression<int>? deviceSequence,
    Expression<String>? voidOrRefundReason,
    Expression<String>? localOrderId,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? syncAttemptCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientSaleId != null) 'client_sale_id': clientSaleId,
      if (status != null) 'status': status,
      if (businessLocationId != null)
        'business_location_id': businessLocationId,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (deviceSequence != null) 'device_sequence': deviceSequence,
      if (voidOrRefundReason != null)
        'void_or_refund_reason': voidOrRefundReason,
      if (localOrderId != null) 'local_order_id': localOrderId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (syncAttemptCount != null) 'sync_attempt_count': syncAttemptCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingSalesCompanion copyWith({
    Value<int>? id,
    Value<String>? clientSaleId,
    Value<String>? status,
    Value<String>? businessLocationId,
    Value<Decimal>? discountAmount,
    Value<String>? paymentMethod,
    Value<DateTime>? occurredAt,
    Value<int?>? deviceSequence,
    Value<String?>? voidOrRefundReason,
    Value<String?>? localOrderId,
    Value<String>? syncStatus,
    Value<String?>? syncError,
    Value<int>? syncAttemptCount,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? createdAt,
  }) {
    return PendingSalesCompanion(
      id: id ?? this.id,
      clientSaleId: clientSaleId ?? this.clientSaleId,
      status: status ?? this.status,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      discountAmount: discountAmount ?? this.discountAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      occurredAt: occurredAt ?? this.occurredAt,
      deviceSequence: deviceSequence ?? this.deviceSequence,
      voidOrRefundReason: voidOrRefundReason ?? this.voidOrRefundReason,
      localOrderId: localOrderId ?? this.localOrderId,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientSaleId.present) {
      map['client_sale_id'] = Variable<String>(clientSaleId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (businessLocationId.present) {
      map['business_location_id'] = Variable<String>(businessLocationId.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<String>(
        $PendingSalesTable.$converterdiscountAmount.toSql(discountAmount.value),
      );
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (deviceSequence.present) {
      map['device_sequence'] = Variable<int>(deviceSequence.value);
    }
    if (voidOrRefundReason.present) {
      map['void_or_refund_reason'] = Variable<String>(voidOrRefundReason.value);
    }
    if (localOrderId.present) {
      map['local_order_id'] = Variable<String>(localOrderId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (syncAttemptCount.present) {
      map['sync_attempt_count'] = Variable<int>(syncAttemptCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSalesCompanion(')
          ..write('id: $id, ')
          ..write('clientSaleId: $clientSaleId, ')
          ..write('status: $status, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('deviceSequence: $deviceSequence, ')
          ..write('voidOrRefundReason: $voidOrRefundReason, ')
          ..write('localOrderId: $localOrderId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('syncAttemptCount: $syncAttemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PendingSaleLineItemsTable extends PendingSaleLineItems
    with TableInfo<$PendingSaleLineItemsTable, PendingSaleLineItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSaleLineItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pendingSaleIdMeta = const VerificationMeta(
    'pendingSaleId',
  );
  @override
  late final GeneratedColumn<int> pendingSaleId = GeneratedColumn<int>(
    'pending_sale_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pending_sales (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> quantity =
      GeneratedColumn<String>(
        'quantity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($PendingSaleLineItemsTable.$converterquantity);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> unitPrice =
      GeneratedColumn<String>(
        'unit_price',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($PendingSaleLineItemsTable.$converterunitPrice);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> discountAmount =
      GeneratedColumn<String>(
        'discount_amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('0'),
      ).withConverter<Decimal>(
        $PendingSaleLineItemsTable.$converterdiscountAmount,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pendingSaleId,
    itemId,
    quantity,
    unitPrice,
    discountAmount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sale_line_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSaleLineItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pending_sale_id')) {
      context.handle(
        _pendingSaleIdMeta,
        pendingSaleId.isAcceptableOrUnknown(
          data['pending_sale_id']!,
          _pendingSaleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pendingSaleIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSaleLineItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSaleLineItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      pendingSaleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pending_sale_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      quantity: $PendingSaleLineItemsTable.$converterquantity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quantity'],
        )!,
      ),
      unitPrice: $PendingSaleLineItemsTable.$converterunitPrice.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit_price'],
        )!,
      ),
      discountAmount: $PendingSaleLineItemsTable.$converterdiscountAmount
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}discount_amount'],
            )!,
          ),
    );
  }

  @override
  $PendingSaleLineItemsTable createAlias(String alias) {
    return $PendingSaleLineItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterquantity =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $converterunitPrice =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $converterdiscountAmount =
      const DecimalConverter();
}

class PendingSaleLineItem extends DataClass
    implements Insertable<PendingSaleLineItem> {
  /// Local row ID (autoincrement).
  final int id;

  /// Foreign key to the sale this line belongs to.
  final int pendingSaleId;

  /// Item UUID from the inventory catalog.
  /// Soft-references `CachedItems.id` without an FK constraint
  /// (see `CachedItems` for rationale).
  final String itemId;

  /// Quantity sold (strictly positive, validated app-side).
  final Decimal quantity;

  /// Unit price of the item.
  final Decimal unitPrice;

  /// Discount applied to this line.
  final Decimal discountAmount;
  const PendingSaleLineItem({
    required this.id,
    required this.pendingSaleId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pending_sale_id'] = Variable<int>(pendingSaleId);
    map['item_id'] = Variable<String>(itemId);
    {
      map['quantity'] = Variable<String>(
        $PendingSaleLineItemsTable.$converterquantity.toSql(quantity),
      );
    }
    {
      map['unit_price'] = Variable<String>(
        $PendingSaleLineItemsTable.$converterunitPrice.toSql(unitPrice),
      );
    }
    {
      map['discount_amount'] = Variable<String>(
        $PendingSaleLineItemsTable.$converterdiscountAmount.toSql(
          discountAmount,
        ),
      );
    }
    return map;
  }

  PendingSaleLineItemsCompanion toCompanion(bool nullToAbsent) {
    return PendingSaleLineItemsCompanion(
      id: Value(id),
      pendingSaleId: Value(pendingSaleId),
      itemId: Value(itemId),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      discountAmount: Value(discountAmount),
    );
  }

  factory PendingSaleLineItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSaleLineItem(
      id: serializer.fromJson<int>(json['id']),
      pendingSaleId: serializer.fromJson<int>(json['pendingSaleId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      quantity: serializer.fromJson<Decimal>(json['quantity']),
      unitPrice: serializer.fromJson<Decimal>(json['unitPrice']),
      discountAmount: serializer.fromJson<Decimal>(json['discountAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pendingSaleId': serializer.toJson<int>(pendingSaleId),
      'itemId': serializer.toJson<String>(itemId),
      'quantity': serializer.toJson<Decimal>(quantity),
      'unitPrice': serializer.toJson<Decimal>(unitPrice),
      'discountAmount': serializer.toJson<Decimal>(discountAmount),
    };
  }

  PendingSaleLineItem copyWith({
    int? id,
    int? pendingSaleId,
    String? itemId,
    Decimal? quantity,
    Decimal? unitPrice,
    Decimal? discountAmount,
  }) => PendingSaleLineItem(
    id: id ?? this.id,
    pendingSaleId: pendingSaleId ?? this.pendingSaleId,
    itemId: itemId ?? this.itemId,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    discountAmount: discountAmount ?? this.discountAmount,
  );
  PendingSaleLineItem copyWithCompanion(PendingSaleLineItemsCompanion data) {
    return PendingSaleLineItem(
      id: data.id.present ? data.id.value : this.id,
      pendingSaleId: data.pendingSaleId.present
          ? data.pendingSaleId.value
          : this.pendingSaleId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSaleLineItem(')
          ..write('id: $id, ')
          ..write('pendingSaleId: $pendingSaleId, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('discountAmount: $discountAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pendingSaleId,
    itemId,
    quantity,
    unitPrice,
    discountAmount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSaleLineItem &&
          other.id == this.id &&
          other.pendingSaleId == this.pendingSaleId &&
          other.itemId == this.itemId &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.discountAmount == this.discountAmount);
}

class PendingSaleLineItemsCompanion
    extends UpdateCompanion<PendingSaleLineItem> {
  final Value<int> id;
  final Value<int> pendingSaleId;
  final Value<String> itemId;
  final Value<Decimal> quantity;
  final Value<Decimal> unitPrice;
  final Value<Decimal> discountAmount;
  const PendingSaleLineItemsCompanion({
    this.id = const Value.absent(),
    this.pendingSaleId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.discountAmount = const Value.absent(),
  });
  PendingSaleLineItemsCompanion.insert({
    this.id = const Value.absent(),
    required int pendingSaleId,
    required String itemId,
    required Decimal quantity,
    required Decimal unitPrice,
    this.discountAmount = const Value.absent(),
  }) : pendingSaleId = Value(pendingSaleId),
       itemId = Value(itemId),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice);
  static Insertable<PendingSaleLineItem> custom({
    Expression<int>? id,
    Expression<int>? pendingSaleId,
    Expression<String>? itemId,
    Expression<String>? quantity,
    Expression<String>? unitPrice,
    Expression<String>? discountAmount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pendingSaleId != null) 'pending_sale_id': pendingSaleId,
      if (itemId != null) 'item_id': itemId,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (discountAmount != null) 'discount_amount': discountAmount,
    });
  }

  PendingSaleLineItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? pendingSaleId,
    Value<String>? itemId,
    Value<Decimal>? quantity,
    Value<Decimal>? unitPrice,
    Value<Decimal>? discountAmount,
  }) {
    return PendingSaleLineItemsCompanion(
      id: id ?? this.id,
      pendingSaleId: pendingSaleId ?? this.pendingSaleId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pendingSaleId.present) {
      map['pending_sale_id'] = Variable<int>(pendingSaleId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(
        $PendingSaleLineItemsTable.$converterquantity.toSql(quantity.value),
      );
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<String>(
        $PendingSaleLineItemsTable.$converterunitPrice.toSql(unitPrice.value),
      );
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<String>(
        $PendingSaleLineItemsTable.$converterdiscountAmount.toSql(
          discountAmount.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSaleLineItemsCompanion(')
          ..write('id: $id, ')
          ..write('pendingSaleId: $pendingSaleId, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('discountAmount: $discountAmount')
          ..write(')'))
        .toString();
  }
}

class $CachedItemsTable extends CachedItems
    with TableInfo<$CachedItemsTable, CachedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessLocationIdMeta =
      const VerificationMeta('businessLocationId');
  @override
  late final GeneratedColumn<String> businessLocationId =
      GeneratedColumn<String>(
        'business_location_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitOfMeasureMeta = const VerificationMeta(
    'unitOfMeasure',
  );
  @override
  late final GeneratedColumn<String> unitOfMeasure = GeneratedColumn<String>(
    'unit_of_measure',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String>
  reorderThreshold = GeneratedColumn<String>(
    'reorder_threshold',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Decimal>($CachedItemsTable.$converterreorderThreshold);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> reorderQuantity =
      GeneratedColumn<String>(
        'reorder_quantity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($CachedItemsTable.$converterreorderQuantity);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> sellingPrice =
      GeneratedColumn<String>(
        'selling_price',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>($CachedItemsTable.$convertersellingPricen);
  static const VerificationMeta _allowNegativeStockMeta =
      const VerificationMeta('allowNegativeStock');
  @override
  late final GeneratedColumn<bool> allowNegativeStock = GeneratedColumn<bool>(
    'allow_negative_stock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_negative_stock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtServerMeta = const VerificationMeta(
    'createdAtServer',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtServer =
      GeneratedColumn<DateTime>(
        'created_at_server',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtServerMeta = const VerificationMeta(
    'updatedAtServer',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtServer =
      GeneratedColumn<DateTime>(
        'updated_at_server',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    businessLocationId,
    name,
    unitOfMeasure,
    category,
    reorderThreshold,
    reorderQuantity,
    sellingPrice,
    allowNegativeStock,
    itemType,
    isActive,
    createdAtServer,
    updatedAtServer,
    lastSeenAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('business_location_id')) {
      context.handle(
        _businessLocationIdMeta,
        businessLocationId.isAcceptableOrUnknown(
          data['business_location_id']!,
          _businessLocationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessLocationIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit_of_measure')) {
      context.handle(
        _unitOfMeasureMeta,
        unitOfMeasure.isAcceptableOrUnknown(
          data['unit_of_measure']!,
          _unitOfMeasureMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitOfMeasureMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('allow_negative_stock')) {
      context.handle(
        _allowNegativeStockMeta,
        allowNegativeStock.isAcceptableOrUnknown(
          data['allow_negative_stock']!,
          _allowNegativeStockMeta,
        ),
      );
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at_server')) {
      context.handle(
        _createdAtServerMeta,
        createdAtServer.isAcceptableOrUnknown(
          data['created_at_server']!,
          _createdAtServerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtServerMeta);
    }
    if (data.containsKey('updated_at_server')) {
      context.handle(
        _updatedAtServerMeta,
        updatedAtServer.isAcceptableOrUnknown(
          data['updated_at_server']!,
          _updatedAtServerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtServerMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      businessLocationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_location_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unitOfMeasure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_of_measure'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      reorderThreshold: $CachedItemsTable.$converterreorderThreshold.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reorder_threshold'],
        )!,
      ),
      reorderQuantity: $CachedItemsTable.$converterreorderQuantity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reorder_quantity'],
        )!,
      ),
      sellingPrice: $CachedItemsTable.$convertersellingPricen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}selling_price'],
        ),
      ),
      allowNegativeStock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_negative_stock'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAtServer: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_server'],
      )!,
      updatedAtServer: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_server'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
    );
  }

  @override
  $CachedItemsTable createAlias(String alias) {
    return $CachedItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterreorderThreshold =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $converterreorderQuantity =
      const DecimalConverter();
  static TypeConverter<Decimal, String> $convertersellingPrice =
      const DecimalConverter();
  static TypeConverter<Decimal?, String?> $convertersellingPricen =
      NullAwareTypeConverter.wrap($convertersellingPrice);
}

class CachedItem extends DataClass implements Insertable<CachedItem> {
  /// Item UUID (primary key).
  final String id;

  /// Business this item belongs to.
  final String businessId;

  /// Business location this item belongs to.
  final String businessLocationId;

  /// Item name.
  final String name;

  /// Unit of measure (e.g., 'kg', 'l', 'unit', 'pack').
  final String unitOfMeasure;

  /// Item category (optional).
  final String? category;

  /// Reorder threshold quantity.
  final Decimal reorderThreshold;

  /// Reorder quantity.
  final Decimal reorderQuantity;

  /// Selling price (optional).
  final Decimal? sellingPrice;

  /// Whether negative stock is allowed.
  final bool allowNegativeStock;

  /// Item type: `sellable`, `raw_material`, or `both`.
  final String itemType;

  /// Soft-delete flag: false means the item is no longer available from the
  /// catalog, but existing references to it (e.g., completed sales) remain valid.
  final bool isActive;

  /// Backend creation timestamp.
  final DateTime createdAtServer;

  /// Backend last-update timestamp (used to detect changed rows on pull).
  final DateTime updatedAtServer;

  /// Local timestamp of the most recent pull that included this row.
  /// Anything with a stale `lastSeenAt` after a full pull gets `isActive=false`.
  final DateTime lastSeenAt;

  /// Local timestamp of the last catalog sync that touched this row.
  final DateTime lastSyncedAt;
  const CachedItem({
    required this.id,
    required this.businessId,
    required this.businessLocationId,
    required this.name,
    required this.unitOfMeasure,
    this.category,
    required this.reorderThreshold,
    required this.reorderQuantity,
    this.sellingPrice,
    required this.allowNegativeStock,
    required this.itemType,
    required this.isActive,
    required this.createdAtServer,
    required this.updatedAtServer,
    required this.lastSeenAt,
    required this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['business_location_id'] = Variable<String>(businessLocationId);
    map['name'] = Variable<String>(name);
    map['unit_of_measure'] = Variable<String>(unitOfMeasure);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    {
      map['reorder_threshold'] = Variable<String>(
        $CachedItemsTable.$converterreorderThreshold.toSql(reorderThreshold),
      );
    }
    {
      map['reorder_quantity'] = Variable<String>(
        $CachedItemsTable.$converterreorderQuantity.toSql(reorderQuantity),
      );
    }
    if (!nullToAbsent || sellingPrice != null) {
      map['selling_price'] = Variable<String>(
        $CachedItemsTable.$convertersellingPricen.toSql(sellingPrice),
      );
    }
    map['allow_negative_stock'] = Variable<bool>(allowNegativeStock);
    map['item_type'] = Variable<String>(itemType);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at_server'] = Variable<DateTime>(createdAtServer);
    map['updated_at_server'] = Variable<DateTime>(updatedAtServer);
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    return map;
  }

  CachedItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedItemsCompanion(
      id: Value(id),
      businessId: Value(businessId),
      businessLocationId: Value(businessLocationId),
      name: Value(name),
      unitOfMeasure: Value(unitOfMeasure),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      reorderThreshold: Value(reorderThreshold),
      reorderQuantity: Value(reorderQuantity),
      sellingPrice: sellingPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(sellingPrice),
      allowNegativeStock: Value(allowNegativeStock),
      itemType: Value(itemType),
      isActive: Value(isActive),
      createdAtServer: Value(createdAtServer),
      updatedAtServer: Value(updatedAtServer),
      lastSeenAt: Value(lastSeenAt),
      lastSyncedAt: Value(lastSyncedAt),
    );
  }

  factory CachedItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedItem(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      businessLocationId: serializer.fromJson<String>(
        json['businessLocationId'],
      ),
      name: serializer.fromJson<String>(json['name']),
      unitOfMeasure: serializer.fromJson<String>(json['unitOfMeasure']),
      category: serializer.fromJson<String?>(json['category']),
      reorderThreshold: serializer.fromJson<Decimal>(json['reorderThreshold']),
      reorderQuantity: serializer.fromJson<Decimal>(json['reorderQuantity']),
      sellingPrice: serializer.fromJson<Decimal?>(json['sellingPrice']),
      allowNegativeStock: serializer.fromJson<bool>(json['allowNegativeStock']),
      itemType: serializer.fromJson<String>(json['itemType']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAtServer: serializer.fromJson<DateTime>(json['createdAtServer']),
      updatedAtServer: serializer.fromJson<DateTime>(json['updatedAtServer']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'businessLocationId': serializer.toJson<String>(businessLocationId),
      'name': serializer.toJson<String>(name),
      'unitOfMeasure': serializer.toJson<String>(unitOfMeasure),
      'category': serializer.toJson<String?>(category),
      'reorderThreshold': serializer.toJson<Decimal>(reorderThreshold),
      'reorderQuantity': serializer.toJson<Decimal>(reorderQuantity),
      'sellingPrice': serializer.toJson<Decimal?>(sellingPrice),
      'allowNegativeStock': serializer.toJson<bool>(allowNegativeStock),
      'itemType': serializer.toJson<String>(itemType),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAtServer': serializer.toJson<DateTime>(createdAtServer),
      'updatedAtServer': serializer.toJson<DateTime>(updatedAtServer),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
    };
  }

  CachedItem copyWith({
    String? id,
    String? businessId,
    String? businessLocationId,
    String? name,
    String? unitOfMeasure,
    Value<String?> category = const Value.absent(),
    Decimal? reorderThreshold,
    Decimal? reorderQuantity,
    Value<Decimal?> sellingPrice = const Value.absent(),
    bool? allowNegativeStock,
    String? itemType,
    bool? isActive,
    DateTime? createdAtServer,
    DateTime? updatedAtServer,
    DateTime? lastSeenAt,
    DateTime? lastSyncedAt,
  }) => CachedItem(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    businessLocationId: businessLocationId ?? this.businessLocationId,
    name: name ?? this.name,
    unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
    category: category.present ? category.value : this.category,
    reorderThreshold: reorderThreshold ?? this.reorderThreshold,
    reorderQuantity: reorderQuantity ?? this.reorderQuantity,
    sellingPrice: sellingPrice.present ? sellingPrice.value : this.sellingPrice,
    allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
    itemType: itemType ?? this.itemType,
    isActive: isActive ?? this.isActive,
    createdAtServer: createdAtServer ?? this.createdAtServer,
    updatedAtServer: updatedAtServer ?? this.updatedAtServer,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
  CachedItem copyWithCompanion(CachedItemsCompanion data) {
    return CachedItem(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      businessLocationId: data.businessLocationId.present
          ? data.businessLocationId.value
          : this.businessLocationId,
      name: data.name.present ? data.name.value : this.name,
      unitOfMeasure: data.unitOfMeasure.present
          ? data.unitOfMeasure.value
          : this.unitOfMeasure,
      category: data.category.present ? data.category.value : this.category,
      reorderThreshold: data.reorderThreshold.present
          ? data.reorderThreshold.value
          : this.reorderThreshold,
      reorderQuantity: data.reorderQuantity.present
          ? data.reorderQuantity.value
          : this.reorderQuantity,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      allowNegativeStock: data.allowNegativeStock.present
          ? data.allowNegativeStock.value
          : this.allowNegativeStock,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAtServer: data.createdAtServer.present
          ? data.createdAtServer.value
          : this.createdAtServer,
      updatedAtServer: data.updatedAtServer.present
          ? data.updatedAtServer.value
          : this.updatedAtServer,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedItem(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('name: $name, ')
          ..write('unitOfMeasure: $unitOfMeasure, ')
          ..write('category: $category, ')
          ..write('reorderThreshold: $reorderThreshold, ')
          ..write('reorderQuantity: $reorderQuantity, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('allowNegativeStock: $allowNegativeStock, ')
          ..write('itemType: $itemType, ')
          ..write('isActive: $isActive, ')
          ..write('createdAtServer: $createdAtServer, ')
          ..write('updatedAtServer: $updatedAtServer, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    businessLocationId,
    name,
    unitOfMeasure,
    category,
    reorderThreshold,
    reorderQuantity,
    sellingPrice,
    allowNegativeStock,
    itemType,
    isActive,
    createdAtServer,
    updatedAtServer,
    lastSeenAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedItem &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.businessLocationId == this.businessLocationId &&
          other.name == this.name &&
          other.unitOfMeasure == this.unitOfMeasure &&
          other.category == this.category &&
          other.reorderThreshold == this.reorderThreshold &&
          other.reorderQuantity == this.reorderQuantity &&
          other.sellingPrice == this.sellingPrice &&
          other.allowNegativeStock == this.allowNegativeStock &&
          other.itemType == this.itemType &&
          other.isActive == this.isActive &&
          other.createdAtServer == this.createdAtServer &&
          other.updatedAtServer == this.updatedAtServer &&
          other.lastSeenAt == this.lastSeenAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CachedItemsCompanion extends UpdateCompanion<CachedItem> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> businessLocationId;
  final Value<String> name;
  final Value<String> unitOfMeasure;
  final Value<String?> category;
  final Value<Decimal> reorderThreshold;
  final Value<Decimal> reorderQuantity;
  final Value<Decimal?> sellingPrice;
  final Value<bool> allowNegativeStock;
  final Value<String> itemType;
  final Value<bool> isActive;
  final Value<DateTime> createdAtServer;
  final Value<DateTime> updatedAtServer;
  final Value<DateTime> lastSeenAt;
  final Value<DateTime> lastSyncedAt;
  final Value<int> rowid;
  const CachedItemsCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.businessLocationId = const Value.absent(),
    this.name = const Value.absent(),
    this.unitOfMeasure = const Value.absent(),
    this.category = const Value.absent(),
    this.reorderThreshold = const Value.absent(),
    this.reorderQuantity = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.allowNegativeStock = const Value.absent(),
    this.itemType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAtServer = const Value.absent(),
    this.updatedAtServer = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedItemsCompanion.insert({
    required String id,
    required String businessId,
    required String businessLocationId,
    required String name,
    required String unitOfMeasure,
    this.category = const Value.absent(),
    required Decimal reorderThreshold,
    required Decimal reorderQuantity,
    this.sellingPrice = const Value.absent(),
    this.allowNegativeStock = const Value.absent(),
    required String itemType,
    this.isActive = const Value.absent(),
    required DateTime createdAtServer,
    required DateTime updatedAtServer,
    required DateTime lastSeenAt,
    required DateTime lastSyncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       businessLocationId = Value(businessLocationId),
       name = Value(name),
       unitOfMeasure = Value(unitOfMeasure),
       reorderThreshold = Value(reorderThreshold),
       reorderQuantity = Value(reorderQuantity),
       itemType = Value(itemType),
       createdAtServer = Value(createdAtServer),
       updatedAtServer = Value(updatedAtServer),
       lastSeenAt = Value(lastSeenAt),
       lastSyncedAt = Value(lastSyncedAt);
  static Insertable<CachedItem> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? businessLocationId,
    Expression<String>? name,
    Expression<String>? unitOfMeasure,
    Expression<String>? category,
    Expression<String>? reorderThreshold,
    Expression<String>? reorderQuantity,
    Expression<String>? sellingPrice,
    Expression<bool>? allowNegativeStock,
    Expression<String>? itemType,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAtServer,
    Expression<DateTime>? updatedAtServer,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (businessLocationId != null)
        'business_location_id': businessLocationId,
      if (name != null) 'name': name,
      if (unitOfMeasure != null) 'unit_of_measure': unitOfMeasure,
      if (category != null) 'category': category,
      if (reorderThreshold != null) 'reorder_threshold': reorderThreshold,
      if (reorderQuantity != null) 'reorder_quantity': reorderQuantity,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (allowNegativeStock != null)
        'allow_negative_stock': allowNegativeStock,
      if (itemType != null) 'item_type': itemType,
      if (isActive != null) 'is_active': isActive,
      if (createdAtServer != null) 'created_at_server': createdAtServer,
      if (updatedAtServer != null) 'updated_at_server': updatedAtServer,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? businessLocationId,
    Value<String>? name,
    Value<String>? unitOfMeasure,
    Value<String?>? category,
    Value<Decimal>? reorderThreshold,
    Value<Decimal>? reorderQuantity,
    Value<Decimal?>? sellingPrice,
    Value<bool>? allowNegativeStock,
    Value<String>? itemType,
    Value<bool>? isActive,
    Value<DateTime>? createdAtServer,
    Value<DateTime>? updatedAtServer,
    Value<DateTime>? lastSeenAt,
    Value<DateTime>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return CachedItemsCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      name: name ?? this.name,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      category: category ?? this.category,
      reorderThreshold: reorderThreshold ?? this.reorderThreshold,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
      itemType: itemType ?? this.itemType,
      isActive: isActive ?? this.isActive,
      createdAtServer: createdAtServer ?? this.createdAtServer,
      updatedAtServer: updatedAtServer ?? this.updatedAtServer,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (businessLocationId.present) {
      map['business_location_id'] = Variable<String>(businessLocationId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unitOfMeasure.present) {
      map['unit_of_measure'] = Variable<String>(unitOfMeasure.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (reorderThreshold.present) {
      map['reorder_threshold'] = Variable<String>(
        $CachedItemsTable.$converterreorderThreshold.toSql(
          reorderThreshold.value,
        ),
      );
    }
    if (reorderQuantity.present) {
      map['reorder_quantity'] = Variable<String>(
        $CachedItemsTable.$converterreorderQuantity.toSql(
          reorderQuantity.value,
        ),
      );
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<String>(
        $CachedItemsTable.$convertersellingPricen.toSql(sellingPrice.value),
      );
    }
    if (allowNegativeStock.present) {
      map['allow_negative_stock'] = Variable<bool>(allowNegativeStock.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAtServer.present) {
      map['created_at_server'] = Variable<DateTime>(createdAtServer.value);
    }
    if (updatedAtServer.present) {
      map['updated_at_server'] = Variable<DateTime>(updatedAtServer.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedItemsCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('name: $name, ')
          ..write('unitOfMeasure: $unitOfMeasure, ')
          ..write('category: $category, ')
          ..write('reorderThreshold: $reorderThreshold, ')
          ..write('reorderQuantity: $reorderQuantity, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('allowNegativeStock: $allowNegativeStock, ')
          ..write('itemType: $itemType, ')
          ..write('isActive: $isActive, ')
          ..write('createdAtServer: $createdAtServer, ')
          ..write('updatedAtServer: $updatedAtServer, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPermissionsTable extends CachedPermissions
    with TableInfo<$CachedPermissionsTable, CachedPermission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPermissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_user_profiles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessLocationIdMeta =
      const VerificationMeta('businessLocationId');
  @override
  late final GeneratedColumn<String> businessLocationId =
      GeneratedColumn<String>(
        'business_location_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _roleNameMeta = const VerificationMeta(
    'roleName',
  );
  @override
  late final GeneratedColumn<String> roleName = GeneratedColumn<String>(
    'role_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionCodesMeta = const VerificationMeta(
    'permissionCodes',
  );
  @override
  late final GeneratedColumn<String> permissionCodes = GeneratedColumn<String>(
    'permission_codes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    businessId,
    businessName,
    businessLocationId,
    roleName,
    permissionCodes,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_permissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPermission> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessNameMeta);
    }
    if (data.containsKey('business_location_id')) {
      context.handle(
        _businessLocationIdMeta,
        businessLocationId.isAcceptableOrUnknown(
          data['business_location_id']!,
          _businessLocationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessLocationIdMeta);
    }
    if (data.containsKey('role_name')) {
      context.handle(
        _roleNameMeta,
        roleName.isAcceptableOrUnknown(data['role_name']!, _roleNameMeta),
      );
    } else if (isInserting) {
      context.missing(_roleNameMeta);
    }
    if (data.containsKey('permission_codes')) {
      context.handle(
        _permissionCodesMeta,
        permissionCodes.isAcceptableOrUnknown(
          data['permission_codes']!,
          _permissionCodesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_permissionCodesMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  CachedPermission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPermission(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      )!,
      businessLocationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_location_id'],
      )!,
      roleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_name'],
      )!,
      permissionCodes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permission_codes'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedPermissionsTable createAlias(String alias) {
    return $CachedPermissionsTable(attachedDatabase, alias);
  }
}

class CachedPermission extends DataClass
    implements Insertable<CachedPermission> {
  /// Staff member's UUID; also the foreign key to `LocalUserProfiles.id`.
  final String userId;

  /// Business this permission set applies to.
  final String businessId;

  /// Cached business name for offline display.
  final String businessName;

  /// Business location this permission set applies to.
  final String businessLocationId;

  /// Cached display-only role name.
  final String roleName;

  /// JSON-encoded list of permission codes granted to this role.
  final String permissionCodes;

  /// When this permission set was last refreshed from the server.
  final DateTime cachedAt;
  const CachedPermission({
    required this.userId,
    required this.businessId,
    required this.businessName,
    required this.businessLocationId,
    required this.roleName,
    required this.permissionCodes,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['business_id'] = Variable<String>(businessId);
    map['business_name'] = Variable<String>(businessName);
    map['business_location_id'] = Variable<String>(businessLocationId);
    map['role_name'] = Variable<String>(roleName);
    map['permission_codes'] = Variable<String>(permissionCodes);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedPermissionsCompanion toCompanion(bool nullToAbsent) {
    return CachedPermissionsCompanion(
      userId: Value(userId),
      businessId: Value(businessId),
      businessName: Value(businessName),
      businessLocationId: Value(businessLocationId),
      roleName: Value(roleName),
      permissionCodes: Value(permissionCodes),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedPermission.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPermission(
      userId: serializer.fromJson<String>(json['userId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      businessName: serializer.fromJson<String>(json['businessName']),
      businessLocationId: serializer.fromJson<String>(
        json['businessLocationId'],
      ),
      roleName: serializer.fromJson<String>(json['roleName']),
      permissionCodes: serializer.fromJson<String>(json['permissionCodes']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'businessId': serializer.toJson<String>(businessId),
      'businessName': serializer.toJson<String>(businessName),
      'businessLocationId': serializer.toJson<String>(businessLocationId),
      'roleName': serializer.toJson<String>(roleName),
      'permissionCodes': serializer.toJson<String>(permissionCodes),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedPermission copyWith({
    String? userId,
    String? businessId,
    String? businessName,
    String? businessLocationId,
    String? roleName,
    String? permissionCodes,
    DateTime? cachedAt,
  }) => CachedPermission(
    userId: userId ?? this.userId,
    businessId: businessId ?? this.businessId,
    businessName: businessName ?? this.businessName,
    businessLocationId: businessLocationId ?? this.businessLocationId,
    roleName: roleName ?? this.roleName,
    permissionCodes: permissionCodes ?? this.permissionCodes,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedPermission copyWithCompanion(CachedPermissionsCompanion data) {
    return CachedPermission(
      userId: data.userId.present ? data.userId.value : this.userId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      businessLocationId: data.businessLocationId.present
          ? data.businessLocationId.value
          : this.businessLocationId,
      roleName: data.roleName.present ? data.roleName.value : this.roleName,
      permissionCodes: data.permissionCodes.present
          ? data.permissionCodes.value
          : this.permissionCodes,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPermission(')
          ..write('userId: $userId, ')
          ..write('businessId: $businessId, ')
          ..write('businessName: $businessName, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('roleName: $roleName, ')
          ..write('permissionCodes: $permissionCodes, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    businessId,
    businessName,
    businessLocationId,
    roleName,
    permissionCodes,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPermission &&
          other.userId == this.userId &&
          other.businessId == this.businessId &&
          other.businessName == this.businessName &&
          other.businessLocationId == this.businessLocationId &&
          other.roleName == this.roleName &&
          other.permissionCodes == this.permissionCodes &&
          other.cachedAt == this.cachedAt);
}

class CachedPermissionsCompanion extends UpdateCompanion<CachedPermission> {
  final Value<String> userId;
  final Value<String> businessId;
  final Value<String> businessName;
  final Value<String> businessLocationId;
  final Value<String> roleName;
  final Value<String> permissionCodes;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedPermissionsCompanion({
    this.userId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.businessName = const Value.absent(),
    this.businessLocationId = const Value.absent(),
    this.roleName = const Value.absent(),
    this.permissionCodes = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPermissionsCompanion.insert({
    required String userId,
    required String businessId,
    required String businessName,
    required String businessLocationId,
    required String roleName,
    required String permissionCodes,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       businessId = Value(businessId),
       businessName = Value(businessName),
       businessLocationId = Value(businessLocationId),
       roleName = Value(roleName),
       permissionCodes = Value(permissionCodes),
       cachedAt = Value(cachedAt);
  static Insertable<CachedPermission> custom({
    Expression<String>? userId,
    Expression<String>? businessId,
    Expression<String>? businessName,
    Expression<String>? businessLocationId,
    Expression<String>? roleName,
    Expression<String>? permissionCodes,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (businessId != null) 'business_id': businessId,
      if (businessName != null) 'business_name': businessName,
      if (businessLocationId != null)
        'business_location_id': businessLocationId,
      if (roleName != null) 'role_name': roleName,
      if (permissionCodes != null) 'permission_codes': permissionCodes,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPermissionsCompanion copyWith({
    Value<String>? userId,
    Value<String>? businessId,
    Value<String>? businessName,
    Value<String>? businessLocationId,
    Value<String>? roleName,
    Value<String>? permissionCodes,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedPermissionsCompanion(
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      roleName: roleName ?? this.roleName,
      permissionCodes: permissionCodes ?? this.permissionCodes,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (businessLocationId.present) {
      map['business_location_id'] = Variable<String>(businessLocationId.value);
    }
    if (roleName.present) {
      map['role_name'] = Variable<String>(roleName.value);
    }
    if (permissionCodes.present) {
      map['permission_codes'] = Variable<String>(permissionCodes.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPermissionsCompanion(')
          ..write('userId: $userId, ')
          ..write('businessId: $businessId, ')
          ..write('businessName: $businessName, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('roleName: $roleName, ')
          ..write('permissionCodes: $permissionCodes, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedStockLevelsTable extends CachedStockLevels
    with TableInfo<$CachedStockLevelsTable, CachedStockLevel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStockLevelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessLocationIdMeta =
      const VerificationMeta('businessLocationId');
  @override
  late final GeneratedColumn<String> businessLocationId =
      GeneratedColumn<String>(
        'business_location_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> currentQuantity =
      GeneratedColumn<String>(
        'current_quantity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>(
        $CachedStockLevelsTable.$convertercurrentQuantity,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    businessLocationId,
    currentQuantity,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_stock_levels';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedStockLevel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('business_location_id')) {
      context.handle(
        _businessLocationIdMeta,
        businessLocationId.isAcceptableOrUnknown(
          data['business_location_id']!,
          _businessLocationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessLocationIdMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, businessLocationId};
  @override
  CachedStockLevel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStockLevel(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      businessLocationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_location_id'],
      )!,
      currentQuantity: $CachedStockLevelsTable.$convertercurrentQuantity
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}current_quantity'],
            )!,
          ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedStockLevelsTable createAlias(String alias) {
    return $CachedStockLevelsTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $convertercurrentQuantity =
      const DecimalConverter();
}

class CachedStockLevel extends DataClass
    implements Insertable<CachedStockLevel> {
  /// Item UUID from the inventory catalog.
  /// Soft-references `CachedItems.id` without an FK constraint
  /// (see `CachedItems` for rationale).
  final String itemId;

  /// Business location this stock level applies to.
  final String businessLocationId;

  /// Current on-hand quantity, as last reported by the server.
  final Decimal currentQuantity;

  /// When this stock level was last refreshed from the server.
  final DateTime cachedAt;
  const CachedStockLevel({
    required this.itemId,
    required this.businessLocationId,
    required this.currentQuantity,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['business_location_id'] = Variable<String>(businessLocationId);
    {
      map['current_quantity'] = Variable<String>(
        $CachedStockLevelsTable.$convertercurrentQuantity.toSql(
          currentQuantity,
        ),
      );
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedStockLevelsCompanion toCompanion(bool nullToAbsent) {
    return CachedStockLevelsCompanion(
      itemId: Value(itemId),
      businessLocationId: Value(businessLocationId),
      currentQuantity: Value(currentQuantity),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedStockLevel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStockLevel(
      itemId: serializer.fromJson<String>(json['itemId']),
      businessLocationId: serializer.fromJson<String>(
        json['businessLocationId'],
      ),
      currentQuantity: serializer.fromJson<Decimal>(json['currentQuantity']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'businessLocationId': serializer.toJson<String>(businessLocationId),
      'currentQuantity': serializer.toJson<Decimal>(currentQuantity),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedStockLevel copyWith({
    String? itemId,
    String? businessLocationId,
    Decimal? currentQuantity,
    DateTime? cachedAt,
  }) => CachedStockLevel(
    itemId: itemId ?? this.itemId,
    businessLocationId: businessLocationId ?? this.businessLocationId,
    currentQuantity: currentQuantity ?? this.currentQuantity,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedStockLevel copyWithCompanion(CachedStockLevelsCompanion data) {
    return CachedStockLevel(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      businessLocationId: data.businessLocationId.present
          ? data.businessLocationId.value
          : this.businessLocationId,
      currentQuantity: data.currentQuantity.present
          ? data.currentQuantity.value
          : this.currentQuantity,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStockLevel(')
          ..write('itemId: $itemId, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('currentQuantity: $currentQuantity, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(itemId, businessLocationId, currentQuantity, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStockLevel &&
          other.itemId == this.itemId &&
          other.businessLocationId == this.businessLocationId &&
          other.currentQuantity == this.currentQuantity &&
          other.cachedAt == this.cachedAt);
}

class CachedStockLevelsCompanion extends UpdateCompanion<CachedStockLevel> {
  final Value<String> itemId;
  final Value<String> businessLocationId;
  final Value<Decimal> currentQuantity;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedStockLevelsCompanion({
    this.itemId = const Value.absent(),
    this.businessLocationId = const Value.absent(),
    this.currentQuantity = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedStockLevelsCompanion.insert({
    required String itemId,
    required String businessLocationId,
    required Decimal currentQuantity,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       businessLocationId = Value(businessLocationId),
       currentQuantity = Value(currentQuantity),
       cachedAt = Value(cachedAt);
  static Insertable<CachedStockLevel> custom({
    Expression<String>? itemId,
    Expression<String>? businessLocationId,
    Expression<String>? currentQuantity,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (businessLocationId != null)
        'business_location_id': businessLocationId,
      if (currentQuantity != null) 'current_quantity': currentQuantity,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedStockLevelsCompanion copyWith({
    Value<String>? itemId,
    Value<String>? businessLocationId,
    Value<Decimal>? currentQuantity,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedStockLevelsCompanion(
      itemId: itemId ?? this.itemId,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (businessLocationId.present) {
      map['business_location_id'] = Variable<String>(businessLocationId.value);
    }
    if (currentQuantity.present) {
      map['current_quantity'] = Variable<String>(
        $CachedStockLevelsTable.$convertercurrentQuantity.toSql(
          currentQuantity.value,
        ),
      );
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStockLevelsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('currentQuantity: $currentQuantity, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingVoidsRefundsTable extends PendingVoidsRefunds
    with TableInfo<$PendingVoidsRefundsTable, PendingVoidsRefund> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingVoidsRefundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientActionIdMeta = const VerificationMeta(
    'clientActionId',
  );
  @override
  late final GeneratedColumn<String> clientActionId = GeneratedColumn<String>(
    'client_action_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pending_sales (client_sale_id)',
    ),
  );
  static const VerificationMeta _newStatusMeta = const VerificationMeta(
    'newStatus',
  );
  @override
  late final GeneratedColumn<String> newStatus = GeneratedColumn<String>(
    'new_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorUserIdMeta = const VerificationMeta(
    'actorUserId',
  );
  @override
  late final GeneratedColumn<String> actorUserId = GeneratedColumn<String>(
    'actor_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncAttemptCountMeta = const VerificationMeta(
    'syncAttemptCount',
  );
  @override
  late final GeneratedColumn<int> syncAttemptCount = GeneratedColumn<int>(
    'sync_attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientActionId,
    saleId,
    newStatus,
    reason,
    actorUserId,
    occurredAt,
    syncStatus,
    syncError,
    syncAttemptCount,
    lastAttemptAt,
    syncedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_voids_refunds';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingVoidsRefund> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_action_id')) {
      context.handle(
        _clientActionIdMeta,
        clientActionId.isAcceptableOrUnknown(
          data['client_action_id']!,
          _clientActionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientActionIdMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('new_status')) {
      context.handle(
        _newStatusMeta,
        newStatus.isAcceptableOrUnknown(data['new_status']!, _newStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_newStatusMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('actor_user_id')) {
      context.handle(
        _actorUserIdMeta,
        actorUserId.isAcceptableOrUnknown(
          data['actor_user_id']!,
          _actorUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actorUserIdMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('sync_attempt_count')) {
      context.handle(
        _syncAttemptCountMeta,
        syncAttemptCount.isAcceptableOrUnknown(
          data['sync_attempt_count']!,
          _syncAttemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingVoidsRefund map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingVoidsRefund(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientActionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_action_id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      newStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_status'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      actorUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_user_id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      syncAttemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempt_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingVoidsRefundsTable createAlias(String alias) {
    return $PendingVoidsRefundsTable(attachedDatabase, alias);
  }
}

class PendingVoidsRefund extends DataClass
    implements Insertable<PendingVoidsRefund> {
  /// Local row ID (autoincrement).
  final int id;

  /// Client-side idempotency key (UUID v4, unique).
  final String clientActionId;

  /// The already-synced sale this action applies to.
  final String saleId;

  /// Requested new status: `voided` or `refunded`.
  final String newStatus;

  /// Reason for the void/refund.
  final String reason;

  /// Staff member who performed the action.
  /// Soft-references `LocalUserProfiles.id` without an FK constraint: a
  /// profile that is later remotely revoked and deleted should not block
  /// or cascade-delete a historical void/refund record.
  final String actorUserId;

  /// When the void/refund occurred (device time, UTC).
  final DateTime occurredAt;

  /// Local sync state: `pending`, `syncing`, `failed`, `synced`.
  final String syncStatus;

  /// Error message from the last sync attempt, if any.
  final String? syncError;

  /// Number of times this action has been attempted.
  final int syncAttemptCount;

  /// Timestamp of the last sync attempt.
  final DateTime? lastAttemptAt;

  /// When the action was successfully synced to the backend.
  final DateTime? syncedAt;

  /// Local row creation timestamp.
  final DateTime createdAt;
  const PendingVoidsRefund({
    required this.id,
    required this.clientActionId,
    required this.saleId,
    required this.newStatus,
    required this.reason,
    required this.actorUserId,
    required this.occurredAt,
    required this.syncStatus,
    this.syncError,
    required this.syncAttemptCount,
    this.lastAttemptAt,
    this.syncedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_action_id'] = Variable<String>(clientActionId);
    map['sale_id'] = Variable<String>(saleId);
    map['new_status'] = Variable<String>(newStatus);
    map['reason'] = Variable<String>(reason);
    map['actor_user_id'] = Variable<String>(actorUserId);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['sync_attempt_count'] = Variable<int>(syncAttemptCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingVoidsRefundsCompanion toCompanion(bool nullToAbsent) {
    return PendingVoidsRefundsCompanion(
      id: Value(id),
      clientActionId: Value(clientActionId),
      saleId: Value(saleId),
      newStatus: Value(newStatus),
      reason: Value(reason),
      actorUserId: Value(actorUserId),
      occurredAt: Value(occurredAt),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      syncAttemptCount: Value(syncAttemptCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      createdAt: Value(createdAt),
    );
  }

  factory PendingVoidsRefund.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingVoidsRefund(
      id: serializer.fromJson<int>(json['id']),
      clientActionId: serializer.fromJson<String>(json['clientActionId']),
      saleId: serializer.fromJson<String>(json['saleId']),
      newStatus: serializer.fromJson<String>(json['newStatus']),
      reason: serializer.fromJson<String>(json['reason']),
      actorUserId: serializer.fromJson<String>(json['actorUserId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      syncAttemptCount: serializer.fromJson<int>(json['syncAttemptCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientActionId': serializer.toJson<String>(clientActionId),
      'saleId': serializer.toJson<String>(saleId),
      'newStatus': serializer.toJson<String>(newStatus),
      'reason': serializer.toJson<String>(reason),
      'actorUserId': serializer.toJson<String>(actorUserId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'syncAttemptCount': serializer.toJson<int>(syncAttemptCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingVoidsRefund copyWith({
    int? id,
    String? clientActionId,
    String? saleId,
    String? newStatus,
    String? reason,
    String? actorUserId,
    DateTime? occurredAt,
    String? syncStatus,
    Value<String?> syncError = const Value.absent(),
    int? syncAttemptCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? createdAt,
  }) => PendingVoidsRefund(
    id: id ?? this.id,
    clientActionId: clientActionId ?? this.clientActionId,
    saleId: saleId ?? this.saleId,
    newStatus: newStatus ?? this.newStatus,
    reason: reason ?? this.reason,
    actorUserId: actorUserId ?? this.actorUserId,
    occurredAt: occurredAt ?? this.occurredAt,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingVoidsRefund copyWithCompanion(PendingVoidsRefundsCompanion data) {
    return PendingVoidsRefund(
      id: data.id.present ? data.id.value : this.id,
      clientActionId: data.clientActionId.present
          ? data.clientActionId.value
          : this.clientActionId,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      newStatus: data.newStatus.present ? data.newStatus.value : this.newStatus,
      reason: data.reason.present ? data.reason.value : this.reason,
      actorUserId: data.actorUserId.present
          ? data.actorUserId.value
          : this.actorUserId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      syncAttemptCount: data.syncAttemptCount.present
          ? data.syncAttemptCount.value
          : this.syncAttemptCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingVoidsRefund(')
          ..write('id: $id, ')
          ..write('clientActionId: $clientActionId, ')
          ..write('saleId: $saleId, ')
          ..write('newStatus: $newStatus, ')
          ..write('reason: $reason, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('syncAttemptCount: $syncAttemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientActionId,
    saleId,
    newStatus,
    reason,
    actorUserId,
    occurredAt,
    syncStatus,
    syncError,
    syncAttemptCount,
    lastAttemptAt,
    syncedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingVoidsRefund &&
          other.id == this.id &&
          other.clientActionId == this.clientActionId &&
          other.saleId == this.saleId &&
          other.newStatus == this.newStatus &&
          other.reason == this.reason &&
          other.actorUserId == this.actorUserId &&
          other.occurredAt == this.occurredAt &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.syncAttemptCount == this.syncAttemptCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.syncedAt == this.syncedAt &&
          other.createdAt == this.createdAt);
}

class PendingVoidsRefundsCompanion extends UpdateCompanion<PendingVoidsRefund> {
  final Value<int> id;
  final Value<String> clientActionId;
  final Value<String> saleId;
  final Value<String> newStatus;
  final Value<String> reason;
  final Value<String> actorUserId;
  final Value<DateTime> occurredAt;
  final Value<String> syncStatus;
  final Value<String?> syncError;
  final Value<int> syncAttemptCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> createdAt;
  const PendingVoidsRefundsCompanion({
    this.id = const Value.absent(),
    this.clientActionId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.newStatus = const Value.absent(),
    this.reason = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.syncAttemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingVoidsRefundsCompanion.insert({
    this.id = const Value.absent(),
    required String clientActionId,
    required String saleId,
    required String newStatus,
    required String reason,
    required String actorUserId,
    required DateTime occurredAt,
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.syncAttemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    required DateTime createdAt,
  }) : clientActionId = Value(clientActionId),
       saleId = Value(saleId),
       newStatus = Value(newStatus),
       reason = Value(reason),
       actorUserId = Value(actorUserId),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt);
  static Insertable<PendingVoidsRefund> custom({
    Expression<int>? id,
    Expression<String>? clientActionId,
    Expression<String>? saleId,
    Expression<String>? newStatus,
    Expression<String>? reason,
    Expression<String>? actorUserId,
    Expression<DateTime>? occurredAt,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? syncAttemptCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientActionId != null) 'client_action_id': clientActionId,
      if (saleId != null) 'sale_id': saleId,
      if (newStatus != null) 'new_status': newStatus,
      if (reason != null) 'reason': reason,
      if (actorUserId != null) 'actor_user_id': actorUserId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (syncAttemptCount != null) 'sync_attempt_count': syncAttemptCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingVoidsRefundsCompanion copyWith({
    Value<int>? id,
    Value<String>? clientActionId,
    Value<String>? saleId,
    Value<String>? newStatus,
    Value<String>? reason,
    Value<String>? actorUserId,
    Value<DateTime>? occurredAt,
    Value<String>? syncStatus,
    Value<String?>? syncError,
    Value<int>? syncAttemptCount,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? createdAt,
  }) {
    return PendingVoidsRefundsCompanion(
      id: id ?? this.id,
      clientActionId: clientActionId ?? this.clientActionId,
      saleId: saleId ?? this.saleId,
      newStatus: newStatus ?? this.newStatus,
      reason: reason ?? this.reason,
      actorUserId: actorUserId ?? this.actorUserId,
      occurredAt: occurredAt ?? this.occurredAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientActionId.present) {
      map['client_action_id'] = Variable<String>(clientActionId.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (newStatus.present) {
      map['new_status'] = Variable<String>(newStatus.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (actorUserId.present) {
      map['actor_user_id'] = Variable<String>(actorUserId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (syncAttemptCount.present) {
      map['sync_attempt_count'] = Variable<int>(syncAttemptCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingVoidsRefundsCompanion(')
          ..write('id: $id, ')
          ..write('clientActionId: $clientActionId, ')
          ..write('saleId: $saleId, ')
          ..write('newStatus: $newStatus, ')
          ..write('reason: $reason, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('syncAttemptCount: $syncAttemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ExpenseEntriesTable extends ExpenseEntries
    with TableInfo<$ExpenseEntriesTable, ExpenseEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessLocationIdMeta =
      const VerificationMeta('businessLocationId');
  @override
  late final GeneratedColumn<String> businessLocationId =
      GeneratedColumn<String>(
        'business_location_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> amount =
      GeneratedColumn<String>(
        'amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($ExpenseEntriesTable.$converteramount);
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorUserIdMeta = const VerificationMeta(
    'actorUserId',
  );
  @override
  late final GeneratedColumn<String> actorUserId = GeneratedColumn<String>(
    'actor_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncAttemptCountMeta = const VerificationMeta(
    'syncAttemptCount',
  );
  @override
  late final GeneratedColumn<int> syncAttemptCount = GeneratedColumn<int>(
    'sync_attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expenseId,
    businessId,
    businessLocationId,
    category,
    amount,
    description,
    occurredAt,
    actorUserId,
    syncStatus,
    syncError,
    syncAttemptCount,
    lastAttemptAt,
    syncedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('business_location_id')) {
      context.handle(
        _businessLocationIdMeta,
        businessLocationId.isAcceptableOrUnknown(
          data['business_location_id']!,
          _businessLocationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessLocationIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('actor_user_id')) {
      context.handle(
        _actorUserIdMeta,
        actorUserId.isAcceptableOrUnknown(
          data['actor_user_id']!,
          _actorUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actorUserIdMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('sync_attempt_count')) {
      context.handle(
        _syncAttemptCountMeta,
        syncAttemptCount.isAcceptableOrUnknown(
          data['sync_attempt_count']!,
          _syncAttemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      businessLocationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_location_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amount: $ExpenseEntriesTable.$converteramount.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount'],
        )!,
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      actorUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_user_id'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      syncAttemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempt_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExpenseEntriesTable createAlias(String alias) {
    return $ExpenseEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converteramount =
      const DecimalConverter();
}

class ExpenseEntry extends DataClass implements Insertable<ExpenseEntry> {
  /// Local row ID (autoincrement).
  final int id;

  /// Client-side idempotency key (UUID v4, unique).
  final String expenseId;

  /// Business this expense belongs to.
  final String businessId;

  /// Business location this expense belongs to.
  final String businessLocationId;

  /// Expense category. Controlled list, not free text, so reporting
  /// stays meaningful: rent|utilities|salaries|repairs|supplies|other.
  final String category;

  /// Expense amount.
  final Decimal amount;

  /// Optional free-text description.
  final String? description;

  /// When the expense occurred (device time, UTC).
  final DateTime occurredAt;

  /// Staff member who recorded the expense.
  /// Soft-references `LocalUserProfiles.id` without an FK constraint: a
  /// profile that is later remotely revoked and deleted should not block
  /// or cascade-delete a historical expense record.
  final String actorUserId;

  /// Local sync state: `pending`, `syncing`, `failed`, `synced`.
  final String syncStatus;

  /// Error message from the last sync attempt, if any.
  final String? syncError;

  /// Number of times this entry has been attempted.
  final int syncAttemptCount;

  /// Timestamp of the last sync attempt.
  final DateTime? lastAttemptAt;

  /// When the entry was successfully synced to the backend.
  final DateTime? syncedAt;

  /// Local row creation timestamp.
  final DateTime createdAt;
  const ExpenseEntry({
    required this.id,
    required this.expenseId,
    required this.businessId,
    required this.businessLocationId,
    required this.category,
    required this.amount,
    this.description,
    required this.occurredAt,
    required this.actorUserId,
    required this.syncStatus,
    this.syncError,
    required this.syncAttemptCount,
    this.lastAttemptAt,
    this.syncedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['expense_id'] = Variable<String>(expenseId);
    map['business_id'] = Variable<String>(businessId);
    map['business_location_id'] = Variable<String>(businessLocationId);
    map['category'] = Variable<String>(category);
    {
      map['amount'] = Variable<String>(
        $ExpenseEntriesTable.$converteramount.toSql(amount),
      );
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['actor_user_id'] = Variable<String>(actorUserId);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['sync_attempt_count'] = Variable<int>(syncAttemptCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExpenseEntriesCompanion toCompanion(bool nullToAbsent) {
    return ExpenseEntriesCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      businessId: Value(businessId),
      businessLocationId: Value(businessLocationId),
      category: Value(category),
      amount: Value(amount),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      occurredAt: Value(occurredAt),
      actorUserId: Value(actorUserId),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      syncAttemptCount: Value(syncAttemptCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      createdAt: Value(createdAt),
    );
  }

  factory ExpenseEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseEntry(
      id: serializer.fromJson<int>(json['id']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      businessLocationId: serializer.fromJson<String>(
        json['businessLocationId'],
      ),
      category: serializer.fromJson<String>(json['category']),
      amount: serializer.fromJson<Decimal>(json['amount']),
      description: serializer.fromJson<String?>(json['description']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      actorUserId: serializer.fromJson<String>(json['actorUserId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      syncAttemptCount: serializer.fromJson<int>(json['syncAttemptCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'expenseId': serializer.toJson<String>(expenseId),
      'businessId': serializer.toJson<String>(businessId),
      'businessLocationId': serializer.toJson<String>(businessLocationId),
      'category': serializer.toJson<String>(category),
      'amount': serializer.toJson<Decimal>(amount),
      'description': serializer.toJson<String?>(description),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'actorUserId': serializer.toJson<String>(actorUserId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'syncAttemptCount': serializer.toJson<int>(syncAttemptCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExpenseEntry copyWith({
    int? id,
    String? expenseId,
    String? businessId,
    String? businessLocationId,
    String? category,
    Decimal? amount,
    Value<String?> description = const Value.absent(),
    DateTime? occurredAt,
    String? actorUserId,
    String? syncStatus,
    Value<String?> syncError = const Value.absent(),
    int? syncAttemptCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? createdAt,
  }) => ExpenseEntry(
    id: id ?? this.id,
    expenseId: expenseId ?? this.expenseId,
    businessId: businessId ?? this.businessId,
    businessLocationId: businessLocationId ?? this.businessLocationId,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    description: description.present ? description.value : this.description,
    occurredAt: occurredAt ?? this.occurredAt,
    actorUserId: actorUserId ?? this.actorUserId,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  ExpenseEntry copyWithCompanion(ExpenseEntriesCompanion data) {
    return ExpenseEntry(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      businessLocationId: data.businessLocationId.present
          ? data.businessLocationId.value
          : this.businessLocationId,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      description: data.description.present
          ? data.description.value
          : this.description,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      actorUserId: data.actorUserId.present
          ? data.actorUserId.value
          : this.actorUserId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      syncAttemptCount: data.syncAttemptCount.present
          ? data.syncAttemptCount.value
          : this.syncAttemptCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseEntry(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('businessId: $businessId, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('syncAttemptCount: $syncAttemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    expenseId,
    businessId,
    businessLocationId,
    category,
    amount,
    description,
    occurredAt,
    actorUserId,
    syncStatus,
    syncError,
    syncAttemptCount,
    lastAttemptAt,
    syncedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseEntry &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.businessId == this.businessId &&
          other.businessLocationId == this.businessLocationId &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.description == this.description &&
          other.occurredAt == this.occurredAt &&
          other.actorUserId == this.actorUserId &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.syncAttemptCount == this.syncAttemptCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.syncedAt == this.syncedAt &&
          other.createdAt == this.createdAt);
}

class ExpenseEntriesCompanion extends UpdateCompanion<ExpenseEntry> {
  final Value<int> id;
  final Value<String> expenseId;
  final Value<String> businessId;
  final Value<String> businessLocationId;
  final Value<String> category;
  final Value<Decimal> amount;
  final Value<String?> description;
  final Value<DateTime> occurredAt;
  final Value<String> actorUserId;
  final Value<String> syncStatus;
  final Value<String?> syncError;
  final Value<int> syncAttemptCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> createdAt;
  const ExpenseEntriesCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.businessLocationId = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.description = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.syncAttemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExpenseEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String expenseId,
    required String businessId,
    required String businessLocationId,
    required String category,
    required Decimal amount,
    this.description = const Value.absent(),
    required DateTime occurredAt,
    required String actorUserId,
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.syncAttemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    required DateTime createdAt,
  }) : expenseId = Value(expenseId),
       businessId = Value(businessId),
       businessLocationId = Value(businessLocationId),
       category = Value(category),
       amount = Value(amount),
       occurredAt = Value(occurredAt),
       actorUserId = Value(actorUserId),
       createdAt = Value(createdAt);
  static Insertable<ExpenseEntry> custom({
    Expression<int>? id,
    Expression<String>? expenseId,
    Expression<String>? businessId,
    Expression<String>? businessLocationId,
    Expression<String>? category,
    Expression<String>? amount,
    Expression<String>? description,
    Expression<DateTime>? occurredAt,
    Expression<String>? actorUserId,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? syncAttemptCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expense_id': expenseId,
      if (businessId != null) 'business_id': businessId,
      if (businessLocationId != null)
        'business_location_id': businessLocationId,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (actorUserId != null) 'actor_user_id': actorUserId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (syncAttemptCount != null) 'sync_attempt_count': syncAttemptCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExpenseEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? expenseId,
    Value<String>? businessId,
    Value<String>? businessLocationId,
    Value<String>? category,
    Value<Decimal>? amount,
    Value<String?>? description,
    Value<DateTime>? occurredAt,
    Value<String>? actorUserId,
    Value<String>? syncStatus,
    Value<String?>? syncError,
    Value<int>? syncAttemptCount,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? createdAt,
  }) {
    return ExpenseEntriesCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      businessId: businessId ?? this.businessId,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      actorUserId: actorUserId ?? this.actorUserId,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (businessLocationId.present) {
      map['business_location_id'] = Variable<String>(businessLocationId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(
        $ExpenseEntriesTable.$converteramount.toSql(amount.value),
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (actorUserId.present) {
      map['actor_user_id'] = Variable<String>(actorUserId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (syncAttemptCount.present) {
      map['sync_attempt_count'] = Variable<int>(syncAttemptCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseEntriesCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('businessId: $businessId, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('syncAttemptCount: $syncAttemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OtherIncomeEntriesTable extends OtherIncomeEntries
    with TableInfo<$OtherIncomeEntriesTable, OtherIncomeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OtherIncomeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _incomeIdMeta = const VerificationMeta(
    'incomeId',
  );
  @override
  late final GeneratedColumn<String> incomeId = GeneratedColumn<String>(
    'income_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessLocationIdMeta =
      const VerificationMeta('businessLocationId');
  @override
  late final GeneratedColumn<String> businessLocationId =
      GeneratedColumn<String>(
        'business_location_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> amount =
      GeneratedColumn<String>(
        'amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($OtherIncomeEntriesTable.$converteramount);
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorUserIdMeta = const VerificationMeta(
    'actorUserId',
  );
  @override
  late final GeneratedColumn<String> actorUserId = GeneratedColumn<String>(
    'actor_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncAttemptCountMeta = const VerificationMeta(
    'syncAttemptCount',
  );
  @override
  late final GeneratedColumn<int> syncAttemptCount = GeneratedColumn<int>(
    'sync_attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    incomeId,
    businessId,
    businessLocationId,
    category,
    amount,
    description,
    occurredAt,
    actorUserId,
    syncStatus,
    syncError,
    syncAttemptCount,
    lastAttemptAt,
    syncedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'other_income_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OtherIncomeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('income_id')) {
      context.handle(
        _incomeIdMeta,
        incomeId.isAcceptableOrUnknown(data['income_id']!, _incomeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_incomeIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('business_location_id')) {
      context.handle(
        _businessLocationIdMeta,
        businessLocationId.isAcceptableOrUnknown(
          data['business_location_id']!,
          _businessLocationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessLocationIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('actor_user_id')) {
      context.handle(
        _actorUserIdMeta,
        actorUserId.isAcceptableOrUnknown(
          data['actor_user_id']!,
          _actorUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actorUserIdMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('sync_attempt_count')) {
      context.handle(
        _syncAttemptCountMeta,
        syncAttemptCount.isAcceptableOrUnknown(
          data['sync_attempt_count']!,
          _syncAttemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OtherIncomeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OtherIncomeEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      incomeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}income_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      businessLocationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_location_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amount: $OtherIncomeEntriesTable.$converteramount.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}amount'],
        )!,
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      actorUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_user_id'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      syncAttemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempt_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OtherIncomeEntriesTable createAlias(String alias) {
    return $OtherIncomeEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converteramount =
      const DecimalConverter();
}

class OtherIncomeEntry extends DataClass
    implements Insertable<OtherIncomeEntry> {
  /// Local row ID (autoincrement).
  final int id;

  /// Client-side idempotency key (UUID v4, unique).
  final String incomeId;

  /// Business this income belongs to.
  final String businessId;

  /// Business location this income belongs to.
  final String businessLocationId;

  /// Income category. Controlled list, not free text, same reasoning as
  /// `ExpenseEntries.category`: equipment_rental|catering_deposit|other.
  final String category;

  /// Income amount.
  final Decimal amount;

  /// Optional free-text description.
  final String? description;

  /// When the income occurred (device time, UTC).
  final DateTime occurredAt;

  /// Staff member who recorded the income.
  /// Soft-references `LocalUserProfiles.id` without an FK constraint, same
  /// rationale as `ExpenseEntries.actorUserId`.
  final String actorUserId;

  /// Local sync state: `pending`, `syncing`, `failed`, `synced`.
  final String syncStatus;

  /// Error message from the last sync attempt, if any.
  final String? syncError;

  /// Number of times this entry has been attempted.
  final int syncAttemptCount;

  /// Timestamp of the last sync attempt.
  final DateTime? lastAttemptAt;

  /// When the entry was successfully synced to the backend.
  final DateTime? syncedAt;

  /// Local row creation timestamp.
  final DateTime createdAt;
  const OtherIncomeEntry({
    required this.id,
    required this.incomeId,
    required this.businessId,
    required this.businessLocationId,
    required this.category,
    required this.amount,
    this.description,
    required this.occurredAt,
    required this.actorUserId,
    required this.syncStatus,
    this.syncError,
    required this.syncAttemptCount,
    this.lastAttemptAt,
    this.syncedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['income_id'] = Variable<String>(incomeId);
    map['business_id'] = Variable<String>(businessId);
    map['business_location_id'] = Variable<String>(businessLocationId);
    map['category'] = Variable<String>(category);
    {
      map['amount'] = Variable<String>(
        $OtherIncomeEntriesTable.$converteramount.toSql(amount),
      );
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['actor_user_id'] = Variable<String>(actorUserId);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['sync_attempt_count'] = Variable<int>(syncAttemptCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OtherIncomeEntriesCompanion toCompanion(bool nullToAbsent) {
    return OtherIncomeEntriesCompanion(
      id: Value(id),
      incomeId: Value(incomeId),
      businessId: Value(businessId),
      businessLocationId: Value(businessLocationId),
      category: Value(category),
      amount: Value(amount),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      occurredAt: Value(occurredAt),
      actorUserId: Value(actorUserId),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      syncAttemptCount: Value(syncAttemptCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      createdAt: Value(createdAt),
    );
  }

  factory OtherIncomeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OtherIncomeEntry(
      id: serializer.fromJson<int>(json['id']),
      incomeId: serializer.fromJson<String>(json['incomeId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      businessLocationId: serializer.fromJson<String>(
        json['businessLocationId'],
      ),
      category: serializer.fromJson<String>(json['category']),
      amount: serializer.fromJson<Decimal>(json['amount']),
      description: serializer.fromJson<String?>(json['description']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      actorUserId: serializer.fromJson<String>(json['actorUserId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      syncAttemptCount: serializer.fromJson<int>(json['syncAttemptCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'incomeId': serializer.toJson<String>(incomeId),
      'businessId': serializer.toJson<String>(businessId),
      'businessLocationId': serializer.toJson<String>(businessLocationId),
      'category': serializer.toJson<String>(category),
      'amount': serializer.toJson<Decimal>(amount),
      'description': serializer.toJson<String?>(description),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'actorUserId': serializer.toJson<String>(actorUserId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'syncAttemptCount': serializer.toJson<int>(syncAttemptCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OtherIncomeEntry copyWith({
    int? id,
    String? incomeId,
    String? businessId,
    String? businessLocationId,
    String? category,
    Decimal? amount,
    Value<String?> description = const Value.absent(),
    DateTime? occurredAt,
    String? actorUserId,
    String? syncStatus,
    Value<String?> syncError = const Value.absent(),
    int? syncAttemptCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? createdAt,
  }) => OtherIncomeEntry(
    id: id ?? this.id,
    incomeId: incomeId ?? this.incomeId,
    businessId: businessId ?? this.businessId,
    businessLocationId: businessLocationId ?? this.businessLocationId,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    description: description.present ? description.value : this.description,
    occurredAt: occurredAt ?? this.occurredAt,
    actorUserId: actorUserId ?? this.actorUserId,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  OtherIncomeEntry copyWithCompanion(OtherIncomeEntriesCompanion data) {
    return OtherIncomeEntry(
      id: data.id.present ? data.id.value : this.id,
      incomeId: data.incomeId.present ? data.incomeId.value : this.incomeId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      businessLocationId: data.businessLocationId.present
          ? data.businessLocationId.value
          : this.businessLocationId,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      description: data.description.present
          ? data.description.value
          : this.description,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      actorUserId: data.actorUserId.present
          ? data.actorUserId.value
          : this.actorUserId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      syncAttemptCount: data.syncAttemptCount.present
          ? data.syncAttemptCount.value
          : this.syncAttemptCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OtherIncomeEntry(')
          ..write('id: $id, ')
          ..write('incomeId: $incomeId, ')
          ..write('businessId: $businessId, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('syncAttemptCount: $syncAttemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    incomeId,
    businessId,
    businessLocationId,
    category,
    amount,
    description,
    occurredAt,
    actorUserId,
    syncStatus,
    syncError,
    syncAttemptCount,
    lastAttemptAt,
    syncedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OtherIncomeEntry &&
          other.id == this.id &&
          other.incomeId == this.incomeId &&
          other.businessId == this.businessId &&
          other.businessLocationId == this.businessLocationId &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.description == this.description &&
          other.occurredAt == this.occurredAt &&
          other.actorUserId == this.actorUserId &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.syncAttemptCount == this.syncAttemptCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.syncedAt == this.syncedAt &&
          other.createdAt == this.createdAt);
}

class OtherIncomeEntriesCompanion extends UpdateCompanion<OtherIncomeEntry> {
  final Value<int> id;
  final Value<String> incomeId;
  final Value<String> businessId;
  final Value<String> businessLocationId;
  final Value<String> category;
  final Value<Decimal> amount;
  final Value<String?> description;
  final Value<DateTime> occurredAt;
  final Value<String> actorUserId;
  final Value<String> syncStatus;
  final Value<String?> syncError;
  final Value<int> syncAttemptCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> createdAt;
  const OtherIncomeEntriesCompanion({
    this.id = const Value.absent(),
    this.incomeId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.businessLocationId = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.description = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.syncAttemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OtherIncomeEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String incomeId,
    required String businessId,
    required String businessLocationId,
    required String category,
    required Decimal amount,
    this.description = const Value.absent(),
    required DateTime occurredAt,
    required String actorUserId,
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.syncAttemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    required DateTime createdAt,
  }) : incomeId = Value(incomeId),
       businessId = Value(businessId),
       businessLocationId = Value(businessLocationId),
       category = Value(category),
       amount = Value(amount),
       occurredAt = Value(occurredAt),
       actorUserId = Value(actorUserId),
       createdAt = Value(createdAt);
  static Insertable<OtherIncomeEntry> custom({
    Expression<int>? id,
    Expression<String>? incomeId,
    Expression<String>? businessId,
    Expression<String>? businessLocationId,
    Expression<String>? category,
    Expression<String>? amount,
    Expression<String>? description,
    Expression<DateTime>? occurredAt,
    Expression<String>? actorUserId,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? syncAttemptCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (incomeId != null) 'income_id': incomeId,
      if (businessId != null) 'business_id': businessId,
      if (businessLocationId != null)
        'business_location_id': businessLocationId,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (actorUserId != null) 'actor_user_id': actorUserId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (syncAttemptCount != null) 'sync_attempt_count': syncAttemptCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OtherIncomeEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? incomeId,
    Value<String>? businessId,
    Value<String>? businessLocationId,
    Value<String>? category,
    Value<Decimal>? amount,
    Value<String?>? description,
    Value<DateTime>? occurredAt,
    Value<String>? actorUserId,
    Value<String>? syncStatus,
    Value<String?>? syncError,
    Value<int>? syncAttemptCount,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? createdAt,
  }) {
    return OtherIncomeEntriesCompanion(
      id: id ?? this.id,
      incomeId: incomeId ?? this.incomeId,
      businessId: businessId ?? this.businessId,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      actorUserId: actorUserId ?? this.actorUserId,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (incomeId.present) {
      map['income_id'] = Variable<String>(incomeId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (businessLocationId.present) {
      map['business_location_id'] = Variable<String>(businessLocationId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(
        $OtherIncomeEntriesTable.$converteramount.toSql(amount.value),
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (actorUserId.present) {
      map['actor_user_id'] = Variable<String>(actorUserId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (syncAttemptCount.present) {
      map['sync_attempt_count'] = Variable<int>(syncAttemptCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OtherIncomeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('incomeId: $incomeId, ')
          ..write('businessId: $businessId, ')
          ..write('businessLocationId: $businessLocationId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('syncAttemptCount: $syncAttemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalAuditLogTable extends LocalAuditLog
    with TableInfo<$LocalAuditLogTable, LocalAuditLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actorUserIdMeta = const VerificationMeta(
    'actorUserId',
  );
  @override
  late final GeneratedColumn<String> actorUserId = GeneratedColumn<String>(
    'actor_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resourceTypeMeta = const VerificationMeta(
    'resourceType',
  );
  @override
  late final GeneratedColumn<String> resourceType = GeneratedColumn<String>(
    'resource_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailsJsonMeta = const VerificationMeta(
    'detailsJson',
  );
  @override
  late final GeneratedColumn<String> detailsJson = GeneratedColumn<String>(
    'details_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncAttemptCountMeta = const VerificationMeta(
    'syncAttemptCount',
  );
  @override
  late final GeneratedColumn<int> syncAttemptCount = GeneratedColumn<int>(
    'sync_attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actorUserId,
    action,
    resourceType,
    resourceId,
    detailsJson,
    occurredAt,
    syncStatus,
    syncError,
    syncAttemptCount,
    lastAttemptAt,
    syncedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAuditLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('actor_user_id')) {
      context.handle(
        _actorUserIdMeta,
        actorUserId.isAcceptableOrUnknown(
          data['actor_user_id']!,
          _actorUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actorUserIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('resource_type')) {
      context.handle(
        _resourceTypeMeta,
        resourceType.isAcceptableOrUnknown(
          data['resource_type']!,
          _resourceTypeMeta,
        ),
      );
    }
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    }
    if (data.containsKey('details_json')) {
      context.handle(
        _detailsJsonMeta,
        detailsJson.isAcceptableOrUnknown(
          data['details_json']!,
          _detailsJsonMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('sync_attempt_count')) {
      context.handle(
        _syncAttemptCountMeta,
        syncAttemptCount.isAcceptableOrUnknown(
          data['sync_attempt_count']!,
          _syncAttemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAuditLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAuditLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      actorUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_user_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      resourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_type'],
      ),
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      ),
      detailsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details_json'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      syncAttemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempt_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalAuditLogTable createAlias(String alias) {
    return $LocalAuditLogTable(attachedDatabase, alias);
  }
}

class LocalAuditLogData extends DataClass
    implements Insertable<LocalAuditLogData> {
  /// Local row ID (autoincrement).
  final int id;

  /// Staff member (or system) responsible for the action.
  /// Soft-references `LocalUserProfiles.id` without an FK constraint: a
  /// profile that is later remotely revoked and deleted should not block
  /// or cascade-delete a historical audit entry.
  final String actorUserId;

  /// Event identifier, e.g. `pin.unlock_failed`, `sale.completed`,
  /// `expense.recorded`, `profile.remotely_revoked`.
  final String action;

  /// Optional type of the resource this event concerns.
  final String? resourceType;

  /// Optional ID of the resource this event concerns.
  final String? resourceId;

  /// Optional JSON-encoded event details.
  final String? detailsJson;

  /// When the event occurred (device time, UTC).
  final DateTime occurredAt;

  /// Local sync state: `pending`, `syncing`, `failed`, `synced`.
  final String syncStatus;

  /// Error message from the last sync attempt, if any.
  final String? syncError;

  /// Number of times this entry has been attempted.
  final int syncAttemptCount;

  /// Timestamp of the last sync attempt.
  final DateTime? lastAttemptAt;

  /// When the entry was successfully synced to the backend.
  final DateTime? syncedAt;

  /// Local row creation timestamp.
  final DateTime createdAt;
  const LocalAuditLogData({
    required this.id,
    required this.actorUserId,
    required this.action,
    this.resourceType,
    this.resourceId,
    this.detailsJson,
    required this.occurredAt,
    required this.syncStatus,
    this.syncError,
    required this.syncAttemptCount,
    this.lastAttemptAt,
    this.syncedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['actor_user_id'] = Variable<String>(actorUserId);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || resourceType != null) {
      map['resource_type'] = Variable<String>(resourceType);
    }
    if (!nullToAbsent || resourceId != null) {
      map['resource_id'] = Variable<String>(resourceId);
    }
    if (!nullToAbsent || detailsJson != null) {
      map['details_json'] = Variable<String>(detailsJson);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['sync_attempt_count'] = Variable<int>(syncAttemptCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalAuditLogCompanion toCompanion(bool nullToAbsent) {
    return LocalAuditLogCompanion(
      id: Value(id),
      actorUserId: Value(actorUserId),
      action: Value(action),
      resourceType: resourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceType),
      resourceId: resourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceId),
      detailsJson: detailsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailsJson),
      occurredAt: Value(occurredAt),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      syncAttemptCount: Value(syncAttemptCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      createdAt: Value(createdAt),
    );
  }

  factory LocalAuditLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAuditLogData(
      id: serializer.fromJson<int>(json['id']),
      actorUserId: serializer.fromJson<String>(json['actorUserId']),
      action: serializer.fromJson<String>(json['action']),
      resourceType: serializer.fromJson<String?>(json['resourceType']),
      resourceId: serializer.fromJson<String?>(json['resourceId']),
      detailsJson: serializer.fromJson<String?>(json['detailsJson']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      syncAttemptCount: serializer.fromJson<int>(json['syncAttemptCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'actorUserId': serializer.toJson<String>(actorUserId),
      'action': serializer.toJson<String>(action),
      'resourceType': serializer.toJson<String?>(resourceType),
      'resourceId': serializer.toJson<String?>(resourceId),
      'detailsJson': serializer.toJson<String?>(detailsJson),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'syncAttemptCount': serializer.toJson<int>(syncAttemptCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalAuditLogData copyWith({
    int? id,
    String? actorUserId,
    String? action,
    Value<String?> resourceType = const Value.absent(),
    Value<String?> resourceId = const Value.absent(),
    Value<String?> detailsJson = const Value.absent(),
    DateTime? occurredAt,
    String? syncStatus,
    Value<String?> syncError = const Value.absent(),
    int? syncAttemptCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? createdAt,
  }) => LocalAuditLogData(
    id: id ?? this.id,
    actorUserId: actorUserId ?? this.actorUserId,
    action: action ?? this.action,
    resourceType: resourceType.present ? resourceType.value : this.resourceType,
    resourceId: resourceId.present ? resourceId.value : this.resourceId,
    detailsJson: detailsJson.present ? detailsJson.value : this.detailsJson,
    occurredAt: occurredAt ?? this.occurredAt,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalAuditLogData copyWithCompanion(LocalAuditLogCompanion data) {
    return LocalAuditLogData(
      id: data.id.present ? data.id.value : this.id,
      actorUserId: data.actorUserId.present
          ? data.actorUserId.value
          : this.actorUserId,
      action: data.action.present ? data.action.value : this.action,
      resourceType: data.resourceType.present
          ? data.resourceType.value
          : this.resourceType,
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      detailsJson: data.detailsJson.present
          ? data.detailsJson.value
          : this.detailsJson,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      syncAttemptCount: data.syncAttemptCount.present
          ? data.syncAttemptCount.value
          : this.syncAttemptCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAuditLogData(')
          ..write('id: $id, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('action: $action, ')
          ..write('resourceType: $resourceType, ')
          ..write('resourceId: $resourceId, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('syncAttemptCount: $syncAttemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actorUserId,
    action,
    resourceType,
    resourceId,
    detailsJson,
    occurredAt,
    syncStatus,
    syncError,
    syncAttemptCount,
    lastAttemptAt,
    syncedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAuditLogData &&
          other.id == this.id &&
          other.actorUserId == this.actorUserId &&
          other.action == this.action &&
          other.resourceType == this.resourceType &&
          other.resourceId == this.resourceId &&
          other.detailsJson == this.detailsJson &&
          other.occurredAt == this.occurredAt &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.syncAttemptCount == this.syncAttemptCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.syncedAt == this.syncedAt &&
          other.createdAt == this.createdAt);
}

class LocalAuditLogCompanion extends UpdateCompanion<LocalAuditLogData> {
  final Value<int> id;
  final Value<String> actorUserId;
  final Value<String> action;
  final Value<String?> resourceType;
  final Value<String?> resourceId;
  final Value<String?> detailsJson;
  final Value<DateTime> occurredAt;
  final Value<String> syncStatus;
  final Value<String?> syncError;
  final Value<int> syncAttemptCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> createdAt;
  const LocalAuditLogCompanion({
    this.id = const Value.absent(),
    this.actorUserId = const Value.absent(),
    this.action = const Value.absent(),
    this.resourceType = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.syncAttemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalAuditLogCompanion.insert({
    this.id = const Value.absent(),
    required String actorUserId,
    required String action,
    this.resourceType = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.detailsJson = const Value.absent(),
    required DateTime occurredAt,
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.syncAttemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    required DateTime createdAt,
  }) : actorUserId = Value(actorUserId),
       action = Value(action),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt);
  static Insertable<LocalAuditLogData> custom({
    Expression<int>? id,
    Expression<String>? actorUserId,
    Expression<String>? action,
    Expression<String>? resourceType,
    Expression<String>? resourceId,
    Expression<String>? detailsJson,
    Expression<DateTime>? occurredAt,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? syncAttemptCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actorUserId != null) 'actor_user_id': actorUserId,
      if (action != null) 'action': action,
      if (resourceType != null) 'resource_type': resourceType,
      if (resourceId != null) 'resource_id': resourceId,
      if (detailsJson != null) 'details_json': detailsJson,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (syncAttemptCount != null) 'sync_attempt_count': syncAttemptCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalAuditLogCompanion copyWith({
    Value<int>? id,
    Value<String>? actorUserId,
    Value<String>? action,
    Value<String?>? resourceType,
    Value<String?>? resourceId,
    Value<String?>? detailsJson,
    Value<DateTime>? occurredAt,
    Value<String>? syncStatus,
    Value<String?>? syncError,
    Value<int>? syncAttemptCount,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? createdAt,
  }) {
    return LocalAuditLogCompanion(
      id: id ?? this.id,
      actorUserId: actorUserId ?? this.actorUserId,
      action: action ?? this.action,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      detailsJson: detailsJson ?? this.detailsJson,
      occurredAt: occurredAt ?? this.occurredAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (actorUserId.present) {
      map['actor_user_id'] = Variable<String>(actorUserId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (resourceType.present) {
      map['resource_type'] = Variable<String>(resourceType.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (detailsJson.present) {
      map['details_json'] = Variable<String>(detailsJson.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (syncAttemptCount.present) {
      map['sync_attempt_count'] = Variable<int>(syncAttemptCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAuditLogCompanion(')
          ..write('id: $id, ')
          ..write('actorUserId: $actorUserId, ')
          ..write('action: $action, ')
          ..write('resourceType: $resourceType, ')
          ..write('resourceId: $resourceId, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('syncAttemptCount: $syncAttemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalUserProfilesTable localUserProfiles =
      $LocalUserProfilesTable(this);
  late final $DeviceConfigTable deviceConfig = $DeviceConfigTable(this);
  late final $PendingSalesTable pendingSales = $PendingSalesTable(this);
  late final $PendingSaleLineItemsTable pendingSaleLineItems =
      $PendingSaleLineItemsTable(this);
  late final $CachedItemsTable cachedItems = $CachedItemsTable(this);
  late final $CachedPermissionsTable cachedPermissions =
      $CachedPermissionsTable(this);
  late final $CachedStockLevelsTable cachedStockLevels =
      $CachedStockLevelsTable(this);
  late final $PendingVoidsRefundsTable pendingVoidsRefunds =
      $PendingVoidsRefundsTable(this);
  late final $ExpenseEntriesTable expenseEntries = $ExpenseEntriesTable(this);
  late final $OtherIncomeEntriesTable otherIncomeEntries =
      $OtherIncomeEntriesTable(this);
  late final $LocalAuditLogTable localAuditLog = $LocalAuditLogTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localUserProfiles,
    deviceConfig,
    pendingSales,
    pendingSaleLineItems,
    cachedItems,
    cachedPermissions,
    cachedStockLevels,
    pendingVoidsRefunds,
    expenseEntries,
    otherIncomeEntries,
    localAuditLog,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pending_sales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pending_sale_line_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_user_profiles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cached_permissions', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LocalUserProfilesTableCreateCompanionBuilder =
    LocalUserProfilesCompanion Function({
      required String id,
      required String displayName,
      required String pinHash,
      required String pinSalt,
      Value<String?> roleLabel,
      Value<DateTime?> lastSignedInAt,
      Value<int> failedPinAttempts,
      Value<DateTime?> lockedUntil,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastRevocationCheckAt,
      Value<int> rowid,
    });
typedef $$LocalUserProfilesTableUpdateCompanionBuilder =
    LocalUserProfilesCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> pinHash,
      Value<String> pinSalt,
      Value<String?> roleLabel,
      Value<DateTime?> lastSignedInAt,
      Value<int> failedPinAttempts,
      Value<DateTime?> lockedUntil,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastRevocationCheckAt,
      Value<int> rowid,
    });

final class $$LocalUserProfilesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalUserProfilesTable,
          LocalUserProfile
        > {
  $$LocalUserProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CachedPermissionsTable, List<CachedPermission>>
  _cachedPermissionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedPermissions,
        aliasName: 'local_user_profiles__id__cached_permissions__user_id',
      );

  $$CachedPermissionsTableProcessedTableManager get cachedPermissionsRefs {
    final manager = $$CachedPermissionsTableTableManager(
      $_db,
      $_db.cachedPermissions,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedPermissionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalUserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalUserProfilesTable> {
  $$LocalUserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinSalt => $composableBuilder(
    column: $table.pinSalt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleLabel => $composableBuilder(
    column: $table.roleLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSignedInAt => $composableBuilder(
    column: $table.lastSignedInAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedPinAttempts => $composableBuilder(
    column: $table.failedPinAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRevocationCheckAt => $composableBuilder(
    column: $table.lastRevocationCheckAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cachedPermissionsRefs(
    Expression<bool> Function($$CachedPermissionsTableFilterComposer f) f,
  ) {
    final $$CachedPermissionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedPermissions,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedPermissionsTableFilterComposer(
            $db: $db,
            $table: $db.cachedPermissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalUserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalUserProfilesTable> {
  $$LocalUserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinSalt => $composableBuilder(
    column: $table.pinSalt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleLabel => $composableBuilder(
    column: $table.roleLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSignedInAt => $composableBuilder(
    column: $table.lastSignedInAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedPinAttempts => $composableBuilder(
    column: $table.failedPinAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRevocationCheckAt => $composableBuilder(
    column: $table.lastRevocationCheckAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalUserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalUserProfilesTable> {
  $$LocalUserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<String> get pinSalt =>
      $composableBuilder(column: $table.pinSalt, builder: (column) => column);

  GeneratedColumn<String> get roleLabel =>
      $composableBuilder(column: $table.roleLabel, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSignedInAt => $composableBuilder(
    column: $table.lastSignedInAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedPinAttempts => $composableBuilder(
    column: $table.failedPinAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastRevocationCheckAt => $composableBuilder(
    column: $table.lastRevocationCheckAt,
    builder: (column) => column,
  );

  Expression<T> cachedPermissionsRefs<T extends Object>(
    Expression<T> Function($$CachedPermissionsTableAnnotationComposer a) f,
  ) {
    final $$CachedPermissionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cachedPermissions,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedPermissionsTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedPermissions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LocalUserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalUserProfilesTable,
          LocalUserProfile,
          $$LocalUserProfilesTableFilterComposer,
          $$LocalUserProfilesTableOrderingComposer,
          $$LocalUserProfilesTableAnnotationComposer,
          $$LocalUserProfilesTableCreateCompanionBuilder,
          $$LocalUserProfilesTableUpdateCompanionBuilder,
          (LocalUserProfile, $$LocalUserProfilesTableReferences),
          LocalUserProfile,
          PrefetchHooks Function({bool cachedPermissionsRefs})
        > {
  $$LocalUserProfilesTableTableManager(
    _$AppDatabase db,
    $LocalUserProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalUserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalUserProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> pinHash = const Value.absent(),
                Value<String> pinSalt = const Value.absent(),
                Value<String?> roleLabel = const Value.absent(),
                Value<DateTime?> lastSignedInAt = const Value.absent(),
                Value<int> failedPinAttempts = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastRevocationCheckAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUserProfilesCompanion(
                id: id,
                displayName: displayName,
                pinHash: pinHash,
                pinSalt: pinSalt,
                roleLabel: roleLabel,
                lastSignedInAt: lastSignedInAt,
                failedPinAttempts: failedPinAttempts,
                lockedUntil: lockedUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastRevocationCheckAt: lastRevocationCheckAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String pinHash,
                required String pinSalt,
                Value<String?> roleLabel = const Value.absent(),
                Value<DateTime?> lastSignedInAt = const Value.absent(),
                Value<int> failedPinAttempts = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastRevocationCheckAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUserProfilesCompanion.insert(
                id: id,
                displayName: displayName,
                pinHash: pinHash,
                pinSalt: pinSalt,
                roleLabel: roleLabel,
                lastSignedInAt: lastSignedInAt,
                failedPinAttempts: failedPinAttempts,
                lockedUntil: lockedUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastRevocationCheckAt: lastRevocationCheckAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalUserProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cachedPermissionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cachedPermissionsRefs) db.cachedPermissions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cachedPermissionsRefs)
                    await $_getPrefetchedData<
                      LocalUserProfile,
                      $LocalUserProfilesTable,
                      CachedPermission
                    >(
                      currentTable: table,
                      referencedTable: $$LocalUserProfilesTableReferences
                          ._cachedPermissionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalUserProfilesTableReferences(
                            db,
                            table,
                            p0,
                          ).cachedPermissionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.userId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalUserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalUserProfilesTable,
      LocalUserProfile,
      $$LocalUserProfilesTableFilterComposer,
      $$LocalUserProfilesTableOrderingComposer,
      $$LocalUserProfilesTableAnnotationComposer,
      $$LocalUserProfilesTableCreateCompanionBuilder,
      $$LocalUserProfilesTableUpdateCompanionBuilder,
      (LocalUserProfile, $$LocalUserProfilesTableReferences),
      LocalUserProfile,
      PrefetchHooks Function({bool cachedPermissionsRefs})
    >;
typedef $$DeviceConfigTableCreateCompanionBuilder =
    DeviceConfigCompanion Function({
      Value<int> id,
      required String businessId,
      required String businessLocationId,
      required String businessName,
      Value<String?> deviceLabel,
      required DateTime provisionedAt,
      required DateTime updatedAt,
    });
typedef $$DeviceConfigTableUpdateCompanionBuilder =
    DeviceConfigCompanion Function({
      Value<int> id,
      Value<String> businessId,
      Value<String> businessLocationId,
      Value<String> businessName,
      Value<String?> deviceLabel,
      Value<DateTime> provisionedAt,
      Value<DateTime> updatedAt,
    });

class $$DeviceConfigTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceConfigTable> {
  $$DeviceConfigTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get provisionedAt => $composableBuilder(
    column: $table.provisionedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceConfigTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceConfigTable> {
  $$DeviceConfigTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get provisionedAt => $composableBuilder(
    column: $table.provisionedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceConfigTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceConfigTable> {
  $$DeviceConfigTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get provisionedAt => $composableBuilder(
    column: $table.provisionedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DeviceConfigTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceConfigTable,
          DeviceConfigData,
          $$DeviceConfigTableFilterComposer,
          $$DeviceConfigTableOrderingComposer,
          $$DeviceConfigTableAnnotationComposer,
          $$DeviceConfigTableCreateCompanionBuilder,
          $$DeviceConfigTableUpdateCompanionBuilder,
          (
            DeviceConfigData,
            BaseReferences<_$AppDatabase, $DeviceConfigTable, DeviceConfigData>,
          ),
          DeviceConfigData,
          PrefetchHooks Function()
        > {
  $$DeviceConfigTableTableManager(_$AppDatabase db, $DeviceConfigTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceConfigTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceConfigTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceConfigTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> businessLocationId = const Value.absent(),
                Value<String> businessName = const Value.absent(),
                Value<String?> deviceLabel = const Value.absent(),
                Value<DateTime> provisionedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DeviceConfigCompanion(
                id: id,
                businessId: businessId,
                businessLocationId: businessLocationId,
                businessName: businessName,
                deviceLabel: deviceLabel,
                provisionedAt: provisionedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String businessId,
                required String businessLocationId,
                required String businessName,
                Value<String?> deviceLabel = const Value.absent(),
                required DateTime provisionedAt,
                required DateTime updatedAt,
              }) => DeviceConfigCompanion.insert(
                id: id,
                businessId: businessId,
                businessLocationId: businessLocationId,
                businessName: businessName,
                deviceLabel: deviceLabel,
                provisionedAt: provisionedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceConfigTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceConfigTable,
      DeviceConfigData,
      $$DeviceConfigTableFilterComposer,
      $$DeviceConfigTableOrderingComposer,
      $$DeviceConfigTableAnnotationComposer,
      $$DeviceConfigTableCreateCompanionBuilder,
      $$DeviceConfigTableUpdateCompanionBuilder,
      (
        DeviceConfigData,
        BaseReferences<_$AppDatabase, $DeviceConfigTable, DeviceConfigData>,
      ),
      DeviceConfigData,
      PrefetchHooks Function()
    >;
typedef $$PendingSalesTableCreateCompanionBuilder =
    PendingSalesCompanion Function({
      Value<int> id,
      required String clientSaleId,
      required String status,
      required String businessLocationId,
      Value<Decimal> discountAmount,
      required String paymentMethod,
      required DateTime occurredAt,
      Value<int?> deviceSequence,
      Value<String?> voidOrRefundReason,
      Value<String?> localOrderId,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> syncAttemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> syncedAt,
      required DateTime createdAt,
    });
typedef $$PendingSalesTableUpdateCompanionBuilder =
    PendingSalesCompanion Function({
      Value<int> id,
      Value<String> clientSaleId,
      Value<String> status,
      Value<String> businessLocationId,
      Value<Decimal> discountAmount,
      Value<String> paymentMethod,
      Value<DateTime> occurredAt,
      Value<int?> deviceSequence,
      Value<String?> voidOrRefundReason,
      Value<String?> localOrderId,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> syncAttemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> syncedAt,
      Value<DateTime> createdAt,
    });

final class $$PendingSalesTableReferences
    extends BaseReferences<_$AppDatabase, $PendingSalesTable, PendingSale> {
  $$PendingSalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $PendingSaleLineItemsTable,
    List<PendingSaleLineItem>
  >
  _pendingSaleLineItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pendingSaleLineItems,
        aliasName:
            'pending_sales__id__pending_sale_line_items__pending_sale_id',
      );

  $$PendingSaleLineItemsTableProcessedTableManager
  get pendingSaleLineItemsRefs {
    final manager = $$PendingSaleLineItemsTableTableManager(
      $_db,
      $_db.pendingSaleLineItems,
    ).filter((f) => f.pendingSaleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pendingSaleLineItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PendingVoidsRefundsTable,
    List<PendingVoidsRefund>
  >
  _pendingVoidsRefundsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pendingVoidsRefunds,
        aliasName:
            'pending_sales__client_sale_id__pending_voids_refunds__sale_id',
      );

  $$PendingVoidsRefundsTableProcessedTableManager get pendingVoidsRefundsRefs {
    final manager =
        $$PendingVoidsRefundsTableTableManager(
          $_db,
          $_db.pendingVoidsRefunds,
        ).filter(
          (f) => f.saleId.clientSaleId.sqlEquals(
            $_itemColumn<String>('client_sale_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _pendingVoidsRefundsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PendingSalesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSalesTable> {
  $$PendingSalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientSaleId => $composableBuilder(
    column: $table.clientSaleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get discountAmount =>
      $composableBuilder(
        column: $table.discountAmount,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceSequence => $composableBuilder(
    column: $table.deviceSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidOrRefundReason => $composableBuilder(
    column: $table.voidOrRefundReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localOrderId => $composableBuilder(
    column: $table.localOrderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pendingSaleLineItemsRefs(
    Expression<bool> Function($$PendingSaleLineItemsTableFilterComposer f) f,
  ) {
    final $$PendingSaleLineItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingSaleLineItems,
      getReferencedColumn: (t) => t.pendingSaleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingSaleLineItemsTableFilterComposer(
            $db: $db,
            $table: $db.pendingSaleLineItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pendingVoidsRefundsRefs(
    Expression<bool> Function($$PendingVoidsRefundsTableFilterComposer f) f,
  ) {
    final $$PendingVoidsRefundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientSaleId,
      referencedTable: $db.pendingVoidsRefunds,
      getReferencedColumn: (t) => t.saleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingVoidsRefundsTableFilterComposer(
            $db: $db,
            $table: $db.pendingVoidsRefunds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PendingSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSalesTable> {
  $$PendingSalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientSaleId => $composableBuilder(
    column: $table.clientSaleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceSequence => $composableBuilder(
    column: $table.deviceSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidOrRefundReason => $composableBuilder(
    column: $table.voidOrRefundReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localOrderId => $composableBuilder(
    column: $table.localOrderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSalesTable> {
  $$PendingSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientSaleId => $composableBuilder(
    column: $table.clientSaleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal, String> get discountAmount =>
      $composableBuilder(
        column: $table.discountAmount,
        builder: (column) => column,
      );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deviceSequence => $composableBuilder(
    column: $table.deviceSequence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voidOrRefundReason => $composableBuilder(
    column: $table.voidOrRefundReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localOrderId => $composableBuilder(
    column: $table.localOrderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> pendingSaleLineItemsRefs<T extends Object>(
    Expression<T> Function($$PendingSaleLineItemsTableAnnotationComposer a) f,
  ) {
    final $$PendingSaleLineItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.pendingSaleLineItems,
          getReferencedColumn: (t) => t.pendingSaleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PendingSaleLineItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.pendingSaleLineItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> pendingVoidsRefundsRefs<T extends Object>(
    Expression<T> Function($$PendingVoidsRefundsTableAnnotationComposer a) f,
  ) {
    final $$PendingVoidsRefundsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.clientSaleId,
          referencedTable: $db.pendingVoidsRefunds,
          getReferencedColumn: (t) => t.saleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PendingVoidsRefundsTableAnnotationComposer(
                $db: $db,
                $table: $db.pendingVoidsRefunds,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PendingSalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSalesTable,
          PendingSale,
          $$PendingSalesTableFilterComposer,
          $$PendingSalesTableOrderingComposer,
          $$PendingSalesTableAnnotationComposer,
          $$PendingSalesTableCreateCompanionBuilder,
          $$PendingSalesTableUpdateCompanionBuilder,
          (PendingSale, $$PendingSalesTableReferences),
          PendingSale,
          PrefetchHooks Function({
            bool pendingSaleLineItemsRefs,
            bool pendingVoidsRefundsRefs,
          })
        > {
  $$PendingSalesTableTableManager(_$AppDatabase db, $PendingSalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientSaleId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> businessLocationId = const Value.absent(),
                Value<Decimal> discountAmount = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int?> deviceSequence = const Value.absent(),
                Value<String?> voidOrRefundReason = const Value.absent(),
                Value<String?> localOrderId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> syncAttemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingSalesCompanion(
                id: id,
                clientSaleId: clientSaleId,
                status: status,
                businessLocationId: businessLocationId,
                discountAmount: discountAmount,
                paymentMethod: paymentMethod,
                occurredAt: occurredAt,
                deviceSequence: deviceSequence,
                voidOrRefundReason: voidOrRefundReason,
                localOrderId: localOrderId,
                syncStatus: syncStatus,
                syncError: syncError,
                syncAttemptCount: syncAttemptCount,
                lastAttemptAt: lastAttemptAt,
                syncedAt: syncedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientSaleId,
                required String status,
                required String businessLocationId,
                Value<Decimal> discountAmount = const Value.absent(),
                required String paymentMethod,
                required DateTime occurredAt,
                Value<int?> deviceSequence = const Value.absent(),
                Value<String?> voidOrRefundReason = const Value.absent(),
                Value<String?> localOrderId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> syncAttemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                required DateTime createdAt,
              }) => PendingSalesCompanion.insert(
                id: id,
                clientSaleId: clientSaleId,
                status: status,
                businessLocationId: businessLocationId,
                discountAmount: discountAmount,
                paymentMethod: paymentMethod,
                occurredAt: occurredAt,
                deviceSequence: deviceSequence,
                voidOrRefundReason: voidOrRefundReason,
                localOrderId: localOrderId,
                syncStatus: syncStatus,
                syncError: syncError,
                syncAttemptCount: syncAttemptCount,
                lastAttemptAt: lastAttemptAt,
                syncedAt: syncedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PendingSalesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                pendingSaleLineItemsRefs = false,
                pendingVoidsRefundsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pendingSaleLineItemsRefs) db.pendingSaleLineItems,
                    if (pendingVoidsRefundsRefs) db.pendingVoidsRefunds,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pendingSaleLineItemsRefs)
                        await $_getPrefetchedData<
                          PendingSale,
                          $PendingSalesTable,
                          PendingSaleLineItem
                        >(
                          currentTable: table,
                          referencedTable: $$PendingSalesTableReferences
                              ._pendingSaleLineItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PendingSalesTableReferences(
                                db,
                                table,
                                p0,
                              ).pendingSaleLineItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pendingSaleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pendingVoidsRefundsRefs)
                        await $_getPrefetchedData<
                          PendingSale,
                          $PendingSalesTable,
                          PendingVoidsRefund
                        >(
                          currentTable: table,
                          referencedTable: $$PendingSalesTableReferences
                              ._pendingVoidsRefundsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PendingSalesTableReferences(
                                db,
                                table,
                                p0,
                              ).pendingVoidsRefundsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.saleId == item.clientSaleId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PendingSalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSalesTable,
      PendingSale,
      $$PendingSalesTableFilterComposer,
      $$PendingSalesTableOrderingComposer,
      $$PendingSalesTableAnnotationComposer,
      $$PendingSalesTableCreateCompanionBuilder,
      $$PendingSalesTableUpdateCompanionBuilder,
      (PendingSale, $$PendingSalesTableReferences),
      PendingSale,
      PrefetchHooks Function({
        bool pendingSaleLineItemsRefs,
        bool pendingVoidsRefundsRefs,
      })
    >;
typedef $$PendingSaleLineItemsTableCreateCompanionBuilder =
    PendingSaleLineItemsCompanion Function({
      Value<int> id,
      required int pendingSaleId,
      required String itemId,
      required Decimal quantity,
      required Decimal unitPrice,
      Value<Decimal> discountAmount,
    });
typedef $$PendingSaleLineItemsTableUpdateCompanionBuilder =
    PendingSaleLineItemsCompanion Function({
      Value<int> id,
      Value<int> pendingSaleId,
      Value<String> itemId,
      Value<Decimal> quantity,
      Value<Decimal> unitPrice,
      Value<Decimal> discountAmount,
    });

final class $$PendingSaleLineItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PendingSaleLineItemsTable,
          PendingSaleLineItem
        > {
  $$PendingSaleLineItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PendingSalesTable _pendingSaleIdTable(_$AppDatabase db) =>
      db.pendingSales.createAlias(
        'pending_sale_line_items__pending_sale_id__pending_sales__id',
      );

  $$PendingSalesTableProcessedTableManager get pendingSaleId {
    final $_column = $_itemColumn<int>('pending_sale_id')!;

    final manager = $$PendingSalesTableTableManager(
      $_db,
      $_db.pendingSales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pendingSaleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PendingSaleLineItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSaleLineItemsTable> {
  $$PendingSaleLineItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get quantity =>
      $composableBuilder(
        column: $table.quantity,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get unitPrice =>
      $composableBuilder(
        column: $table.unitPrice,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get discountAmount =>
      $composableBuilder(
        column: $table.discountAmount,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$PendingSalesTableFilterComposer get pendingSaleId {
    final $$PendingSalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pendingSaleId,
      referencedTable: $db.pendingSales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingSalesTableFilterComposer(
            $db: $db,
            $table: $db.pendingSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingSaleLineItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSaleLineItemsTable> {
  $$PendingSaleLineItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  $$PendingSalesTableOrderingComposer get pendingSaleId {
    final $$PendingSalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pendingSaleId,
      referencedTable: $db.pendingSales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingSalesTableOrderingComposer(
            $db: $db,
            $table: $db.pendingSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingSaleLineItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSaleLineItemsTable> {
  $$PendingSaleLineItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get discountAmount =>
      $composableBuilder(
        column: $table.discountAmount,
        builder: (column) => column,
      );

  $$PendingSalesTableAnnotationComposer get pendingSaleId {
    final $$PendingSalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pendingSaleId,
      referencedTable: $db.pendingSales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingSalesTableAnnotationComposer(
            $db: $db,
            $table: $db.pendingSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingSaleLineItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSaleLineItemsTable,
          PendingSaleLineItem,
          $$PendingSaleLineItemsTableFilterComposer,
          $$PendingSaleLineItemsTableOrderingComposer,
          $$PendingSaleLineItemsTableAnnotationComposer,
          $$PendingSaleLineItemsTableCreateCompanionBuilder,
          $$PendingSaleLineItemsTableUpdateCompanionBuilder,
          (PendingSaleLineItem, $$PendingSaleLineItemsTableReferences),
          PendingSaleLineItem,
          PrefetchHooks Function({bool pendingSaleId})
        > {
  $$PendingSaleLineItemsTableTableManager(
    _$AppDatabase db,
    $PendingSaleLineItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSaleLineItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSaleLineItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingSaleLineItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> pendingSaleId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<Decimal> quantity = const Value.absent(),
                Value<Decimal> unitPrice = const Value.absent(),
                Value<Decimal> discountAmount = const Value.absent(),
              }) => PendingSaleLineItemsCompanion(
                id: id,
                pendingSaleId: pendingSaleId,
                itemId: itemId,
                quantity: quantity,
                unitPrice: unitPrice,
                discountAmount: discountAmount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int pendingSaleId,
                required String itemId,
                required Decimal quantity,
                required Decimal unitPrice,
                Value<Decimal> discountAmount = const Value.absent(),
              }) => PendingSaleLineItemsCompanion.insert(
                id: id,
                pendingSaleId: pendingSaleId,
                itemId: itemId,
                quantity: quantity,
                unitPrice: unitPrice,
                discountAmount: discountAmount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PendingSaleLineItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pendingSaleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pendingSaleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pendingSaleId,
                                referencedTable:
                                    $$PendingSaleLineItemsTableReferences
                                        ._pendingSaleIdTable(db),
                                referencedColumn:
                                    $$PendingSaleLineItemsTableReferences
                                        ._pendingSaleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PendingSaleLineItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSaleLineItemsTable,
      PendingSaleLineItem,
      $$PendingSaleLineItemsTableFilterComposer,
      $$PendingSaleLineItemsTableOrderingComposer,
      $$PendingSaleLineItemsTableAnnotationComposer,
      $$PendingSaleLineItemsTableCreateCompanionBuilder,
      $$PendingSaleLineItemsTableUpdateCompanionBuilder,
      (PendingSaleLineItem, $$PendingSaleLineItemsTableReferences),
      PendingSaleLineItem,
      PrefetchHooks Function({bool pendingSaleId})
    >;
typedef $$CachedItemsTableCreateCompanionBuilder =
    CachedItemsCompanion Function({
      required String id,
      required String businessId,
      required String businessLocationId,
      required String name,
      required String unitOfMeasure,
      Value<String?> category,
      required Decimal reorderThreshold,
      required Decimal reorderQuantity,
      Value<Decimal?> sellingPrice,
      Value<bool> allowNegativeStock,
      required String itemType,
      Value<bool> isActive,
      required DateTime createdAtServer,
      required DateTime updatedAtServer,
      required DateTime lastSeenAt,
      required DateTime lastSyncedAt,
      Value<int> rowid,
    });
typedef $$CachedItemsTableUpdateCompanionBuilder =
    CachedItemsCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> businessLocationId,
      Value<String> name,
      Value<String> unitOfMeasure,
      Value<String?> category,
      Value<Decimal> reorderThreshold,
      Value<Decimal> reorderQuantity,
      Value<Decimal?> sellingPrice,
      Value<bool> allowNegativeStock,
      Value<String> itemType,
      Value<bool> isActive,
      Value<DateTime> createdAtServer,
      Value<DateTime> updatedAtServer,
      Value<DateTime> lastSeenAt,
      Value<DateTime> lastSyncedAt,
      Value<int> rowid,
    });

class $$CachedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedItemsTable> {
  $$CachedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitOfMeasure => $composableBuilder(
    column: $table.unitOfMeasure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String>
  get reorderThreshold => $composableBuilder(
    column: $table.reorderThreshold,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String>
  get reorderQuantity => $composableBuilder(
    column: $table.reorderQuantity,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal?, Decimal, String> get sellingPrice =>
      $composableBuilder(
        column: $table.sellingPrice,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get allowNegativeStock => $composableBuilder(
    column: $table.allowNegativeStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtServer => $composableBuilder(
    column: $table.createdAtServer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtServer => $composableBuilder(
    column: $table.updatedAtServer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedItemsTable> {
  $$CachedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitOfMeasure => $composableBuilder(
    column: $table.unitOfMeasure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reorderThreshold => $composableBuilder(
    column: $table.reorderThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reorderQuantity => $composableBuilder(
    column: $table.reorderQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowNegativeStock => $composableBuilder(
    column: $table.allowNegativeStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtServer => $composableBuilder(
    column: $table.createdAtServer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtServer => $composableBuilder(
    column: $table.updatedAtServer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedItemsTable> {
  $$CachedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unitOfMeasure => $composableBuilder(
    column: $table.unitOfMeasure,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get reorderThreshold =>
      $composableBuilder(
        column: $table.reorderThreshold,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal, String> get reorderQuantity =>
      $composableBuilder(
        column: $table.reorderQuantity,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Decimal?, String> get sellingPrice =>
      $composableBuilder(
        column: $table.sellingPrice,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get allowNegativeStock => $composableBuilder(
    column: $table.allowNegativeStock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtServer => $composableBuilder(
    column: $table.createdAtServer,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtServer => $composableBuilder(
    column: $table.updatedAtServer,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$CachedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedItemsTable,
          CachedItem,
          $$CachedItemsTableFilterComposer,
          $$CachedItemsTableOrderingComposer,
          $$CachedItemsTableAnnotationComposer,
          $$CachedItemsTableCreateCompanionBuilder,
          $$CachedItemsTableUpdateCompanionBuilder,
          (
            CachedItem,
            BaseReferences<_$AppDatabase, $CachedItemsTable, CachedItem>,
          ),
          CachedItem,
          PrefetchHooks Function()
        > {
  $$CachedItemsTableTableManager(_$AppDatabase db, $CachedItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> businessLocationId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> unitOfMeasure = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<Decimal> reorderThreshold = const Value.absent(),
                Value<Decimal> reorderQuantity = const Value.absent(),
                Value<Decimal?> sellingPrice = const Value.absent(),
                Value<bool> allowNegativeStock = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAtServer = const Value.absent(),
                Value<DateTime> updatedAtServer = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedItemsCompanion(
                id: id,
                businessId: businessId,
                businessLocationId: businessLocationId,
                name: name,
                unitOfMeasure: unitOfMeasure,
                category: category,
                reorderThreshold: reorderThreshold,
                reorderQuantity: reorderQuantity,
                sellingPrice: sellingPrice,
                allowNegativeStock: allowNegativeStock,
                itemType: itemType,
                isActive: isActive,
                createdAtServer: createdAtServer,
                updatedAtServer: updatedAtServer,
                lastSeenAt: lastSeenAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String businessLocationId,
                required String name,
                required String unitOfMeasure,
                Value<String?> category = const Value.absent(),
                required Decimal reorderThreshold,
                required Decimal reorderQuantity,
                Value<Decimal?> sellingPrice = const Value.absent(),
                Value<bool> allowNegativeStock = const Value.absent(),
                required String itemType,
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAtServer,
                required DateTime updatedAtServer,
                required DateTime lastSeenAt,
                required DateTime lastSyncedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedItemsCompanion.insert(
                id: id,
                businessId: businessId,
                businessLocationId: businessLocationId,
                name: name,
                unitOfMeasure: unitOfMeasure,
                category: category,
                reorderThreshold: reorderThreshold,
                reorderQuantity: reorderQuantity,
                sellingPrice: sellingPrice,
                allowNegativeStock: allowNegativeStock,
                itemType: itemType,
                isActive: isActive,
                createdAtServer: createdAtServer,
                updatedAtServer: updatedAtServer,
                lastSeenAt: lastSeenAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedItemsTable,
      CachedItem,
      $$CachedItemsTableFilterComposer,
      $$CachedItemsTableOrderingComposer,
      $$CachedItemsTableAnnotationComposer,
      $$CachedItemsTableCreateCompanionBuilder,
      $$CachedItemsTableUpdateCompanionBuilder,
      (
        CachedItem,
        BaseReferences<_$AppDatabase, $CachedItemsTable, CachedItem>,
      ),
      CachedItem,
      PrefetchHooks Function()
    >;
typedef $$CachedPermissionsTableCreateCompanionBuilder =
    CachedPermissionsCompanion Function({
      required String userId,
      required String businessId,
      required String businessName,
      required String businessLocationId,
      required String roleName,
      required String permissionCodes,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedPermissionsTableUpdateCompanionBuilder =
    CachedPermissionsCompanion Function({
      Value<String> userId,
      Value<String> businessId,
      Value<String> businessName,
      Value<String> businessLocationId,
      Value<String> roleName,
      Value<String> permissionCodes,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$CachedPermissionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedPermissionsTable,
          CachedPermission
        > {
  $$CachedPermissionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalUserProfilesTable _userIdTable(_$AppDatabase db) => db
      .localUserProfiles
      .createAlias('cached_permissions__user_id__local_user_profiles__id');

  $$LocalUserProfilesTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$LocalUserProfilesTableTableManager(
      $_db,
      $_db.localUserProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedPermissionsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPermissionsTable> {
  $$CachedPermissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissionCodes => $composableBuilder(
    column: $table.permissionCodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalUserProfilesTableFilterComposer get userId {
    final $$LocalUserProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localUserProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalUserProfilesTableFilterComposer(
            $db: $db,
            $table: $db.localUserProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedPermissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPermissionsTable> {
  $$CachedPermissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissionCodes => $composableBuilder(
    column: $table.permissionCodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalUserProfilesTableOrderingComposer get userId {
    final $$LocalUserProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localUserProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalUserProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.localUserProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedPermissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPermissionsTable> {
  $$CachedPermissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roleName =>
      $composableBuilder(column: $table.roleName, builder: (column) => column);

  GeneratedColumn<String> get permissionCodes => $composableBuilder(
    column: $table.permissionCodes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  $$LocalUserProfilesTableAnnotationComposer get userId {
    final $$LocalUserProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.userId,
          referencedTable: $db.localUserProfiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalUserProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.localUserProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CachedPermissionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPermissionsTable,
          CachedPermission,
          $$CachedPermissionsTableFilterComposer,
          $$CachedPermissionsTableOrderingComposer,
          $$CachedPermissionsTableAnnotationComposer,
          $$CachedPermissionsTableCreateCompanionBuilder,
          $$CachedPermissionsTableUpdateCompanionBuilder,
          (CachedPermission, $$CachedPermissionsTableReferences),
          CachedPermission,
          PrefetchHooks Function({bool userId})
        > {
  $$CachedPermissionsTableTableManager(
    _$AppDatabase db,
    $CachedPermissionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPermissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPermissionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPermissionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> businessName = const Value.absent(),
                Value<String> businessLocationId = const Value.absent(),
                Value<String> roleName = const Value.absent(),
                Value<String> permissionCodes = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPermissionsCompanion(
                userId: userId,
                businessId: businessId,
                businessName: businessName,
                businessLocationId: businessLocationId,
                roleName: roleName,
                permissionCodes: permissionCodes,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String businessId,
                required String businessName,
                required String businessLocationId,
                required String roleName,
                required String permissionCodes,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedPermissionsCompanion.insert(
                userId: userId,
                businessId: businessId,
                businessName: businessName,
                businessLocationId: businessLocationId,
                roleName: roleName,
                permissionCodes: permissionCodes,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedPermissionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable:
                                    $$CachedPermissionsTableReferences
                                        ._userIdTable(db),
                                referencedColumn:
                                    $$CachedPermissionsTableReferences
                                        ._userIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedPermissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPermissionsTable,
      CachedPermission,
      $$CachedPermissionsTableFilterComposer,
      $$CachedPermissionsTableOrderingComposer,
      $$CachedPermissionsTableAnnotationComposer,
      $$CachedPermissionsTableCreateCompanionBuilder,
      $$CachedPermissionsTableUpdateCompanionBuilder,
      (CachedPermission, $$CachedPermissionsTableReferences),
      CachedPermission,
      PrefetchHooks Function({bool userId})
    >;
typedef $$CachedStockLevelsTableCreateCompanionBuilder =
    CachedStockLevelsCompanion Function({
      required String itemId,
      required String businessLocationId,
      required Decimal currentQuantity,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedStockLevelsTableUpdateCompanionBuilder =
    CachedStockLevelsCompanion Function({
      Value<String> itemId,
      Value<String> businessLocationId,
      Value<Decimal> currentQuantity,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedStockLevelsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedStockLevelsTable> {
  $$CachedStockLevelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String>
  get currentQuantity => $composableBuilder(
    column: $table.currentQuantity,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedStockLevelsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedStockLevelsTable> {
  $$CachedStockLevelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentQuantity => $composableBuilder(
    column: $table.currentQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedStockLevelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedStockLevelsTable> {
  $$CachedStockLevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Decimal, String> get currentQuantity =>
      $composableBuilder(
        column: $table.currentQuantity,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedStockLevelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedStockLevelsTable,
          CachedStockLevel,
          $$CachedStockLevelsTableFilterComposer,
          $$CachedStockLevelsTableOrderingComposer,
          $$CachedStockLevelsTableAnnotationComposer,
          $$CachedStockLevelsTableCreateCompanionBuilder,
          $$CachedStockLevelsTableUpdateCompanionBuilder,
          (
            CachedStockLevel,
            BaseReferences<
              _$AppDatabase,
              $CachedStockLevelsTable,
              CachedStockLevel
            >,
          ),
          CachedStockLevel,
          PrefetchHooks Function()
        > {
  $$CachedStockLevelsTableTableManager(
    _$AppDatabase db,
    $CachedStockLevelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedStockLevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedStockLevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedStockLevelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String> businessLocationId = const Value.absent(),
                Value<Decimal> currentQuantity = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedStockLevelsCompanion(
                itemId: itemId,
                businessLocationId: businessLocationId,
                currentQuantity: currentQuantity,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required String businessLocationId,
                required Decimal currentQuantity,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedStockLevelsCompanion.insert(
                itemId: itemId,
                businessLocationId: businessLocationId,
                currentQuantity: currentQuantity,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedStockLevelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedStockLevelsTable,
      CachedStockLevel,
      $$CachedStockLevelsTableFilterComposer,
      $$CachedStockLevelsTableOrderingComposer,
      $$CachedStockLevelsTableAnnotationComposer,
      $$CachedStockLevelsTableCreateCompanionBuilder,
      $$CachedStockLevelsTableUpdateCompanionBuilder,
      (
        CachedStockLevel,
        BaseReferences<
          _$AppDatabase,
          $CachedStockLevelsTable,
          CachedStockLevel
        >,
      ),
      CachedStockLevel,
      PrefetchHooks Function()
    >;
typedef $$PendingVoidsRefundsTableCreateCompanionBuilder =
    PendingVoidsRefundsCompanion Function({
      Value<int> id,
      required String clientActionId,
      required String saleId,
      required String newStatus,
      required String reason,
      required String actorUserId,
      required DateTime occurredAt,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> syncAttemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> syncedAt,
      required DateTime createdAt,
    });
typedef $$PendingVoidsRefundsTableUpdateCompanionBuilder =
    PendingVoidsRefundsCompanion Function({
      Value<int> id,
      Value<String> clientActionId,
      Value<String> saleId,
      Value<String> newStatus,
      Value<String> reason,
      Value<String> actorUserId,
      Value<DateTime> occurredAt,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> syncAttemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> syncedAt,
      Value<DateTime> createdAt,
    });

final class $$PendingVoidsRefundsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PendingVoidsRefundsTable,
          PendingVoidsRefund
        > {
  $$PendingVoidsRefundsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PendingSalesTable _saleIdTable(_$AppDatabase db) =>
      db.pendingSales.createAlias(
        'pending_voids_refunds__sale_id__pending_sales__client_sale_id',
      );

  $$PendingSalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<String>('sale_id')!;

    final manager = $$PendingSalesTableTableManager(
      $_db,
      $_db.pendingSales,
    ).filter((f) => f.clientSaleId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PendingVoidsRefundsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingVoidsRefundsTable> {
  $$PendingVoidsRefundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientActionId => $composableBuilder(
    column: $table.clientActionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newStatus => $composableBuilder(
    column: $table.newStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PendingSalesTableFilterComposer get saleId {
    final $$PendingSalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.pendingSales,
      getReferencedColumn: (t) => t.clientSaleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingSalesTableFilterComposer(
            $db: $db,
            $table: $db.pendingSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingVoidsRefundsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingVoidsRefundsTable> {
  $$PendingVoidsRefundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientActionId => $composableBuilder(
    column: $table.clientActionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newStatus => $composableBuilder(
    column: $table.newStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PendingSalesTableOrderingComposer get saleId {
    final $$PendingSalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.pendingSales,
      getReferencedColumn: (t) => t.clientSaleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingSalesTableOrderingComposer(
            $db: $db,
            $table: $db.pendingSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingVoidsRefundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingVoidsRefundsTable> {
  $$PendingVoidsRefundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientActionId => $composableBuilder(
    column: $table.clientActionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get newStatus =>
      $composableBuilder(column: $table.newStatus, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PendingSalesTableAnnotationComposer get saleId {
    final $$PendingSalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleId,
      referencedTable: $db.pendingSales,
      getReferencedColumn: (t) => t.clientSaleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingSalesTableAnnotationComposer(
            $db: $db,
            $table: $db.pendingSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingVoidsRefundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingVoidsRefundsTable,
          PendingVoidsRefund,
          $$PendingVoidsRefundsTableFilterComposer,
          $$PendingVoidsRefundsTableOrderingComposer,
          $$PendingVoidsRefundsTableAnnotationComposer,
          $$PendingVoidsRefundsTableCreateCompanionBuilder,
          $$PendingVoidsRefundsTableUpdateCompanionBuilder,
          (PendingVoidsRefund, $$PendingVoidsRefundsTableReferences),
          PendingVoidsRefund,
          PrefetchHooks Function({bool saleId})
        > {
  $$PendingVoidsRefundsTableTableManager(
    _$AppDatabase db,
    $PendingVoidsRefundsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingVoidsRefundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingVoidsRefundsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingVoidsRefundsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientActionId = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> newStatus = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> actorUserId = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> syncAttemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingVoidsRefundsCompanion(
                id: id,
                clientActionId: clientActionId,
                saleId: saleId,
                newStatus: newStatus,
                reason: reason,
                actorUserId: actorUserId,
                occurredAt: occurredAt,
                syncStatus: syncStatus,
                syncError: syncError,
                syncAttemptCount: syncAttemptCount,
                lastAttemptAt: lastAttemptAt,
                syncedAt: syncedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientActionId,
                required String saleId,
                required String newStatus,
                required String reason,
                required String actorUserId,
                required DateTime occurredAt,
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> syncAttemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                required DateTime createdAt,
              }) => PendingVoidsRefundsCompanion.insert(
                id: id,
                clientActionId: clientActionId,
                saleId: saleId,
                newStatus: newStatus,
                reason: reason,
                actorUserId: actorUserId,
                occurredAt: occurredAt,
                syncStatus: syncStatus,
                syncError: syncError,
                syncAttemptCount: syncAttemptCount,
                lastAttemptAt: lastAttemptAt,
                syncedAt: syncedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PendingVoidsRefundsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({saleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (saleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.saleId,
                                referencedTable:
                                    $$PendingVoidsRefundsTableReferences
                                        ._saleIdTable(db),
                                referencedColumn:
                                    $$PendingVoidsRefundsTableReferences
                                        ._saleIdTable(db)
                                        .clientSaleId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PendingVoidsRefundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingVoidsRefundsTable,
      PendingVoidsRefund,
      $$PendingVoidsRefundsTableFilterComposer,
      $$PendingVoidsRefundsTableOrderingComposer,
      $$PendingVoidsRefundsTableAnnotationComposer,
      $$PendingVoidsRefundsTableCreateCompanionBuilder,
      $$PendingVoidsRefundsTableUpdateCompanionBuilder,
      (PendingVoidsRefund, $$PendingVoidsRefundsTableReferences),
      PendingVoidsRefund,
      PrefetchHooks Function({bool saleId})
    >;
typedef $$ExpenseEntriesTableCreateCompanionBuilder =
    ExpenseEntriesCompanion Function({
      Value<int> id,
      required String expenseId,
      required String businessId,
      required String businessLocationId,
      required String category,
      required Decimal amount,
      Value<String?> description,
      required DateTime occurredAt,
      required String actorUserId,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> syncAttemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> syncedAt,
      required DateTime createdAt,
    });
typedef $$ExpenseEntriesTableUpdateCompanionBuilder =
    ExpenseEntriesCompanion Function({
      Value<int> id,
      Value<String> expenseId,
      Value<String> businessId,
      Value<String> businessLocationId,
      Value<String> category,
      Value<Decimal> amount,
      Value<String?> description,
      Value<DateTime> occurredAt,
      Value<String> actorUserId,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> syncAttemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> syncedAt,
      Value<DateTime> createdAt,
    });

class $$ExpenseEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseEntriesTable> {
  $$ExpenseEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get amount =>
      $composableBuilder(
        column: $table.amount,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpenseEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseEntriesTable> {
  $$ExpenseEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpenseEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseEntriesTable> {
  $$ExpenseEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExpenseEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseEntriesTable,
          ExpenseEntry,
          $$ExpenseEntriesTableFilterComposer,
          $$ExpenseEntriesTableOrderingComposer,
          $$ExpenseEntriesTableAnnotationComposer,
          $$ExpenseEntriesTableCreateCompanionBuilder,
          $$ExpenseEntriesTableUpdateCompanionBuilder,
          (
            ExpenseEntry,
            BaseReferences<_$AppDatabase, $ExpenseEntriesTable, ExpenseEntry>,
          ),
          ExpenseEntry,
          PrefetchHooks Function()
        > {
  $$ExpenseEntriesTableTableManager(
    _$AppDatabase db,
    $ExpenseEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> businessLocationId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<Decimal> amount = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> actorUserId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> syncAttemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExpenseEntriesCompanion(
                id: id,
                expenseId: expenseId,
                businessId: businessId,
                businessLocationId: businessLocationId,
                category: category,
                amount: amount,
                description: description,
                occurredAt: occurredAt,
                actorUserId: actorUserId,
                syncStatus: syncStatus,
                syncError: syncError,
                syncAttemptCount: syncAttemptCount,
                lastAttemptAt: lastAttemptAt,
                syncedAt: syncedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String expenseId,
                required String businessId,
                required String businessLocationId,
                required String category,
                required Decimal amount,
                Value<String?> description = const Value.absent(),
                required DateTime occurredAt,
                required String actorUserId,
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> syncAttemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                required DateTime createdAt,
              }) => ExpenseEntriesCompanion.insert(
                id: id,
                expenseId: expenseId,
                businessId: businessId,
                businessLocationId: businessLocationId,
                category: category,
                amount: amount,
                description: description,
                occurredAt: occurredAt,
                actorUserId: actorUserId,
                syncStatus: syncStatus,
                syncError: syncError,
                syncAttemptCount: syncAttemptCount,
                lastAttemptAt: lastAttemptAt,
                syncedAt: syncedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpenseEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseEntriesTable,
      ExpenseEntry,
      $$ExpenseEntriesTableFilterComposer,
      $$ExpenseEntriesTableOrderingComposer,
      $$ExpenseEntriesTableAnnotationComposer,
      $$ExpenseEntriesTableCreateCompanionBuilder,
      $$ExpenseEntriesTableUpdateCompanionBuilder,
      (
        ExpenseEntry,
        BaseReferences<_$AppDatabase, $ExpenseEntriesTable, ExpenseEntry>,
      ),
      ExpenseEntry,
      PrefetchHooks Function()
    >;
typedef $$OtherIncomeEntriesTableCreateCompanionBuilder =
    OtherIncomeEntriesCompanion Function({
      Value<int> id,
      required String incomeId,
      required String businessId,
      required String businessLocationId,
      required String category,
      required Decimal amount,
      Value<String?> description,
      required DateTime occurredAt,
      required String actorUserId,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> syncAttemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> syncedAt,
      required DateTime createdAt,
    });
typedef $$OtherIncomeEntriesTableUpdateCompanionBuilder =
    OtherIncomeEntriesCompanion Function({
      Value<int> id,
      Value<String> incomeId,
      Value<String> businessId,
      Value<String> businessLocationId,
      Value<String> category,
      Value<Decimal> amount,
      Value<String?> description,
      Value<DateTime> occurredAt,
      Value<String> actorUserId,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> syncAttemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> syncedAt,
      Value<DateTime> createdAt,
    });

class $$OtherIncomeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OtherIncomeEntriesTable> {
  $$OtherIncomeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get incomeId => $composableBuilder(
    column: $table.incomeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get amount =>
      $composableBuilder(
        column: $table.amount,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OtherIncomeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OtherIncomeEntriesTable> {
  $$OtherIncomeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get incomeId => $composableBuilder(
    column: $table.incomeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OtherIncomeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OtherIncomeEntriesTable> {
  $$OtherIncomeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get incomeId =>
      $composableBuilder(column: $table.incomeId, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessLocationId => $composableBuilder(
    column: $table.businessLocationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OtherIncomeEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OtherIncomeEntriesTable,
          OtherIncomeEntry,
          $$OtherIncomeEntriesTableFilterComposer,
          $$OtherIncomeEntriesTableOrderingComposer,
          $$OtherIncomeEntriesTableAnnotationComposer,
          $$OtherIncomeEntriesTableCreateCompanionBuilder,
          $$OtherIncomeEntriesTableUpdateCompanionBuilder,
          (
            OtherIncomeEntry,
            BaseReferences<
              _$AppDatabase,
              $OtherIncomeEntriesTable,
              OtherIncomeEntry
            >,
          ),
          OtherIncomeEntry,
          PrefetchHooks Function()
        > {
  $$OtherIncomeEntriesTableTableManager(
    _$AppDatabase db,
    $OtherIncomeEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OtherIncomeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OtherIncomeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OtherIncomeEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> incomeId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> businessLocationId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<Decimal> amount = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> actorUserId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> syncAttemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OtherIncomeEntriesCompanion(
                id: id,
                incomeId: incomeId,
                businessId: businessId,
                businessLocationId: businessLocationId,
                category: category,
                amount: amount,
                description: description,
                occurredAt: occurredAt,
                actorUserId: actorUserId,
                syncStatus: syncStatus,
                syncError: syncError,
                syncAttemptCount: syncAttemptCount,
                lastAttemptAt: lastAttemptAt,
                syncedAt: syncedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String incomeId,
                required String businessId,
                required String businessLocationId,
                required String category,
                required Decimal amount,
                Value<String?> description = const Value.absent(),
                required DateTime occurredAt,
                required String actorUserId,
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> syncAttemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                required DateTime createdAt,
              }) => OtherIncomeEntriesCompanion.insert(
                id: id,
                incomeId: incomeId,
                businessId: businessId,
                businessLocationId: businessLocationId,
                category: category,
                amount: amount,
                description: description,
                occurredAt: occurredAt,
                actorUserId: actorUserId,
                syncStatus: syncStatus,
                syncError: syncError,
                syncAttemptCount: syncAttemptCount,
                lastAttemptAt: lastAttemptAt,
                syncedAt: syncedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OtherIncomeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OtherIncomeEntriesTable,
      OtherIncomeEntry,
      $$OtherIncomeEntriesTableFilterComposer,
      $$OtherIncomeEntriesTableOrderingComposer,
      $$OtherIncomeEntriesTableAnnotationComposer,
      $$OtherIncomeEntriesTableCreateCompanionBuilder,
      $$OtherIncomeEntriesTableUpdateCompanionBuilder,
      (
        OtherIncomeEntry,
        BaseReferences<
          _$AppDatabase,
          $OtherIncomeEntriesTable,
          OtherIncomeEntry
        >,
      ),
      OtherIncomeEntry,
      PrefetchHooks Function()
    >;
typedef $$LocalAuditLogTableCreateCompanionBuilder =
    LocalAuditLogCompanion Function({
      Value<int> id,
      required String actorUserId,
      required String action,
      Value<String?> resourceType,
      Value<String?> resourceId,
      Value<String?> detailsJson,
      required DateTime occurredAt,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> syncAttemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> syncedAt,
      required DateTime createdAt,
    });
typedef $$LocalAuditLogTableUpdateCompanionBuilder =
    LocalAuditLogCompanion Function({
      Value<int> id,
      Value<String> actorUserId,
      Value<String> action,
      Value<String?> resourceType,
      Value<String?> resourceId,
      Value<String?> detailsJson,
      Value<DateTime> occurredAt,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> syncAttemptCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> syncedAt,
      Value<DateTime> createdAt,
    });

class $$LocalAuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAuditLogTable> {
  $$LocalAuditLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceType => $composableBuilder(
    column: $table.resourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAuditLogTable> {
  $$LocalAuditLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceType => $composableBuilder(
    column: $table.resourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAuditLogTable> {
  $$LocalAuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actorUserId => $composableBuilder(
    column: $table.actorUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get resourceType => $composableBuilder(
    column: $table.resourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<int> get syncAttemptCount => $composableBuilder(
    column: $table.syncAttemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalAuditLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAuditLogTable,
          LocalAuditLogData,
          $$LocalAuditLogTableFilterComposer,
          $$LocalAuditLogTableOrderingComposer,
          $$LocalAuditLogTableAnnotationComposer,
          $$LocalAuditLogTableCreateCompanionBuilder,
          $$LocalAuditLogTableUpdateCompanionBuilder,
          (
            LocalAuditLogData,
            BaseReferences<
              _$AppDatabase,
              $LocalAuditLogTable,
              LocalAuditLogData
            >,
          ),
          LocalAuditLogData,
          PrefetchHooks Function()
        > {
  $$LocalAuditLogTableTableManager(_$AppDatabase db, $LocalAuditLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> actorUserId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> resourceType = const Value.absent(),
                Value<String?> resourceId = const Value.absent(),
                Value<String?> detailsJson = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> syncAttemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocalAuditLogCompanion(
                id: id,
                actorUserId: actorUserId,
                action: action,
                resourceType: resourceType,
                resourceId: resourceId,
                detailsJson: detailsJson,
                occurredAt: occurredAt,
                syncStatus: syncStatus,
                syncError: syncError,
                syncAttemptCount: syncAttemptCount,
                lastAttemptAt: lastAttemptAt,
                syncedAt: syncedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String actorUserId,
                required String action,
                Value<String?> resourceType = const Value.absent(),
                Value<String?> resourceId = const Value.absent(),
                Value<String?> detailsJson = const Value.absent(),
                required DateTime occurredAt,
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> syncAttemptCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                required DateTime createdAt,
              }) => LocalAuditLogCompanion.insert(
                id: id,
                actorUserId: actorUserId,
                action: action,
                resourceType: resourceType,
                resourceId: resourceId,
                detailsJson: detailsJson,
                occurredAt: occurredAt,
                syncStatus: syncStatus,
                syncError: syncError,
                syncAttemptCount: syncAttemptCount,
                lastAttemptAt: lastAttemptAt,
                syncedAt: syncedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAuditLogTable,
      LocalAuditLogData,
      $$LocalAuditLogTableFilterComposer,
      $$LocalAuditLogTableOrderingComposer,
      $$LocalAuditLogTableAnnotationComposer,
      $$LocalAuditLogTableCreateCompanionBuilder,
      $$LocalAuditLogTableUpdateCompanionBuilder,
      (
        LocalAuditLogData,
        BaseReferences<_$AppDatabase, $LocalAuditLogTable, LocalAuditLogData>,
      ),
      LocalAuditLogData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalUserProfilesTableTableManager get localUserProfiles =>
      $$LocalUserProfilesTableTableManager(_db, _db.localUserProfiles);
  $$DeviceConfigTableTableManager get deviceConfig =>
      $$DeviceConfigTableTableManager(_db, _db.deviceConfig);
  $$PendingSalesTableTableManager get pendingSales =>
      $$PendingSalesTableTableManager(_db, _db.pendingSales);
  $$PendingSaleLineItemsTableTableManager get pendingSaleLineItems =>
      $$PendingSaleLineItemsTableTableManager(_db, _db.pendingSaleLineItems);
  $$CachedItemsTableTableManager get cachedItems =>
      $$CachedItemsTableTableManager(_db, _db.cachedItems);
  $$CachedPermissionsTableTableManager get cachedPermissions =>
      $$CachedPermissionsTableTableManager(_db, _db.cachedPermissions);
  $$CachedStockLevelsTableTableManager get cachedStockLevels =>
      $$CachedStockLevelsTableTableManager(_db, _db.cachedStockLevels);
  $$PendingVoidsRefundsTableTableManager get pendingVoidsRefunds =>
      $$PendingVoidsRefundsTableTableManager(_db, _db.pendingVoidsRefunds);
  $$ExpenseEntriesTableTableManager get expenseEntries =>
      $$ExpenseEntriesTableTableManager(_db, _db.expenseEntries);
  $$OtherIncomeEntriesTableTableManager get otherIncomeEntries =>
      $$OtherIncomeEntriesTableTableManager(_db, _db.otherIncomeEntries);
  $$LocalAuditLogTableTableManager get localAuditLog =>
      $$LocalAuditLogTableTableManager(_db, _db.localAuditLog);
}
