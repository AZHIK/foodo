// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalUserProfilesTable extends LocalUserProfiles
    with TableInfo<$LocalUserProfilesTable, LocalUserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
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
  static const VerificationMeta _activeBusinessIdMeta = const VerificationMeta(
    'activeBusinessId',
  );
  @override
  late final GeneratedColumn<String> activeBusinessId = GeneratedColumn<String>(
    'active_business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastLoginAtMeta = const VerificationMeta(
    'lastLoginAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastLoginAt = GeneratedColumn<DateTime>(
    'last_login_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCurrentlyActiveMeta = const VerificationMeta(
    'isCurrentlyActive',
  );
  @override
  late final GeneratedColumn<bool> isCurrentlyActive = GeneratedColumn<bool>(
    'is_currently_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_currently_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    phone,
    displayName,
    pinHash,
    activeBusinessId,
    lastLoginAt,
    isCurrentlyActive,
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
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
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
    if (data.containsKey('active_business_id')) {
      context.handle(
        _activeBusinessIdMeta,
        activeBusinessId.isAcceptableOrUnknown(
          data['active_business_id']!,
          _activeBusinessIdMeta,
        ),
      );
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
        _lastLoginAtMeta,
        lastLoginAt.isAcceptableOrUnknown(
          data['last_login_at']!,
          _lastLoginAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastLoginAtMeta);
    }
    if (data.containsKey('is_currently_active')) {
      context.handle(
        _isCurrentlyActiveMeta,
        isCurrentlyActive.isAcceptableOrUnknown(
          data['is_currently_active']!,
          _isCurrentlyActiveMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalUserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUserProfile(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
      )!,
      activeBusinessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_business_id'],
      ),
      lastLoginAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_login_at'],
      )!,
      isCurrentlyActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_currently_active'],
      )!,
    );
  }

  @override
  $LocalUserProfilesTable createAlias(String alias) {
    return $LocalUserProfilesTable(attachedDatabase, alias);
  }
}

class LocalUserProfile extends DataClass
    implements Insertable<LocalUserProfile> {
  final String userId;
  final String phone;
  final String displayName;
  final String pinHash;
  final String? activeBusinessId;
  final DateTime lastLoginAt;
  final bool isCurrentlyActive;
  const LocalUserProfile({
    required this.userId,
    required this.phone,
    required this.displayName,
    required this.pinHash,
    this.activeBusinessId,
    required this.lastLoginAt,
    required this.isCurrentlyActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['phone'] = Variable<String>(phone);
    map['display_name'] = Variable<String>(displayName);
    map['pin_hash'] = Variable<String>(pinHash);
    if (!nullToAbsent || activeBusinessId != null) {
      map['active_business_id'] = Variable<String>(activeBusinessId);
    }
    map['last_login_at'] = Variable<DateTime>(lastLoginAt);
    map['is_currently_active'] = Variable<bool>(isCurrentlyActive);
    return map;
  }

  LocalUserProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalUserProfilesCompanion(
      userId: Value(userId),
      phone: Value(phone),
      displayName: Value(displayName),
      pinHash: Value(pinHash),
      activeBusinessId: activeBusinessId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeBusinessId),
      lastLoginAt: Value(lastLoginAt),
      isCurrentlyActive: Value(isCurrentlyActive),
    );
  }

  factory LocalUserProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUserProfile(
      userId: serializer.fromJson<String>(json['userId']),
      phone: serializer.fromJson<String>(json['phone']),
      displayName: serializer.fromJson<String>(json['displayName']),
      pinHash: serializer.fromJson<String>(json['pinHash']),
      activeBusinessId: serializer.fromJson<String?>(json['activeBusinessId']),
      lastLoginAt: serializer.fromJson<DateTime>(json['lastLoginAt']),
      isCurrentlyActive: serializer.fromJson<bool>(json['isCurrentlyActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'phone': serializer.toJson<String>(phone),
      'displayName': serializer.toJson<String>(displayName),
      'pinHash': serializer.toJson<String>(pinHash),
      'activeBusinessId': serializer.toJson<String?>(activeBusinessId),
      'lastLoginAt': serializer.toJson<DateTime>(lastLoginAt),
      'isCurrentlyActive': serializer.toJson<bool>(isCurrentlyActive),
    };
  }

  LocalUserProfile copyWith({
    String? userId,
    String? phone,
    String? displayName,
    String? pinHash,
    Value<String?> activeBusinessId = const Value.absent(),
    DateTime? lastLoginAt,
    bool? isCurrentlyActive,
  }) => LocalUserProfile(
    userId: userId ?? this.userId,
    phone: phone ?? this.phone,
    displayName: displayName ?? this.displayName,
    pinHash: pinHash ?? this.pinHash,
    activeBusinessId: activeBusinessId.present
        ? activeBusinessId.value
        : this.activeBusinessId,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    isCurrentlyActive: isCurrentlyActive ?? this.isCurrentlyActive,
  );
  LocalUserProfile copyWithCompanion(LocalUserProfilesCompanion data) {
    return LocalUserProfile(
      userId: data.userId.present ? data.userId.value : this.userId,
      phone: data.phone.present ? data.phone.value : this.phone,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      activeBusinessId: data.activeBusinessId.present
          ? data.activeBusinessId.value
          : this.activeBusinessId,
      lastLoginAt: data.lastLoginAt.present
          ? data.lastLoginAt.value
          : this.lastLoginAt,
      isCurrentlyActive: data.isCurrentlyActive.present
          ? data.isCurrentlyActive.value
          : this.isCurrentlyActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUserProfile(')
          ..write('userId: $userId, ')
          ..write('phone: $phone, ')
          ..write('displayName: $displayName, ')
          ..write('pinHash: $pinHash, ')
          ..write('activeBusinessId: $activeBusinessId, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('isCurrentlyActive: $isCurrentlyActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    phone,
    displayName,
    pinHash,
    activeBusinessId,
    lastLoginAt,
    isCurrentlyActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUserProfile &&
          other.userId == this.userId &&
          other.phone == this.phone &&
          other.displayName == this.displayName &&
          other.pinHash == this.pinHash &&
          other.activeBusinessId == this.activeBusinessId &&
          other.lastLoginAt == this.lastLoginAt &&
          other.isCurrentlyActive == this.isCurrentlyActive);
}

class LocalUserProfilesCompanion extends UpdateCompanion<LocalUserProfile> {
  final Value<String> userId;
  final Value<String> phone;
  final Value<String> displayName;
  final Value<String> pinHash;
  final Value<String?> activeBusinessId;
  final Value<DateTime> lastLoginAt;
  final Value<bool> isCurrentlyActive;
  final Value<int> rowid;
  const LocalUserProfilesCompanion({
    this.userId = const Value.absent(),
    this.phone = const Value.absent(),
    this.displayName = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.activeBusinessId = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.isCurrentlyActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUserProfilesCompanion.insert({
    required String userId,
    required String phone,
    required String displayName,
    required String pinHash,
    this.activeBusinessId = const Value.absent(),
    required DateTime lastLoginAt,
    this.isCurrentlyActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       phone = Value(phone),
       displayName = Value(displayName),
       pinHash = Value(pinHash),
       lastLoginAt = Value(lastLoginAt);
  static Insertable<LocalUserProfile> custom({
    Expression<String>? userId,
    Expression<String>? phone,
    Expression<String>? displayName,
    Expression<String>? pinHash,
    Expression<String>? activeBusinessId,
    Expression<DateTime>? lastLoginAt,
    Expression<bool>? isCurrentlyActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (phone != null) 'phone': phone,
      if (displayName != null) 'display_name': displayName,
      if (pinHash != null) 'pin_hash': pinHash,
      if (activeBusinessId != null) 'active_business_id': activeBusinessId,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
      if (isCurrentlyActive != null) 'is_currently_active': isCurrentlyActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUserProfilesCompanion copyWith({
    Value<String>? userId,
    Value<String>? phone,
    Value<String>? displayName,
    Value<String>? pinHash,
    Value<String?>? activeBusinessId,
    Value<DateTime>? lastLoginAt,
    Value<bool>? isCurrentlyActive,
    Value<int>? rowid,
  }) {
    return LocalUserProfilesCompanion(
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      pinHash: pinHash ?? this.pinHash,
      activeBusinessId: activeBusinessId ?? this.activeBusinessId,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isCurrentlyActive: isCurrentlyActive ?? this.isCurrentlyActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (activeBusinessId.present) {
      map['active_business_id'] = Variable<String>(activeBusinessId.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt.value);
    }
    if (isCurrentlyActive.present) {
      map['is_currently_active'] = Variable<bool>(isCurrentlyActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUserProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('phone: $phone, ')
          ..write('displayName: $displayName, ')
          ..write('pinHash: $pinHash, ')
          ..write('activeBusinessId: $activeBusinessId, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('isCurrentlyActive: $isCurrentlyActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedBusinessContextsTable extends CachedBusinessContexts
    with TableInfo<$CachedBusinessContextsTable, CachedBusinessContext> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedBusinessContextsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> roleNames =
      GeneratedColumn<String>(
        'role_names',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>(
        $CachedBusinessContextsTable.$converterroleNames,
      );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  permissions =
      GeneratedColumn<String>(
        'permissions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>(
        $CachedBusinessContextsTable.$converterpermissions,
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
    businessId,
    businessName,
    displayName,
    phone,
    email,
    address,
    currencyCode,
    roleNames,
    permissions,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_business_contexts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedBusinessContext> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
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
  Set<GeneratedColumn> get $primaryKey => {businessId};
  @override
  CachedBusinessContext map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedBusinessContext(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      roleNames: $CachedBusinessContextsTable.$converterroleNames.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role_names'],
        )!,
      ),
      permissions: $CachedBusinessContextsTable.$converterpermissions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}permissions'],
        )!,
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedBusinessContextsTable createAlias(String alias) {
    return $CachedBusinessContextsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterroleNames =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterpermissions =
      const StringListConverter();
}

class CachedBusinessContext extends DataClass
    implements Insertable<CachedBusinessContext> {
  final String businessId;
  final String businessName;
  final String displayName;
  final String phone;
  final String email;
  final String address;
  final String currencyCode;
  final List<String> roleNames;
  final List<String> permissions;
  final DateTime cachedAt;
  const CachedBusinessContext({
    required this.businessId,
    required this.businessName,
    required this.displayName,
    required this.phone,
    required this.email,
    required this.address,
    required this.currencyCode,
    required this.roleNames,
    required this.permissions,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['business_id'] = Variable<String>(businessId);
    map['business_name'] = Variable<String>(businessName);
    map['display_name'] = Variable<String>(displayName);
    map['phone'] = Variable<String>(phone);
    map['email'] = Variable<String>(email);
    map['address'] = Variable<String>(address);
    map['currency_code'] = Variable<String>(currencyCode);
    {
      map['role_names'] = Variable<String>(
        $CachedBusinessContextsTable.$converterroleNames.toSql(roleNames),
      );
    }
    {
      map['permissions'] = Variable<String>(
        $CachedBusinessContextsTable.$converterpermissions.toSql(permissions),
      );
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedBusinessContextsCompanion toCompanion(bool nullToAbsent) {
    return CachedBusinessContextsCompanion(
      businessId: Value(businessId),
      businessName: Value(businessName),
      displayName: Value(displayName),
      phone: Value(phone),
      email: Value(email),
      address: Value(address),
      currencyCode: Value(currencyCode),
      roleNames: Value(roleNames),
      permissions: Value(permissions),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedBusinessContext.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedBusinessContext(
      businessId: serializer.fromJson<String>(json['businessId']),
      businessName: serializer.fromJson<String>(json['businessName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      phone: serializer.fromJson<String>(json['phone']),
      email: serializer.fromJson<String>(json['email']),
      address: serializer.fromJson<String>(json['address']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      roleNames: serializer.fromJson<List<String>>(json['roleNames']),
      permissions: serializer.fromJson<List<String>>(json['permissions']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'businessId': serializer.toJson<String>(businessId),
      'businessName': serializer.toJson<String>(businessName),
      'displayName': serializer.toJson<String>(displayName),
      'phone': serializer.toJson<String>(phone),
      'email': serializer.toJson<String>(email),
      'address': serializer.toJson<String>(address),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'roleNames': serializer.toJson<List<String>>(roleNames),
      'permissions': serializer.toJson<List<String>>(permissions),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedBusinessContext copyWith({
    String? businessId,
    String? businessName,
    String? displayName,
    String? phone,
    String? email,
    String? address,
    String? currencyCode,
    List<String>? roleNames,
    List<String>? permissions,
    DateTime? cachedAt,
  }) => CachedBusinessContext(
    businessId: businessId ?? this.businessId,
    businessName: businessName ?? this.businessName,
    displayName: displayName ?? this.displayName,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    currencyCode: currencyCode ?? this.currencyCode,
    roleNames: roleNames ?? this.roleNames,
    permissions: permissions ?? this.permissions,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedBusinessContext copyWithCompanion(
    CachedBusinessContextsCompanion data,
  ) {
    return CachedBusinessContext(
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      roleNames: data.roleNames.present ? data.roleNames.value : this.roleNames,
      permissions: data.permissions.present
          ? data.permissions.value
          : this.permissions,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedBusinessContext(')
          ..write('businessId: $businessId, ')
          ..write('businessName: $businessName, ')
          ..write('displayName: $displayName, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('roleNames: $roleNames, ')
          ..write('permissions: $permissions, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    businessId,
    businessName,
    displayName,
    phone,
    email,
    address,
    currencyCode,
    roleNames,
    permissions,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedBusinessContext &&
          other.businessId == this.businessId &&
          other.businessName == this.businessName &&
          other.displayName == this.displayName &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.currencyCode == this.currencyCode &&
          other.roleNames == this.roleNames &&
          other.permissions == this.permissions &&
          other.cachedAt == this.cachedAt);
}

class CachedBusinessContextsCompanion
    extends UpdateCompanion<CachedBusinessContext> {
  final Value<String> businessId;
  final Value<String> businessName;
  final Value<String> displayName;
  final Value<String> phone;
  final Value<String> email;
  final Value<String> address;
  final Value<String> currencyCode;
  final Value<List<String>> roleNames;
  final Value<List<String>> permissions;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedBusinessContextsCompanion({
    this.businessId = const Value.absent(),
    this.businessName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.roleNames = const Value.absent(),
    this.permissions = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedBusinessContextsCompanion.insert({
    required String businessId,
    required String businessName,
    required String displayName,
    required String phone,
    required String email,
    required String address,
    required String currencyCode,
    this.roleNames = const Value.absent(),
    this.permissions = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       businessName = Value(businessName),
       displayName = Value(displayName),
       phone = Value(phone),
       email = Value(email),
       address = Value(address),
       currencyCode = Value(currencyCode),
       cachedAt = Value(cachedAt);
  static Insertable<CachedBusinessContext> custom({
    Expression<String>? businessId,
    Expression<String>? businessName,
    Expression<String>? displayName,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? currencyCode,
    Expression<String>? roleNames,
    Expression<String>? permissions,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (businessId != null) 'business_id': businessId,
      if (businessName != null) 'business_name': businessName,
      if (displayName != null) 'display_name': displayName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (roleNames != null) 'role_names': roleNames,
      if (permissions != null) 'permissions': permissions,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedBusinessContextsCompanion copyWith({
    Value<String>? businessId,
    Value<String>? businessName,
    Value<String>? displayName,
    Value<String>? phone,
    Value<String>? email,
    Value<String>? address,
    Value<String>? currencyCode,
    Value<List<String>>? roleNames,
    Value<List<String>>? permissions,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedBusinessContextsCompanion(
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      currencyCode: currencyCode ?? this.currencyCode,
      roleNames: roleNames ?? this.roleNames,
      permissions: permissions ?? this.permissions,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (roleNames.present) {
      map['role_names'] = Variable<String>(
        $CachedBusinessContextsTable.$converterroleNames.toSql(roleNames.value),
      );
    }
    if (permissions.present) {
      map['permissions'] = Variable<String>(
        $CachedBusinessContextsTable.$converterpermissions.toSql(
          permissions.value,
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
    return (StringBuffer('CachedBusinessContextsCompanion(')
          ..write('businessId: $businessId, ')
          ..write('businessName: $businessName, ')
          ..write('displayName: $displayName, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('roleNames: $roleNames, ')
          ..write('permissions: $permissions, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
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
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
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
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<int> unitPrice = GeneratedColumn<int>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockOnHandMeta = const VerificationMeta(
    'stockOnHand',
  );
  @override
  late final GeneratedColumn<int> stockOnHand = GeneratedColumn<int>(
    'stock_on_hand',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    businessId,
    name,
    category,
    unit,
    unitPrice,
    stockOnHand,
    cachedAt,
    isAvailable,
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
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('stock_on_hand')) {
      context.handle(
        _stockOnHandMeta,
        stockOnHand.isAcceptableOrUnknown(
          data['stock_on_hand']!,
          _stockOnHandMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  CachedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedItem(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price'],
      )!,
      stockOnHand: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_on_hand'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      isAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available'],
      )!,
    );
  }

  @override
  $CachedItemsTable createAlias(String alias) {
    return $CachedItemsTable(attachedDatabase, alias);
  }
}

class CachedItem extends DataClass implements Insertable<CachedItem> {
  final String itemId;
  final String businessId;
  final String name;
  final String category;
  final String unit;

  /// BACKEND-GAP FLAG (Stage-2): The POS Service API returns
  /// BigDecimal/numeric for unit_price, but we store it as Int64
  /// micro-units (smallest currency unit, e.g. pesewas for GHS).
  ///
  /// This cast is SAFE while ALL supported currencies use 0 or 2
  /// decimal places AND unit_price is always a whole number of
  /// micro-units.  If the backend ever transmits fractional amounts
  /// (e.g. 0.350 GHS per piece) the repository layer MUST apply a
  /// scaling cast — or we add a redundant TEXT/decimal column here.
  final int unitPrice;
  final int stockOnHand;
  final DateTime cachedAt;
  final bool isAvailable;
  const CachedItem({
    required this.itemId,
    required this.businessId,
    required this.name,
    required this.category,
    required this.unit,
    required this.unitPrice,
    required this.stockOnHand,
    required this.cachedAt,
    required this.isAvailable,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['unit'] = Variable<String>(unit);
    map['unit_price'] = Variable<int>(unitPrice);
    map['stock_on_hand'] = Variable<int>(stockOnHand);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['is_available'] = Variable<bool>(isAvailable);
    return map;
  }

  CachedItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedItemsCompanion(
      itemId: Value(itemId),
      businessId: Value(businessId),
      name: Value(name),
      category: Value(category),
      unit: Value(unit),
      unitPrice: Value(unitPrice),
      stockOnHand: Value(stockOnHand),
      cachedAt: Value(cachedAt),
      isAvailable: Value(isAvailable),
    );
  }

  factory CachedItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedItem(
      itemId: serializer.fromJson<String>(json['itemId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      unit: serializer.fromJson<String>(json['unit']),
      unitPrice: serializer.fromJson<int>(json['unitPrice']),
      stockOnHand: serializer.fromJson<int>(json['stockOnHand']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'unit': serializer.toJson<String>(unit),
      'unitPrice': serializer.toJson<int>(unitPrice),
      'stockOnHand': serializer.toJson<int>(stockOnHand),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'isAvailable': serializer.toJson<bool>(isAvailable),
    };
  }

  CachedItem copyWith({
    String? itemId,
    String? businessId,
    String? name,
    String? category,
    String? unit,
    int? unitPrice,
    int? stockOnHand,
    DateTime? cachedAt,
    bool? isAvailable,
  }) => CachedItem(
    itemId: itemId ?? this.itemId,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    category: category ?? this.category,
    unit: unit ?? this.unit,
    unitPrice: unitPrice ?? this.unitPrice,
    stockOnHand: stockOnHand ?? this.stockOnHand,
    cachedAt: cachedAt ?? this.cachedAt,
    isAvailable: isAvailable ?? this.isAvailable,
  );
  CachedItem copyWithCompanion(CachedItemsCompanion data) {
    return CachedItem(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      stockOnHand: data.stockOnHand.present
          ? data.stockOnHand.value
          : this.stockOnHand,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      isAvailable: data.isAvailable.present
          ? data.isAvailable.value
          : this.isAvailable,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedItem(')
          ..write('itemId: $itemId, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('stockOnHand: $stockOnHand, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('isAvailable: $isAvailable')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    itemId,
    businessId,
    name,
    category,
    unit,
    unitPrice,
    stockOnHand,
    cachedAt,
    isAvailable,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedItem &&
          other.itemId == this.itemId &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.category == this.category &&
          other.unit == this.unit &&
          other.unitPrice == this.unitPrice &&
          other.stockOnHand == this.stockOnHand &&
          other.cachedAt == this.cachedAt &&
          other.isAvailable == this.isAvailable);
}

class CachedItemsCompanion extends UpdateCompanion<CachedItem> {
  final Value<String> itemId;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String> category;
  final Value<String> unit;
  final Value<int> unitPrice;
  final Value<int> stockOnHand;
  final Value<DateTime> cachedAt;
  final Value<bool> isAvailable;
  final Value<int> rowid;
  const CachedItemsCompanion({
    this.itemId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.stockOnHand = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedItemsCompanion.insert({
    required String itemId,
    required String businessId,
    required String name,
    required String category,
    required String unit,
    required int unitPrice,
    this.stockOnHand = const Value.absent(),
    required DateTime cachedAt,
    this.isAvailable = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       businessId = Value(businessId),
       name = Value(name),
       category = Value(category),
       unit = Value(unit),
       unitPrice = Value(unitPrice),
       cachedAt = Value(cachedAt);
  static Insertable<CachedItem> custom({
    Expression<String>? itemId,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? unit,
    Expression<int>? unitPrice,
    Expression<int>? stockOnHand,
    Expression<DateTime>? cachedAt,
    Expression<bool>? isAvailable,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (unit != null) 'unit': unit,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (stockOnHand != null) 'stock_on_hand': stockOnHand,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (isAvailable != null) 'is_available': isAvailable,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedItemsCompanion copyWith({
    Value<String>? itemId,
    Value<String>? businessId,
    Value<String>? name,
    Value<String>? category,
    Value<String>? unit,
    Value<int>? unitPrice,
    Value<int>? stockOnHand,
    Value<DateTime>? cachedAt,
    Value<bool>? isAvailable,
    Value<int>? rowid,
  }) {
    return CachedItemsCompanion(
      itemId: itemId ?? this.itemId,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      stockOnHand: stockOnHand ?? this.stockOnHand,
      cachedAt: cachedAt ?? this.cachedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<int>(unitPrice.value);
    }
    if (stockOnHand.present) {
      map['stock_on_hand'] = Variable<int>(stockOnHand.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedItemsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('stockOnHand: $stockOnHand, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('rowid: $rowid')
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceSequenceMeta = const VerificationMeta(
    'deviceSequence',
  );
  @override
  late final GeneratedColumn<int> deviceSequence = GeneratedColumn<int>(
    'device_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientSaleId,
    businessId,
    userId,
    deviceSequence,
    createdAt,
    updatedAt,
    status,
    note,
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
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_sequence')) {
      context.handle(
        _deviceSequenceMeta,
        deviceSequence.isAcceptableOrUnknown(
          data['device_sequence']!,
          _deviceSequenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceSequenceMeta);
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientSaleId};
  @override
  PendingSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSale(
      clientSaleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_sale_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      deviceSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_sequence'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $PendingSalesTable createAlias(String alias) {
    return $PendingSalesTable(attachedDatabase, alias);
  }
}

class PendingSale extends DataClass implements Insertable<PendingSale> {
  final String clientSaleId;
  final String businessId;
  final String userId;
  final int deviceSequence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String? note;
  const PendingSale({
    required this.clientSaleId,
    required this.businessId,
    required this.userId,
    required this.deviceSequence,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_sale_id'] = Variable<String>(clientSaleId);
    map['business_id'] = Variable<String>(businessId);
    map['user_id'] = Variable<String>(userId);
    map['device_sequence'] = Variable<int>(deviceSequence);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  PendingSalesCompanion toCompanion(bool nullToAbsent) {
    return PendingSalesCompanion(
      clientSaleId: Value(clientSaleId),
      businessId: Value(businessId),
      userId: Value(userId),
      deviceSequence: Value(deviceSequence),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      status: Value(status),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory PendingSale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSale(
      clientSaleId: serializer.fromJson<String>(json['clientSaleId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      userId: serializer.fromJson<String>(json['userId']),
      deviceSequence: serializer.fromJson<int>(json['deviceSequence']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientSaleId': serializer.toJson<String>(clientSaleId),
      'businessId': serializer.toJson<String>(businessId),
      'userId': serializer.toJson<String>(userId),
      'deviceSequence': serializer.toJson<int>(deviceSequence),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String?>(note),
    };
  }

  PendingSale copyWith({
    String? clientSaleId,
    String? businessId,
    String? userId,
    int? deviceSequence,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    Value<String?> note = const Value.absent(),
  }) => PendingSale(
    clientSaleId: clientSaleId ?? this.clientSaleId,
    businessId: businessId ?? this.businessId,
    userId: userId ?? this.userId,
    deviceSequence: deviceSequence ?? this.deviceSequence,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    status: status ?? this.status,
    note: note.present ? note.value : this.note,
  );
  PendingSale copyWithCompanion(PendingSalesCompanion data) {
    return PendingSale(
      clientSaleId: data.clientSaleId.present
          ? data.clientSaleId.value
          : this.clientSaleId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceSequence: data.deviceSequence.present
          ? data.deviceSequence.value
          : this.deviceSequence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSale(')
          ..write('clientSaleId: $clientSaleId, ')
          ..write('businessId: $businessId, ')
          ..write('userId: $userId, ')
          ..write('deviceSequence: $deviceSequence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientSaleId,
    businessId,
    userId,
    deviceSequence,
    createdAt,
    updatedAt,
    status,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSale &&
          other.clientSaleId == this.clientSaleId &&
          other.businessId == this.businessId &&
          other.userId == this.userId &&
          other.deviceSequence == this.deviceSequence &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.status == this.status &&
          other.note == this.note);
}

class PendingSalesCompanion extends UpdateCompanion<PendingSale> {
  final Value<String> clientSaleId;
  final Value<String> businessId;
  final Value<String> userId;
  final Value<int> deviceSequence;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> status;
  final Value<String?> note;
  final Value<int> rowid;
  const PendingSalesCompanion({
    this.clientSaleId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceSequence = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingSalesCompanion.insert({
    required String clientSaleId,
    required String businessId,
    required String userId,
    required int deviceSequence,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientSaleId = Value(clientSaleId),
       businessId = Value(businessId),
       userId = Value(userId),
       deviceSequence = Value(deviceSequence),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PendingSale> custom({
    Expression<String>? clientSaleId,
    Expression<String>? businessId,
    Expression<String>? userId,
    Expression<int>? deviceSequence,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? status,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientSaleId != null) 'client_sale_id': clientSaleId,
      if (businessId != null) 'business_id': businessId,
      if (userId != null) 'user_id': userId,
      if (deviceSequence != null) 'device_sequence': deviceSequence,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingSalesCompanion copyWith({
    Value<String>? clientSaleId,
    Value<String>? businessId,
    Value<String>? userId,
    Value<int>? deviceSequence,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? status,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return PendingSalesCompanion(
      clientSaleId: clientSaleId ?? this.clientSaleId,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      deviceSequence: deviceSequence ?? this.deviceSequence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientSaleId.present) {
      map['client_sale_id'] = Variable<String>(clientSaleId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deviceSequence.present) {
      map['device_sequence'] = Variable<int>(deviceSequence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSalesCompanion(')
          ..write('clientSaleId: $clientSaleId, ')
          ..write('businessId: $businessId, ')
          ..write('userId: $userId, ')
          ..write('deviceSequence: $deviceSequence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pending_sales (client_sale_id)',
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_items (item_id)',
    ),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceAtSaleMeta = const VerificationMeta(
    'unitPriceAtSale',
  );
  @override
  late final GeneratedColumn<int> unitPriceAtSale = GeneratedColumn<int>(
    'unit_price_at_sale',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    itemId,
    quantity,
    unitPriceAtSale,
    createdAt,
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
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price_at_sale')) {
      context.handle(
        _unitPriceAtSaleMeta,
        unitPriceAtSale.isAcceptableOrUnknown(
          data['unit_price_at_sale']!,
          _unitPriceAtSaleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPriceAtSaleMeta);
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
  PendingSaleLineItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSaleLineItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientSaleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_sale_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitPriceAtSale: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_at_sale'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingSaleLineItemsTable createAlias(String alias) {
    return $PendingSaleLineItemsTable(attachedDatabase, alias);
  }
}

class PendingSaleLineItem extends DataClass
    implements Insertable<PendingSaleLineItem> {
  final int id;
  final String clientSaleId;
  final String itemId;
  final int quantity;
  final int unitPriceAtSale;
  final DateTime createdAt;
  const PendingSaleLineItem({
    required this.id,
    required this.clientSaleId,
    required this.itemId,
    required this.quantity,
    required this.unitPriceAtSale,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_sale_id'] = Variable<String>(clientSaleId);
    map['item_id'] = Variable<String>(itemId);
    map['quantity'] = Variable<int>(quantity);
    map['unit_price_at_sale'] = Variable<int>(unitPriceAtSale);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingSaleLineItemsCompanion toCompanion(bool nullToAbsent) {
    return PendingSaleLineItemsCompanion(
      id: Value(id),
      clientSaleId: Value(clientSaleId),
      itemId: Value(itemId),
      quantity: Value(quantity),
      unitPriceAtSale: Value(unitPriceAtSale),
      createdAt: Value(createdAt),
    );
  }

  factory PendingSaleLineItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSaleLineItem(
      id: serializer.fromJson<int>(json['id']),
      clientSaleId: serializer.fromJson<String>(json['clientSaleId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitPriceAtSale: serializer.fromJson<int>(json['unitPriceAtSale']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientSaleId': serializer.toJson<String>(clientSaleId),
      'itemId': serializer.toJson<String>(itemId),
      'quantity': serializer.toJson<int>(quantity),
      'unitPriceAtSale': serializer.toJson<int>(unitPriceAtSale),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingSaleLineItem copyWith({
    int? id,
    String? clientSaleId,
    String? itemId,
    int? quantity,
    int? unitPriceAtSale,
    DateTime? createdAt,
  }) => PendingSaleLineItem(
    id: id ?? this.id,
    clientSaleId: clientSaleId ?? this.clientSaleId,
    itemId: itemId ?? this.itemId,
    quantity: quantity ?? this.quantity,
    unitPriceAtSale: unitPriceAtSale ?? this.unitPriceAtSale,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingSaleLineItem copyWithCompanion(PendingSaleLineItemsCompanion data) {
    return PendingSaleLineItem(
      id: data.id.present ? data.id.value : this.id,
      clientSaleId: data.clientSaleId.present
          ? data.clientSaleId.value
          : this.clientSaleId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPriceAtSale: data.unitPriceAtSale.present
          ? data.unitPriceAtSale.value
          : this.unitPriceAtSale,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSaleLineItem(')
          ..write('id: $id, ')
          ..write('clientSaleId: $clientSaleId, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPriceAtSale: $unitPriceAtSale, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientSaleId,
    itemId,
    quantity,
    unitPriceAtSale,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSaleLineItem &&
          other.id == this.id &&
          other.clientSaleId == this.clientSaleId &&
          other.itemId == this.itemId &&
          other.quantity == this.quantity &&
          other.unitPriceAtSale == this.unitPriceAtSale &&
          other.createdAt == this.createdAt);
}

class PendingSaleLineItemsCompanion
    extends UpdateCompanion<PendingSaleLineItem> {
  final Value<int> id;
  final Value<String> clientSaleId;
  final Value<String> itemId;
  final Value<int> quantity;
  final Value<int> unitPriceAtSale;
  final Value<DateTime> createdAt;
  const PendingSaleLineItemsCompanion({
    this.id = const Value.absent(),
    this.clientSaleId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPriceAtSale = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingSaleLineItemsCompanion.insert({
    this.id = const Value.absent(),
    required String clientSaleId,
    required String itemId,
    required int quantity,
    required int unitPriceAtSale,
    required DateTime createdAt,
  }) : clientSaleId = Value(clientSaleId),
       itemId = Value(itemId),
       quantity = Value(quantity),
       unitPriceAtSale = Value(unitPriceAtSale),
       createdAt = Value(createdAt);
  static Insertable<PendingSaleLineItem> custom({
    Expression<int>? id,
    Expression<String>? clientSaleId,
    Expression<String>? itemId,
    Expression<int>? quantity,
    Expression<int>? unitPriceAtSale,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientSaleId != null) 'client_sale_id': clientSaleId,
      if (itemId != null) 'item_id': itemId,
      if (quantity != null) 'quantity': quantity,
      if (unitPriceAtSale != null) 'unit_price_at_sale': unitPriceAtSale,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingSaleLineItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? clientSaleId,
    Value<String>? itemId,
    Value<int>? quantity,
    Value<int>? unitPriceAtSale,
    Value<DateTime>? createdAt,
  }) {
    return PendingSaleLineItemsCompanion(
      id: id ?? this.id,
      clientSaleId: clientSaleId ?? this.clientSaleId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      unitPriceAtSale: unitPriceAtSale ?? this.unitPriceAtSale,
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
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPriceAtSale.present) {
      map['unit_price_at_sale'] = Variable<int>(unitPriceAtSale.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSaleLineItemsCompanion(')
          ..write('id: $id, ')
          ..write('clientSaleId: $clientSaleId, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPriceAtSale: $unitPriceAtSale, ')
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
  late final $CachedBusinessContextsTable cachedBusinessContexts =
      $CachedBusinessContextsTable(this);
  late final $CachedItemsTable cachedItems = $CachedItemsTable(this);
  late final $PendingSalesTable pendingSales = $PendingSalesTable(this);
  late final $PendingSaleLineItemsTable pendingSaleLineItems =
      $PendingSaleLineItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localUserProfiles,
    cachedBusinessContexts,
    cachedItems,
    pendingSales,
    pendingSaleLineItems,
  ];
}

typedef $$LocalUserProfilesTableCreateCompanionBuilder =
    LocalUserProfilesCompanion Function({
      required String userId,
      required String phone,
      required String displayName,
      required String pinHash,
      Value<String?> activeBusinessId,
      required DateTime lastLoginAt,
      Value<bool> isCurrentlyActive,
      Value<int> rowid,
    });
typedef $$LocalUserProfilesTableUpdateCompanionBuilder =
    LocalUserProfilesCompanion Function({
      Value<String> userId,
      Value<String> phone,
      Value<String> displayName,
      Value<String> pinHash,
      Value<String?> activeBusinessId,
      Value<DateTime> lastLoginAt,
      Value<bool> isCurrentlyActive,
      Value<int> rowid,
    });

class $$LocalUserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalUserProfilesTable> {
  $$LocalUserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
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

  ColumnFilters<String> get activeBusinessId => $composableBuilder(
    column: $table.activeBusinessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrentlyActive => $composableBuilder(
    column: $table.isCurrentlyActive,
    builder: (column) => ColumnFilters(column),
  );
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
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
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

  ColumnOrderings<String> get activeBusinessId => $composableBuilder(
    column: $table.activeBusinessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrentlyActive => $composableBuilder(
    column: $table.isCurrentlyActive,
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
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<String> get activeBusinessId => $composableBuilder(
    column: $table.activeBusinessId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCurrentlyActive => $composableBuilder(
    column: $table.isCurrentlyActive,
    builder: (column) => column,
  );
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
          (
            LocalUserProfile,
            BaseReferences<
              _$AppDatabase,
              $LocalUserProfilesTable,
              LocalUserProfile
            >,
          ),
          LocalUserProfile,
          PrefetchHooks Function()
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
                Value<String> userId = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> pinHash = const Value.absent(),
                Value<String?> activeBusinessId = const Value.absent(),
                Value<DateTime> lastLoginAt = const Value.absent(),
                Value<bool> isCurrentlyActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUserProfilesCompanion(
                userId: userId,
                phone: phone,
                displayName: displayName,
                pinHash: pinHash,
                activeBusinessId: activeBusinessId,
                lastLoginAt: lastLoginAt,
                isCurrentlyActive: isCurrentlyActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String phone,
                required String displayName,
                required String pinHash,
                Value<String?> activeBusinessId = const Value.absent(),
                required DateTime lastLoginAt,
                Value<bool> isCurrentlyActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUserProfilesCompanion.insert(
                userId: userId,
                phone: phone,
                displayName: displayName,
                pinHash: pinHash,
                activeBusinessId: activeBusinessId,
                lastLoginAt: lastLoginAt,
                isCurrentlyActive: isCurrentlyActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        LocalUserProfile,
        BaseReferences<
          _$AppDatabase,
          $LocalUserProfilesTable,
          LocalUserProfile
        >,
      ),
      LocalUserProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedBusinessContextsTableCreateCompanionBuilder =
    CachedBusinessContextsCompanion Function({
      required String businessId,
      required String businessName,
      required String displayName,
      required String phone,
      required String email,
      required String address,
      required String currencyCode,
      Value<List<String>> roleNames,
      Value<List<String>> permissions,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedBusinessContextsTableUpdateCompanionBuilder =
    CachedBusinessContextsCompanion Function({
      Value<String> businessId,
      Value<String> businessName,
      Value<String> displayName,
      Value<String> phone,
      Value<String> email,
      Value<String> address,
      Value<String> currencyCode,
      Value<List<String>> roleNames,
      Value<List<String>> permissions,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedBusinessContextsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedBusinessContextsTable> {
  $$CachedBusinessContextsTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get roleNames => $composableBuilder(
    column: $table.roleNames,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedBusinessContextsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedBusinessContextsTable> {
  $$CachedBusinessContextsTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleNames => $composableBuilder(
    column: $table.roleNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissions => $composableBuilder(
    column: $table.permissions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedBusinessContextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedBusinessContextsTable> {
  $$CachedBusinessContextsTableAnnotationComposer({
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

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get roleNames =>
      $composableBuilder(column: $table.roleNames, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get permissions =>
      $composableBuilder(
        column: $table.permissions,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedBusinessContextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedBusinessContextsTable,
          CachedBusinessContext,
          $$CachedBusinessContextsTableFilterComposer,
          $$CachedBusinessContextsTableOrderingComposer,
          $$CachedBusinessContextsTableAnnotationComposer,
          $$CachedBusinessContextsTableCreateCompanionBuilder,
          $$CachedBusinessContextsTableUpdateCompanionBuilder,
          (
            CachedBusinessContext,
            BaseReferences<
              _$AppDatabase,
              $CachedBusinessContextsTable,
              CachedBusinessContext
            >,
          ),
          CachedBusinessContext,
          PrefetchHooks Function()
        > {
  $$CachedBusinessContextsTableTableManager(
    _$AppDatabase db,
    $CachedBusinessContextsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedBusinessContextsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedBusinessContextsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedBusinessContextsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> businessId = const Value.absent(),
                Value<String> businessName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<List<String>> roleNames = const Value.absent(),
                Value<List<String>> permissions = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedBusinessContextsCompanion(
                businessId: businessId,
                businessName: businessName,
                displayName: displayName,
                phone: phone,
                email: email,
                address: address,
                currencyCode: currencyCode,
                roleNames: roleNames,
                permissions: permissions,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String businessId,
                required String businessName,
                required String displayName,
                required String phone,
                required String email,
                required String address,
                required String currencyCode,
                Value<List<String>> roleNames = const Value.absent(),
                Value<List<String>> permissions = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedBusinessContextsCompanion.insert(
                businessId: businessId,
                businessName: businessName,
                displayName: displayName,
                phone: phone,
                email: email,
                address: address,
                currencyCode: currencyCode,
                roleNames: roleNames,
                permissions: permissions,
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

typedef $$CachedBusinessContextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedBusinessContextsTable,
      CachedBusinessContext,
      $$CachedBusinessContextsTableFilterComposer,
      $$CachedBusinessContextsTableOrderingComposer,
      $$CachedBusinessContextsTableAnnotationComposer,
      $$CachedBusinessContextsTableCreateCompanionBuilder,
      $$CachedBusinessContextsTableUpdateCompanionBuilder,
      (
        CachedBusinessContext,
        BaseReferences<
          _$AppDatabase,
          $CachedBusinessContextsTable,
          CachedBusinessContext
        >,
      ),
      CachedBusinessContext,
      PrefetchHooks Function()
    >;
typedef $$CachedItemsTableCreateCompanionBuilder =
    CachedItemsCompanion Function({
      required String itemId,
      required String businessId,
      required String name,
      required String category,
      required String unit,
      required int unitPrice,
      Value<int> stockOnHand,
      required DateTime cachedAt,
      Value<bool> isAvailable,
      Value<int> rowid,
    });
typedef $$CachedItemsTableUpdateCompanionBuilder =
    CachedItemsCompanion Function({
      Value<String> itemId,
      Value<String> businessId,
      Value<String> name,
      Value<String> category,
      Value<String> unit,
      Value<int> unitPrice,
      Value<int> stockOnHand,
      Value<DateTime> cachedAt,
      Value<bool> isAvailable,
      Value<int> rowid,
    });

final class $$CachedItemsTableReferences
    extends BaseReferences<_$AppDatabase, $CachedItemsTable, CachedItem> {
  $$CachedItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $PendingSaleLineItemsTable,
    List<PendingSaleLineItem>
  >
  _pendingSaleLineItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pendingSaleLineItems,
        aliasName: 'cached_items__item_id__pending_sale_line_items__item_id',
      );

  $$PendingSaleLineItemsTableProcessedTableManager
  get pendingSaleLineItemsRefs {
    final manager =
        $$PendingSaleLineItemsTableTableManager(
          $_db,
          $_db.pendingSaleLineItems,
        ).filter(
          (f) => f.itemId.itemId.sqlEquals($_itemColumn<String>('item_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _pendingSaleLineItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedItemsTable> {
  $$CachedItemsTableFilterComposer({
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

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockOnHand => $composableBuilder(
    column: $table.stockOnHand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pendingSaleLineItemsRefs(
    Expression<bool> Function($$PendingSaleLineItemsTableFilterComposer f) f,
  ) {
    final $$PendingSaleLineItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.pendingSaleLineItems,
      getReferencedColumn: (t) => t.itemId,
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
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockOnHand => $composableBuilder(
    column: $table.stockOnHand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
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
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<int> get stockOnHand => $composableBuilder(
    column: $table.stockOnHand,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );

  Expression<T> pendingSaleLineItemsRefs<T extends Object>(
    Expression<T> Function($$PendingSaleLineItemsTableAnnotationComposer a) f,
  ) {
    final $$PendingSaleLineItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.itemId,
          referencedTable: $db.pendingSaleLineItems,
          getReferencedColumn: (t) => t.itemId,
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
          (CachedItem, $$CachedItemsTableReferences),
          CachedItem,
          PrefetchHooks Function({bool pendingSaleLineItemsRefs})
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
                Value<String> itemId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> unitPrice = const Value.absent(),
                Value<int> stockOnHand = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedItemsCompanion(
                itemId: itemId,
                businessId: businessId,
                name: name,
                category: category,
                unit: unit,
                unitPrice: unitPrice,
                stockOnHand: stockOnHand,
                cachedAt: cachedAt,
                isAvailable: isAvailable,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required String businessId,
                required String name,
                required String category,
                required String unit,
                required int unitPrice,
                Value<int> stockOnHand = const Value.absent(),
                required DateTime cachedAt,
                Value<bool> isAvailable = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedItemsCompanion.insert(
                itemId: itemId,
                businessId: businessId,
                name: name,
                category: category,
                unit: unit,
                unitPrice: unitPrice,
                stockOnHand: stockOnHand,
                cachedAt: cachedAt,
                isAvailable: isAvailable,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pendingSaleLineItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (pendingSaleLineItemsRefs) db.pendingSaleLineItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pendingSaleLineItemsRefs)
                    await $_getPrefetchedData<
                      CachedItem,
                      $CachedItemsTable,
                      PendingSaleLineItem
                    >(
                      currentTable: table,
                      referencedTable: $$CachedItemsTableReferences
                          ._pendingSaleLineItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CachedItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).pendingSaleLineItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.itemId == item.itemId),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
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
      (CachedItem, $$CachedItemsTableReferences),
      CachedItem,
      PrefetchHooks Function({bool pendingSaleLineItemsRefs})
    >;
typedef $$PendingSalesTableCreateCompanionBuilder =
    PendingSalesCompanion Function({
      required String clientSaleId,
      required String businessId,
      required String userId,
      required int deviceSequence,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String> status,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$PendingSalesTableUpdateCompanionBuilder =
    PendingSalesCompanion Function({
      Value<String> clientSaleId,
      Value<String> businessId,
      Value<String> userId,
      Value<int> deviceSequence,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> status,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$PendingSalesTableReferences
    extends BaseReferences<_$AppDatabase, $PendingSalesTable, PendingSale> {
  $$PendingSalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $PendingSaleLineItemsTable,
    List<PendingSaleLineItem>
  >
  _pendingSaleLineItemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.pendingSaleLineItems,
    aliasName:
        'pending_sales__client_sale_id__pending_sale_line_items__client_sale_id',
  );

  $$PendingSaleLineItemsTableProcessedTableManager
  get pendingSaleLineItemsRefs {
    final manager =
        $$PendingSaleLineItemsTableTableManager(
          $_db,
          $_db.pendingSaleLineItems,
        ).filter(
          (f) => f.clientSaleId.clientSaleId.sqlEquals(
            $_itemColumn<String>('client_sale_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _pendingSaleLineItemsRefsTable($_db),
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
  ColumnFilters<String> get clientSaleId => $composableBuilder(
    column: $table.clientSaleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceSequence => $composableBuilder(
    column: $table.deviceSequence,
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> pendingSaleLineItemsRefs(
    Expression<bool> Function($$PendingSaleLineItemsTableFilterComposer f) f,
  ) {
    final $$PendingSaleLineItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientSaleId,
      referencedTable: $db.pendingSaleLineItems,
      getReferencedColumn: (t) => t.clientSaleId,
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
  ColumnOrderings<String> get clientSaleId => $composableBuilder(
    column: $table.clientSaleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceSequence => $composableBuilder(
    column: $table.deviceSequence,
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
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
  GeneratedColumn<String> get clientSaleId => $composableBuilder(
    column: $table.clientSaleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get deviceSequence => $composableBuilder(
    column: $table.deviceSequence,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  Expression<T> pendingSaleLineItemsRefs<T extends Object>(
    Expression<T> Function($$PendingSaleLineItemsTableAnnotationComposer a) f,
  ) {
    final $$PendingSaleLineItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.clientSaleId,
          referencedTable: $db.pendingSaleLineItems,
          getReferencedColumn: (t) => t.clientSaleId,
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
          PrefetchHooks Function({bool pendingSaleLineItemsRefs})
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
                Value<String> clientSaleId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> deviceSequence = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingSalesCompanion(
                clientSaleId: clientSaleId,
                businessId: businessId,
                userId: userId,
                deviceSequence: deviceSequence,
                createdAt: createdAt,
                updatedAt: updatedAt,
                status: status,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientSaleId,
                required String businessId,
                required String userId,
                required int deviceSequence,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingSalesCompanion.insert(
                clientSaleId: clientSaleId,
                businessId: businessId,
                userId: userId,
                deviceSequence: deviceSequence,
                createdAt: createdAt,
                updatedAt: updatedAt,
                status: status,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PendingSalesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pendingSaleLineItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (pendingSaleLineItemsRefs) db.pendingSaleLineItems,
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
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.clientSaleId == item.clientSaleId,
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
      PrefetchHooks Function({bool pendingSaleLineItemsRefs})
    >;
typedef $$PendingSaleLineItemsTableCreateCompanionBuilder =
    PendingSaleLineItemsCompanion Function({
      Value<int> id,
      required String clientSaleId,
      required String itemId,
      required int quantity,
      required int unitPriceAtSale,
      required DateTime createdAt,
    });
typedef $$PendingSaleLineItemsTableUpdateCompanionBuilder =
    PendingSaleLineItemsCompanion Function({
      Value<int> id,
      Value<String> clientSaleId,
      Value<String> itemId,
      Value<int> quantity,
      Value<int> unitPriceAtSale,
      Value<DateTime> createdAt,
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

  static $PendingSalesTable _clientSaleIdTable(
    _$AppDatabase db,
  ) => db.pendingSales.createAlias(
    'pending_sale_line_items__client_sale_id__pending_sales__client_sale_id',
  );

  $$PendingSalesTableProcessedTableManager get clientSaleId {
    final $_column = $_itemColumn<String>('client_sale_id')!;

    final manager = $$PendingSalesTableTableManager(
      $_db,
      $_db.pendingSales,
    ).filter((f) => f.clientSaleId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clientSaleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CachedItemsTable _itemIdTable(_$AppDatabase db) => db.cachedItems
      .createAlias('pending_sale_line_items__item_id__cached_items__item_id');

  $$CachedItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$CachedItemsTableTableManager(
      $_db,
      $_db.cachedItems,
    ).filter((f) => f.itemId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
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

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceAtSale => $composableBuilder(
    column: $table.unitPriceAtSale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PendingSalesTableFilterComposer get clientSaleId {
    final $$PendingSalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientSaleId,
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

  $$CachedItemsTableFilterComposer get itemId {
    final $$CachedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.cachedItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedItemsTableFilterComposer(
            $db: $db,
            $table: $db.cachedItems,
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

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceAtSale => $composableBuilder(
    column: $table.unitPriceAtSale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PendingSalesTableOrderingComposer get clientSaleId {
    final $$PendingSalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientSaleId,
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

  $$CachedItemsTableOrderingComposer get itemId {
    final $$CachedItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.cachedItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedItemsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedItems,
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

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get unitPriceAtSale => $composableBuilder(
    column: $table.unitPriceAtSale,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PendingSalesTableAnnotationComposer get clientSaleId {
    final $$PendingSalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clientSaleId,
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

  $$CachedItemsTableAnnotationComposer get itemId {
    final $$CachedItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.cachedItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedItems,
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
          PrefetchHooks Function({bool clientSaleId, bool itemId})
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
                Value<String> clientSaleId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> unitPriceAtSale = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingSaleLineItemsCompanion(
                id: id,
                clientSaleId: clientSaleId,
                itemId: itemId,
                quantity: quantity,
                unitPriceAtSale: unitPriceAtSale,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientSaleId,
                required String itemId,
                required int quantity,
                required int unitPriceAtSale,
                required DateTime createdAt,
              }) => PendingSaleLineItemsCompanion.insert(
                id: id,
                clientSaleId: clientSaleId,
                itemId: itemId,
                quantity: quantity,
                unitPriceAtSale: unitPriceAtSale,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PendingSaleLineItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({clientSaleId = false, itemId = false}) {
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
                    if (clientSaleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.clientSaleId,
                                referencedTable:
                                    $$PendingSaleLineItemsTableReferences
                                        ._clientSaleIdTable(db),
                                referencedColumn:
                                    $$PendingSaleLineItemsTableReferences
                                        ._clientSaleIdTable(db)
                                        .clientSaleId,
                              )
                              as T;
                    }
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$PendingSaleLineItemsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$PendingSaleLineItemsTableReferences
                                        ._itemIdTable(db)
                                        .itemId,
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
      PrefetchHooks Function({bool clientSaleId, bool itemId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalUserProfilesTableTableManager get localUserProfiles =>
      $$LocalUserProfilesTableTableManager(_db, _db.localUserProfiles);
  $$CachedBusinessContextsTableTableManager get cachedBusinessContexts =>
      $$CachedBusinessContextsTableTableManager(
        _db,
        _db.cachedBusinessContexts,
      );
  $$CachedItemsTableTableManager get cachedItems =>
      $$CachedItemsTableTableManager(_db, _db.cachedItems);
  $$PendingSalesTableTableManager get pendingSales =>
      $$PendingSalesTableTableManager(_db, _db.pendingSales);
  $$PendingSaleLineItemsTableTableManager get pendingSaleLineItems =>
      $$PendingSaleLineItemsTableTableManager(_db, _db.pendingSaleLineItems);
}
