// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState()';
}


}

/// @nodoc
class $AuthStateCopyWith<$Res>  {
$AuthStateCopyWith(AuthState _, $Res Function(AuthState) __);
}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Unauthenticated value)?  unauthenticated,TResult Function( ProfilesAvailable value)?  profilesAvailable,TResult Function( SessionActive value)?  sessionActive,TResult Function( OnboardingRequired value)?  onboardingRequired,TResult Function( OtpPending value)?  otpPending,TResult Function( SettingPin value)?  settingPin,TResult Function( PinLockedOut value)?  pinLockedOut,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Unauthenticated() when unauthenticated != null:
return unauthenticated(_that);case ProfilesAvailable() when profilesAvailable != null:
return profilesAvailable(_that);case SessionActive() when sessionActive != null:
return sessionActive(_that);case OnboardingRequired() when onboardingRequired != null:
return onboardingRequired(_that);case OtpPending() when otpPending != null:
return otpPending(_that);case SettingPin() when settingPin != null:
return settingPin(_that);case PinLockedOut() when pinLockedOut != null:
return pinLockedOut(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Unauthenticated value)  unauthenticated,required TResult Function( ProfilesAvailable value)  profilesAvailable,required TResult Function( SessionActive value)  sessionActive,required TResult Function( OnboardingRequired value)  onboardingRequired,required TResult Function( OtpPending value)  otpPending,required TResult Function( SettingPin value)  settingPin,required TResult Function( PinLockedOut value)  pinLockedOut,}){
final _that = this;
switch (_that) {
case Unauthenticated():
return unauthenticated(_that);case ProfilesAvailable():
return profilesAvailable(_that);case SessionActive():
return sessionActive(_that);case OnboardingRequired():
return onboardingRequired(_that);case OtpPending():
return otpPending(_that);case SettingPin():
return settingPin(_that);case PinLockedOut():
return pinLockedOut(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Unauthenticated value)?  unauthenticated,TResult? Function( ProfilesAvailable value)?  profilesAvailable,TResult? Function( SessionActive value)?  sessionActive,TResult? Function( OnboardingRequired value)?  onboardingRequired,TResult? Function( OtpPending value)?  otpPending,TResult? Function( SettingPin value)?  settingPin,TResult? Function( PinLockedOut value)?  pinLockedOut,}){
final _that = this;
switch (_that) {
case Unauthenticated() when unauthenticated != null:
return unauthenticated(_that);case ProfilesAvailable() when profilesAvailable != null:
return profilesAvailable(_that);case SessionActive() when sessionActive != null:
return sessionActive(_that);case OnboardingRequired() when onboardingRequired != null:
return onboardingRequired(_that);case OtpPending() when otpPending != null:
return otpPending(_that);case SettingPin() when settingPin != null:
return settingPin(_that);case PinLockedOut() when pinLockedOut != null:
return pinLockedOut(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  unauthenticated,TResult Function( List<LocalUserProfile> profiles)?  profilesAvailable,TResult Function( LocalUserProfile profile,  bool locked)?  sessionActive,TResult Function( LocalUserProfile profile)?  onboardingRequired,TResult Function( String phone)?  otpPending,TResult Function( String phone,  String userId,  String refreshToken)?  settingPin,TResult Function( LocalUserProfile profile,  DateTime lockedUntil)?  pinLockedOut,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Unauthenticated() when unauthenticated != null:
return unauthenticated();case ProfilesAvailable() when profilesAvailable != null:
return profilesAvailable(_that.profiles);case SessionActive() when sessionActive != null:
return sessionActive(_that.profile,_that.locked);case OnboardingRequired() when onboardingRequired != null:
return onboardingRequired(_that.profile);case OtpPending() when otpPending != null:
return otpPending(_that.phone);case SettingPin() when settingPin != null:
return settingPin(_that.phone,_that.userId,_that.refreshToken);case PinLockedOut() when pinLockedOut != null:
return pinLockedOut(_that.profile,_that.lockedUntil);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  unauthenticated,required TResult Function( List<LocalUserProfile> profiles)  profilesAvailable,required TResult Function( LocalUserProfile profile,  bool locked)  sessionActive,required TResult Function( LocalUserProfile profile)  onboardingRequired,required TResult Function( String phone)  otpPending,required TResult Function( String phone,  String userId,  String refreshToken)  settingPin,required TResult Function( LocalUserProfile profile,  DateTime lockedUntil)  pinLockedOut,}) {final _that = this;
switch (_that) {
case Unauthenticated():
return unauthenticated();case ProfilesAvailable():
return profilesAvailable(_that.profiles);case SessionActive():
return sessionActive(_that.profile,_that.locked);case OnboardingRequired():
return onboardingRequired(_that.profile);case OtpPending():
return otpPending(_that.phone);case SettingPin():
return settingPin(_that.phone,_that.userId,_that.refreshToken);case PinLockedOut():
return pinLockedOut(_that.profile,_that.lockedUntil);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  unauthenticated,TResult? Function( List<LocalUserProfile> profiles)?  profilesAvailable,TResult? Function( LocalUserProfile profile,  bool locked)?  sessionActive,TResult? Function( LocalUserProfile profile)?  onboardingRequired,TResult? Function( String phone)?  otpPending,TResult? Function( String phone,  String userId,  String refreshToken)?  settingPin,TResult? Function( LocalUserProfile profile,  DateTime lockedUntil)?  pinLockedOut,}) {final _that = this;
switch (_that) {
case Unauthenticated() when unauthenticated != null:
return unauthenticated();case ProfilesAvailable() when profilesAvailable != null:
return profilesAvailable(_that.profiles);case SessionActive() when sessionActive != null:
return sessionActive(_that.profile,_that.locked);case OnboardingRequired() when onboardingRequired != null:
return onboardingRequired(_that.profile);case OtpPending() when otpPending != null:
return otpPending(_that.phone);case SettingPin() when settingPin != null:
return settingPin(_that.phone,_that.userId,_that.refreshToken);case PinLockedOut() when pinLockedOut != null:
return pinLockedOut(_that.profile,_that.lockedUntil);case _:
  return null;

}
}

}

/// @nodoc


class Unauthenticated extends AuthState {
  const Unauthenticated(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Unauthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.unauthenticated()';
}


}




/// @nodoc


class ProfilesAvailable extends AuthState {
  const ProfilesAvailable(final  List<LocalUserProfile> profiles): _profiles = profiles,super._();
  

 final  List<LocalUserProfile> _profiles;
 List<LocalUserProfile> get profiles {
  if (_profiles is EqualUnmodifiableListView) return _profiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_profiles);
}


/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfilesAvailableCopyWith<ProfilesAvailable> get copyWith => _$ProfilesAvailableCopyWithImpl<ProfilesAvailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfilesAvailable&&const DeepCollectionEquality().equals(other._profiles, _profiles));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_profiles));

@override
String toString() {
  return 'AuthState.profilesAvailable(profiles: $profiles)';
}


}

/// @nodoc
abstract mixin class $ProfilesAvailableCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $ProfilesAvailableCopyWith(ProfilesAvailable value, $Res Function(ProfilesAvailable) _then) = _$ProfilesAvailableCopyWithImpl;
@useResult
$Res call({
 List<LocalUserProfile> profiles
});




}
/// @nodoc
class _$ProfilesAvailableCopyWithImpl<$Res>
    implements $ProfilesAvailableCopyWith<$Res> {
  _$ProfilesAvailableCopyWithImpl(this._self, this._then);

  final ProfilesAvailable _self;
  final $Res Function(ProfilesAvailable) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? profiles = null,}) {
  return _then(ProfilesAvailable(
null == profiles ? _self._profiles : profiles // ignore: cast_nullable_to_non_nullable
as List<LocalUserProfile>,
  ));
}


}

/// @nodoc


class SessionActive extends AuthState {
  const SessionActive(this.profile, {this.locked = false}): super._();
  

 final  LocalUserProfile profile;
@JsonKey() final  bool locked;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionActiveCopyWith<SessionActive> get copyWith => _$SessionActiveCopyWithImpl<SessionActive>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionActive&&const DeepCollectionEquality().equals(other.profile, profile)&&(identical(other.locked, locked) || other.locked == locked));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(profile),locked);

@override
String toString() {
  return 'AuthState.sessionActive(profile: $profile, locked: $locked)';
}


}

/// @nodoc
abstract mixin class $SessionActiveCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $SessionActiveCopyWith(SessionActive value, $Res Function(SessionActive) _then) = _$SessionActiveCopyWithImpl;
@useResult
$Res call({
 LocalUserProfile profile, bool locked
});




}
/// @nodoc
class _$SessionActiveCopyWithImpl<$Res>
    implements $SessionActiveCopyWith<$Res> {
  _$SessionActiveCopyWithImpl(this._self, this._then);

  final SessionActive _self;
  final $Res Function(SessionActive) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? profile = freezed,Object? locked = null,}) {
  return _then(SessionActive(
freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as LocalUserProfile,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class OnboardingRequired extends AuthState {
  const OnboardingRequired(this.profile): super._();
  

 final  LocalUserProfile profile;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingRequiredCopyWith<OnboardingRequired> get copyWith => _$OnboardingRequiredCopyWithImpl<OnboardingRequired>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingRequired&&const DeepCollectionEquality().equals(other.profile, profile));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(profile));

@override
String toString() {
  return 'AuthState.onboardingRequired(profile: $profile)';
}


}

/// @nodoc
abstract mixin class $OnboardingRequiredCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $OnboardingRequiredCopyWith(OnboardingRequired value, $Res Function(OnboardingRequired) _then) = _$OnboardingRequiredCopyWithImpl;
@useResult
$Res call({
 LocalUserProfile profile
});




}
/// @nodoc
class _$OnboardingRequiredCopyWithImpl<$Res>
    implements $OnboardingRequiredCopyWith<$Res> {
  _$OnboardingRequiredCopyWithImpl(this._self, this._then);

  final OnboardingRequired _self;
  final $Res Function(OnboardingRequired) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? profile = freezed,}) {
  return _then(OnboardingRequired(
freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as LocalUserProfile,
  ));
}


}

/// @nodoc


class OtpPending extends AuthState {
  const OtpPending(this.phone): super._();
  

 final  String phone;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpPendingCopyWith<OtpPending> get copyWith => _$OtpPendingCopyWithImpl<OtpPending>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpPending&&(identical(other.phone, phone) || other.phone == phone));
}


@override
int get hashCode => Object.hash(runtimeType,phone);

@override
String toString() {
  return 'AuthState.otpPending(phone: $phone)';
}


}

/// @nodoc
abstract mixin class $OtpPendingCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $OtpPendingCopyWith(OtpPending value, $Res Function(OtpPending) _then) = _$OtpPendingCopyWithImpl;
@useResult
$Res call({
 String phone
});




}
/// @nodoc
class _$OtpPendingCopyWithImpl<$Res>
    implements $OtpPendingCopyWith<$Res> {
  _$OtpPendingCopyWithImpl(this._self, this._then);

  final OtpPending _self;
  final $Res Function(OtpPending) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phone = null,}) {
  return _then(OtpPending(
null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SettingPin extends AuthState {
  const SettingPin({required this.phone, required this.userId, required this.refreshToken}): super._();
  

 final  String phone;
 final  String userId;
 final  String refreshToken;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingPinCopyWith<SettingPin> get copyWith => _$SettingPinCopyWithImpl<SettingPin>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingPin&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken));
}


@override
int get hashCode => Object.hash(runtimeType,phone,userId,refreshToken);

@override
String toString() {
  return 'AuthState.settingPin(phone: $phone, userId: $userId, refreshToken: $refreshToken)';
}


}

/// @nodoc
abstract mixin class $SettingPinCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $SettingPinCopyWith(SettingPin value, $Res Function(SettingPin) _then) = _$SettingPinCopyWithImpl;
@useResult
$Res call({
 String phone, String userId, String refreshToken
});




}
/// @nodoc
class _$SettingPinCopyWithImpl<$Res>
    implements $SettingPinCopyWith<$Res> {
  _$SettingPinCopyWithImpl(this._self, this._then);

  final SettingPin _self;
  final $Res Function(SettingPin) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? userId = null,Object? refreshToken = null,}) {
  return _then(SettingPin(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PinLockedOut extends AuthState {
  const PinLockedOut(this.profile, this.lockedUntil): super._();
  

 final  LocalUserProfile profile;
 final  DateTime lockedUntil;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PinLockedOutCopyWith<PinLockedOut> get copyWith => _$PinLockedOutCopyWithImpl<PinLockedOut>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PinLockedOut&&const DeepCollectionEquality().equals(other.profile, profile)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(profile),lockedUntil);

@override
String toString() {
  return 'AuthState.pinLockedOut(profile: $profile, lockedUntil: $lockedUntil)';
}


}

/// @nodoc
abstract mixin class $PinLockedOutCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $PinLockedOutCopyWith(PinLockedOut value, $Res Function(PinLockedOut) _then) = _$PinLockedOutCopyWithImpl;
@useResult
$Res call({
 LocalUserProfile profile, DateTime lockedUntil
});




}
/// @nodoc
class _$PinLockedOutCopyWithImpl<$Res>
    implements $PinLockedOutCopyWith<$Res> {
  _$PinLockedOutCopyWithImpl(this._self, this._then);

  final PinLockedOut _self;
  final $Res Function(PinLockedOut) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? profile = freezed,Object? lockedUntil = null,}) {
  return _then(PinLockedOut(
freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as LocalUserProfile,null == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
