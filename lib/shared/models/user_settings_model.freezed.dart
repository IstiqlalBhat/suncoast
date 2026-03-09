// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserSettingsModel {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'face_id_enabled') bool get faceIdEnabled;@JsonKey(name: 'voice_output_enabled') bool get voiceOutputEnabled;@JsonKey(name: 'voice_id') String? get voiceId;@JsonKey(name: 'voice_speed') double get voiceSpeed;@JsonKey(name: 'confirmation_mode') ConfirmationMode get confirmationMode; String get language;@JsonKey(name: 'use_premium_tts') bool get usePremiumTts;
/// Create a copy of UserSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSettingsModelCopyWith<UserSettingsModel> get copyWith => _$UserSettingsModelCopyWithImpl<UserSettingsModel>(this as UserSettingsModel, _$identity);

  /// Serializes this UserSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSettingsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.faceIdEnabled, faceIdEnabled) || other.faceIdEnabled == faceIdEnabled)&&(identical(other.voiceOutputEnabled, voiceOutputEnabled) || other.voiceOutputEnabled == voiceOutputEnabled)&&(identical(other.voiceId, voiceId) || other.voiceId == voiceId)&&(identical(other.voiceSpeed, voiceSpeed) || other.voiceSpeed == voiceSpeed)&&(identical(other.confirmationMode, confirmationMode) || other.confirmationMode == confirmationMode)&&(identical(other.language, language) || other.language == language)&&(identical(other.usePremiumTts, usePremiumTts) || other.usePremiumTts == usePremiumTts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,faceIdEnabled,voiceOutputEnabled,voiceId,voiceSpeed,confirmationMode,language,usePremiumTts);

@override
String toString() {
  return 'UserSettingsModel(id: $id, userId: $userId, faceIdEnabled: $faceIdEnabled, voiceOutputEnabled: $voiceOutputEnabled, voiceId: $voiceId, voiceSpeed: $voiceSpeed, confirmationMode: $confirmationMode, language: $language, usePremiumTts: $usePremiumTts)';
}


}

/// @nodoc
abstract mixin class $UserSettingsModelCopyWith<$Res>  {
  factory $UserSettingsModelCopyWith(UserSettingsModel value, $Res Function(UserSettingsModel) _then) = _$UserSettingsModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'face_id_enabled') bool faceIdEnabled,@JsonKey(name: 'voice_output_enabled') bool voiceOutputEnabled,@JsonKey(name: 'voice_id') String? voiceId,@JsonKey(name: 'voice_speed') double voiceSpeed,@JsonKey(name: 'confirmation_mode') ConfirmationMode confirmationMode, String language,@JsonKey(name: 'use_premium_tts') bool usePremiumTts
});




}
/// @nodoc
class _$UserSettingsModelCopyWithImpl<$Res>
    implements $UserSettingsModelCopyWith<$Res> {
  _$UserSettingsModelCopyWithImpl(this._self, this._then);

  final UserSettingsModel _self;
  final $Res Function(UserSettingsModel) _then;

/// Create a copy of UserSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? faceIdEnabled = null,Object? voiceOutputEnabled = null,Object? voiceId = freezed,Object? voiceSpeed = null,Object? confirmationMode = null,Object? language = null,Object? usePremiumTts = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,faceIdEnabled: null == faceIdEnabled ? _self.faceIdEnabled : faceIdEnabled // ignore: cast_nullable_to_non_nullable
as bool,voiceOutputEnabled: null == voiceOutputEnabled ? _self.voiceOutputEnabled : voiceOutputEnabled // ignore: cast_nullable_to_non_nullable
as bool,voiceId: freezed == voiceId ? _self.voiceId : voiceId // ignore: cast_nullable_to_non_nullable
as String?,voiceSpeed: null == voiceSpeed ? _self.voiceSpeed : voiceSpeed // ignore: cast_nullable_to_non_nullable
as double,confirmationMode: null == confirmationMode ? _self.confirmationMode : confirmationMode // ignore: cast_nullable_to_non_nullable
as ConfirmationMode,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,usePremiumTts: null == usePremiumTts ? _self.usePremiumTts : usePremiumTts // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSettingsModel].
extension UserSettingsModelPatterns on UserSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSettingsModel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _UserSettingsModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserSettingsModel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'face_id_enabled')  bool faceIdEnabled, @JsonKey(name: 'voice_output_enabled')  bool voiceOutputEnabled, @JsonKey(name: 'voice_id')  String? voiceId, @JsonKey(name: 'voice_speed')  double voiceSpeed, @JsonKey(name: 'confirmation_mode')  ConfirmationMode confirmationMode,  String language, @JsonKey(name: 'use_premium_tts')  bool usePremiumTts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSettingsModel() when $default != null:
return $default(_that.id,_that.userId,_that.faceIdEnabled,_that.voiceOutputEnabled,_that.voiceId,_that.voiceSpeed,_that.confirmationMode,_that.language,_that.usePremiumTts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'face_id_enabled')  bool faceIdEnabled, @JsonKey(name: 'voice_output_enabled')  bool voiceOutputEnabled, @JsonKey(name: 'voice_id')  String? voiceId, @JsonKey(name: 'voice_speed')  double voiceSpeed, @JsonKey(name: 'confirmation_mode')  ConfirmationMode confirmationMode,  String language, @JsonKey(name: 'use_premium_tts')  bool usePremiumTts)  $default,) {final _that = this;
switch (_that) {
case _UserSettingsModel():
return $default(_that.id,_that.userId,_that.faceIdEnabled,_that.voiceOutputEnabled,_that.voiceId,_that.voiceSpeed,_that.confirmationMode,_that.language,_that.usePremiumTts);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'face_id_enabled')  bool faceIdEnabled, @JsonKey(name: 'voice_output_enabled')  bool voiceOutputEnabled, @JsonKey(name: 'voice_id')  String? voiceId, @JsonKey(name: 'voice_speed')  double voiceSpeed, @JsonKey(name: 'confirmation_mode')  ConfirmationMode confirmationMode,  String language, @JsonKey(name: 'use_premium_tts')  bool usePremiumTts)?  $default,) {final _that = this;
switch (_that) {
case _UserSettingsModel() when $default != null:
return $default(_that.id,_that.userId,_that.faceIdEnabled,_that.voiceOutputEnabled,_that.voiceId,_that.voiceSpeed,_that.confirmationMode,_that.language,_that.usePremiumTts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserSettingsModel implements UserSettingsModel {
  const _UserSettingsModel({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'face_id_enabled') this.faceIdEnabled = false, @JsonKey(name: 'voice_output_enabled') this.voiceOutputEnabled = true, @JsonKey(name: 'voice_id') this.voiceId, @JsonKey(name: 'voice_speed') this.voiceSpeed = 1.0, @JsonKey(name: 'confirmation_mode') this.confirmationMode = ConfirmationMode.smart, this.language = 'en', @JsonKey(name: 'use_premium_tts') this.usePremiumTts = true});
  factory _UserSettingsModel.fromJson(Map<String, dynamic> json) => _$UserSettingsModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'face_id_enabled') final  bool faceIdEnabled;
@override@JsonKey(name: 'voice_output_enabled') final  bool voiceOutputEnabled;
@override@JsonKey(name: 'voice_id') final  String? voiceId;
@override@JsonKey(name: 'voice_speed') final  double voiceSpeed;
@override@JsonKey(name: 'confirmation_mode') final  ConfirmationMode confirmationMode;
@override@JsonKey() final  String language;
@override@JsonKey(name: 'use_premium_tts') final  bool usePremiumTts;

/// Create a copy of UserSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSettingsModelCopyWith<_UserSettingsModel> get copyWith => __$UserSettingsModelCopyWithImpl<_UserSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSettingsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.faceIdEnabled, faceIdEnabled) || other.faceIdEnabled == faceIdEnabled)&&(identical(other.voiceOutputEnabled, voiceOutputEnabled) || other.voiceOutputEnabled == voiceOutputEnabled)&&(identical(other.voiceId, voiceId) || other.voiceId == voiceId)&&(identical(other.voiceSpeed, voiceSpeed) || other.voiceSpeed == voiceSpeed)&&(identical(other.confirmationMode, confirmationMode) || other.confirmationMode == confirmationMode)&&(identical(other.language, language) || other.language == language)&&(identical(other.usePremiumTts, usePremiumTts) || other.usePremiumTts == usePremiumTts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,faceIdEnabled,voiceOutputEnabled,voiceId,voiceSpeed,confirmationMode,language,usePremiumTts);

@override
String toString() {
  return 'UserSettingsModel(id: $id, userId: $userId, faceIdEnabled: $faceIdEnabled, voiceOutputEnabled: $voiceOutputEnabled, voiceId: $voiceId, voiceSpeed: $voiceSpeed, confirmationMode: $confirmationMode, language: $language, usePremiumTts: $usePremiumTts)';
}


}

/// @nodoc
abstract mixin class _$UserSettingsModelCopyWith<$Res> implements $UserSettingsModelCopyWith<$Res> {
  factory _$UserSettingsModelCopyWith(_UserSettingsModel value, $Res Function(_UserSettingsModel) _then) = __$UserSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'face_id_enabled') bool faceIdEnabled,@JsonKey(name: 'voice_output_enabled') bool voiceOutputEnabled,@JsonKey(name: 'voice_id') String? voiceId,@JsonKey(name: 'voice_speed') double voiceSpeed,@JsonKey(name: 'confirmation_mode') ConfirmationMode confirmationMode, String language,@JsonKey(name: 'use_premium_tts') bool usePremiumTts
});




}
/// @nodoc
class __$UserSettingsModelCopyWithImpl<$Res>
    implements _$UserSettingsModelCopyWith<$Res> {
  __$UserSettingsModelCopyWithImpl(this._self, this._then);

  final _UserSettingsModel _self;
  final $Res Function(_UserSettingsModel) _then;

/// Create a copy of UserSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? faceIdEnabled = null,Object? voiceOutputEnabled = null,Object? voiceId = freezed,Object? voiceSpeed = null,Object? confirmationMode = null,Object? language = null,Object? usePremiumTts = null,}) {
  return _then(_UserSettingsModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,faceIdEnabled: null == faceIdEnabled ? _self.faceIdEnabled : faceIdEnabled // ignore: cast_nullable_to_non_nullable
as bool,voiceOutputEnabled: null == voiceOutputEnabled ? _self.voiceOutputEnabled : voiceOutputEnabled // ignore: cast_nullable_to_non_nullable
as bool,voiceId: freezed == voiceId ? _self.voiceId : voiceId // ignore: cast_nullable_to_non_nullable
as String?,voiceSpeed: null == voiceSpeed ? _self.voiceSpeed : voiceSpeed // ignore: cast_nullable_to_non_nullable
as double,confirmationMode: null == confirmationMode ? _self.confirmationMode : confirmationMode // ignore: cast_nullable_to_non_nullable
as ConfirmationMode,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,usePremiumTts: null == usePremiumTts ? _self.usePremiumTts : usePremiumTts // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
