// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionModel {

 String get id;@JsonKey(name: 'activity_id') String get activityId;@JsonKey(name: 'user_id') String get userId; SessionMode get mode; SessionStatus get status;@JsonKey(name: 'started_at') DateTime get startedAt;@JsonKey(name: 'ended_at') DateTime? get endedAt;@JsonKey(name: 'ended_reason') String? get endedReason;@JsonKey(name: 'processing_error') String? get processingError; String? get transcript;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionModelCopyWith<SessionModel> get copyWith => _$SessionModelCopyWithImpl<SessionModel>(this as SessionModel, _$identity);

  /// Serializes this SessionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.activityId, activityId) || other.activityId == activityId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.endedReason, endedReason) || other.endedReason == endedReason)&&(identical(other.processingError, processingError) || other.processingError == processingError)&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,activityId,userId,mode,status,startedAt,endedAt,endedReason,processingError,transcript,createdAt,updatedAt);

@override
String toString() {
  return 'SessionModel(id: $id, activityId: $activityId, userId: $userId, mode: $mode, status: $status, startedAt: $startedAt, endedAt: $endedAt, endedReason: $endedReason, processingError: $processingError, transcript: $transcript, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SessionModelCopyWith<$Res>  {
  factory $SessionModelCopyWith(SessionModel value, $Res Function(SessionModel) _then) = _$SessionModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'activity_id') String activityId,@JsonKey(name: 'user_id') String userId, SessionMode mode, SessionStatus status,@JsonKey(name: 'started_at') DateTime startedAt,@JsonKey(name: 'ended_at') DateTime? endedAt,@JsonKey(name: 'ended_reason') String? endedReason,@JsonKey(name: 'processing_error') String? processingError, String? transcript,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$SessionModelCopyWithImpl<$Res>
    implements $SessionModelCopyWith<$Res> {
  _$SessionModelCopyWithImpl(this._self, this._then);

  final SessionModel _self;
  final $Res Function(SessionModel) _then;

/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? activityId = null,Object? userId = null,Object? mode = null,Object? status = null,Object? startedAt = null,Object? endedAt = freezed,Object? endedReason = freezed,Object? processingError = freezed,Object? transcript = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as SessionMode,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedReason: freezed == endedReason ? _self.endedReason : endedReason // ignore: cast_nullable_to_non_nullable
as String?,processingError: freezed == processingError ? _self.processingError : processingError // ignore: cast_nullable_to_non_nullable
as String?,transcript: freezed == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionModel].
extension SessionModelPatterns on SessionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionModel value)  $default,){
final _that = this;
switch (_that) {
case _SessionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionModel value)?  $default,){
final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'activity_id')  String activityId, @JsonKey(name: 'user_id')  String userId,  SessionMode mode,  SessionStatus status, @JsonKey(name: 'started_at')  DateTime startedAt, @JsonKey(name: 'ended_at')  DateTime? endedAt, @JsonKey(name: 'ended_reason')  String? endedReason, @JsonKey(name: 'processing_error')  String? processingError,  String? transcript, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
return $default(_that.id,_that.activityId,_that.userId,_that.mode,_that.status,_that.startedAt,_that.endedAt,_that.endedReason,_that.processingError,_that.transcript,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'activity_id')  String activityId, @JsonKey(name: 'user_id')  String userId,  SessionMode mode,  SessionStatus status, @JsonKey(name: 'started_at')  DateTime startedAt, @JsonKey(name: 'ended_at')  DateTime? endedAt, @JsonKey(name: 'ended_reason')  String? endedReason, @JsonKey(name: 'processing_error')  String? processingError,  String? transcript, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SessionModel():
return $default(_that.id,_that.activityId,_that.userId,_that.mode,_that.status,_that.startedAt,_that.endedAt,_that.endedReason,_that.processingError,_that.transcript,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'activity_id')  String activityId, @JsonKey(name: 'user_id')  String userId,  SessionMode mode,  SessionStatus status, @JsonKey(name: 'started_at')  DateTime startedAt, @JsonKey(name: 'ended_at')  DateTime? endedAt, @JsonKey(name: 'ended_reason')  String? endedReason, @JsonKey(name: 'processing_error')  String? processingError,  String? transcript, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
return $default(_that.id,_that.activityId,_that.userId,_that.mode,_that.status,_that.startedAt,_that.endedAt,_that.endedReason,_that.processingError,_that.transcript,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionModel implements SessionModel {
  const _SessionModel({required this.id, @JsonKey(name: 'activity_id') required this.activityId, @JsonKey(name: 'user_id') required this.userId, required this.mode, this.status = SessionStatus.active, @JsonKey(name: 'started_at') required this.startedAt, @JsonKey(name: 'ended_at') this.endedAt, @JsonKey(name: 'ended_reason') this.endedReason, @JsonKey(name: 'processing_error') this.processingError, this.transcript, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _SessionModel.fromJson(Map<String, dynamic> json) => _$SessionModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'activity_id') final  String activityId;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  SessionMode mode;
@override@JsonKey() final  SessionStatus status;
@override@JsonKey(name: 'started_at') final  DateTime startedAt;
@override@JsonKey(name: 'ended_at') final  DateTime? endedAt;
@override@JsonKey(name: 'ended_reason') final  String? endedReason;
@override@JsonKey(name: 'processing_error') final  String? processingError;
@override final  String? transcript;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionModelCopyWith<_SessionModel> get copyWith => __$SessionModelCopyWithImpl<_SessionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.activityId, activityId) || other.activityId == activityId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.endedReason, endedReason) || other.endedReason == endedReason)&&(identical(other.processingError, processingError) || other.processingError == processingError)&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,activityId,userId,mode,status,startedAt,endedAt,endedReason,processingError,transcript,createdAt,updatedAt);

@override
String toString() {
  return 'SessionModel(id: $id, activityId: $activityId, userId: $userId, mode: $mode, status: $status, startedAt: $startedAt, endedAt: $endedAt, endedReason: $endedReason, processingError: $processingError, transcript: $transcript, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SessionModelCopyWith<$Res> implements $SessionModelCopyWith<$Res> {
  factory _$SessionModelCopyWith(_SessionModel value, $Res Function(_SessionModel) _then) = __$SessionModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'activity_id') String activityId,@JsonKey(name: 'user_id') String userId, SessionMode mode, SessionStatus status,@JsonKey(name: 'started_at') DateTime startedAt,@JsonKey(name: 'ended_at') DateTime? endedAt,@JsonKey(name: 'ended_reason') String? endedReason,@JsonKey(name: 'processing_error') String? processingError, String? transcript,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$SessionModelCopyWithImpl<$Res>
    implements _$SessionModelCopyWith<$Res> {
  __$SessionModelCopyWithImpl(this._self, this._then);

  final _SessionModel _self;
  final $Res Function(_SessionModel) _then;

/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? activityId = null,Object? userId = null,Object? mode = null,Object? status = null,Object? startedAt = null,Object? endedAt = freezed,Object? endedReason = freezed,Object? processingError = freezed,Object? transcript = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_SessionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,activityId: null == activityId ? _self.activityId : activityId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as SessionMode,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedReason: freezed == endedReason ? _self.endedReason : endedReason // ignore: cast_nullable_to_non_nullable
as String?,processingError: freezed == processingError ? _self.processingError : processingError // ignore: cast_nullable_to_non_nullable
as String?,transcript: freezed == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
