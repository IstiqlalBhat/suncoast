// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionSummaryModel {

 String get id;@JsonKey(name: 'session_id') String get sessionId;@JsonKey(name: 'observation_summary') String get observationSummary;@JsonKey(name: 'key_observations') List<String> get keyObservations;@JsonKey(name: 'actions_taken') List<String> get actionsTaken;@JsonKey(name: 'follow_ups') List<FollowUpModel> get followUps;@JsonKey(name: 'action_statuses') List<Map<String, dynamic>> get actionStatuses;@JsonKey(name: 'external_records') List<Map<String, dynamic>> get externalRecords;@JsonKey(name: 'duration_seconds') int? get durationSeconds;@JsonKey(name: 'confirmed_at') DateTime? get confirmedAt;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of SessionSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionSummaryModelCopyWith<SessionSummaryModel> get copyWith => _$SessionSummaryModelCopyWithImpl<SessionSummaryModel>(this as SessionSummaryModel, _$identity);

  /// Serializes this SessionSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.observationSummary, observationSummary) || other.observationSummary == observationSummary)&&const DeepCollectionEquality().equals(other.keyObservations, keyObservations)&&const DeepCollectionEquality().equals(other.actionsTaken, actionsTaken)&&const DeepCollectionEquality().equals(other.followUps, followUps)&&const DeepCollectionEquality().equals(other.actionStatuses, actionStatuses)&&const DeepCollectionEquality().equals(other.externalRecords, externalRecords)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,observationSummary,const DeepCollectionEquality().hash(keyObservations),const DeepCollectionEquality().hash(actionsTaken),const DeepCollectionEquality().hash(followUps),const DeepCollectionEquality().hash(actionStatuses),const DeepCollectionEquality().hash(externalRecords),durationSeconds,confirmedAt,createdAt);

@override
String toString() {
  return 'SessionSummaryModel(id: $id, sessionId: $sessionId, observationSummary: $observationSummary, keyObservations: $keyObservations, actionsTaken: $actionsTaken, followUps: $followUps, actionStatuses: $actionStatuses, externalRecords: $externalRecords, durationSeconds: $durationSeconds, confirmedAt: $confirmedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SessionSummaryModelCopyWith<$Res>  {
  factory $SessionSummaryModelCopyWith(SessionSummaryModel value, $Res Function(SessionSummaryModel) _then) = _$SessionSummaryModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'session_id') String sessionId,@JsonKey(name: 'observation_summary') String observationSummary,@JsonKey(name: 'key_observations') List<String> keyObservations,@JsonKey(name: 'actions_taken') List<String> actionsTaken,@JsonKey(name: 'follow_ups') List<FollowUpModel> followUps,@JsonKey(name: 'action_statuses') List<Map<String, dynamic>> actionStatuses,@JsonKey(name: 'external_records') List<Map<String, dynamic>> externalRecords,@JsonKey(name: 'duration_seconds') int? durationSeconds,@JsonKey(name: 'confirmed_at') DateTime? confirmedAt,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$SessionSummaryModelCopyWithImpl<$Res>
    implements $SessionSummaryModelCopyWith<$Res> {
  _$SessionSummaryModelCopyWithImpl(this._self, this._then);

  final SessionSummaryModel _self;
  final $Res Function(SessionSummaryModel) _then;

/// Create a copy of SessionSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? observationSummary = null,Object? keyObservations = null,Object? actionsTaken = null,Object? followUps = null,Object? actionStatuses = null,Object? externalRecords = null,Object? durationSeconds = freezed,Object? confirmedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,observationSummary: null == observationSummary ? _self.observationSummary : observationSummary // ignore: cast_nullable_to_non_nullable
as String,keyObservations: null == keyObservations ? _self.keyObservations : keyObservations // ignore: cast_nullable_to_non_nullable
as List<String>,actionsTaken: null == actionsTaken ? _self.actionsTaken : actionsTaken // ignore: cast_nullable_to_non_nullable
as List<String>,followUps: null == followUps ? _self.followUps : followUps // ignore: cast_nullable_to_non_nullable
as List<FollowUpModel>,actionStatuses: null == actionStatuses ? _self.actionStatuses : actionStatuses // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,externalRecords: null == externalRecords ? _self.externalRecords : externalRecords // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionSummaryModel].
extension SessionSummaryModelPatterns on SessionSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _SessionSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _SessionSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'session_id')  String sessionId, @JsonKey(name: 'observation_summary')  String observationSummary, @JsonKey(name: 'key_observations')  List<String> keyObservations, @JsonKey(name: 'actions_taken')  List<String> actionsTaken, @JsonKey(name: 'follow_ups')  List<FollowUpModel> followUps, @JsonKey(name: 'action_statuses')  List<Map<String, dynamic>> actionStatuses, @JsonKey(name: 'external_records')  List<Map<String, dynamic>> externalRecords, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'confirmed_at')  DateTime? confirmedAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionSummaryModel() when $default != null:
return $default(_that.id,_that.sessionId,_that.observationSummary,_that.keyObservations,_that.actionsTaken,_that.followUps,_that.actionStatuses,_that.externalRecords,_that.durationSeconds,_that.confirmedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'session_id')  String sessionId, @JsonKey(name: 'observation_summary')  String observationSummary, @JsonKey(name: 'key_observations')  List<String> keyObservations, @JsonKey(name: 'actions_taken')  List<String> actionsTaken, @JsonKey(name: 'follow_ups')  List<FollowUpModel> followUps, @JsonKey(name: 'action_statuses')  List<Map<String, dynamic>> actionStatuses, @JsonKey(name: 'external_records')  List<Map<String, dynamic>> externalRecords, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'confirmed_at')  DateTime? confirmedAt, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SessionSummaryModel():
return $default(_that.id,_that.sessionId,_that.observationSummary,_that.keyObservations,_that.actionsTaken,_that.followUps,_that.actionStatuses,_that.externalRecords,_that.durationSeconds,_that.confirmedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'session_id')  String sessionId, @JsonKey(name: 'observation_summary')  String observationSummary, @JsonKey(name: 'key_observations')  List<String> keyObservations, @JsonKey(name: 'actions_taken')  List<String> actionsTaken, @JsonKey(name: 'follow_ups')  List<FollowUpModel> followUps, @JsonKey(name: 'action_statuses')  List<Map<String, dynamic>> actionStatuses, @JsonKey(name: 'external_records')  List<Map<String, dynamic>> externalRecords, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'confirmed_at')  DateTime? confirmedAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SessionSummaryModel() when $default != null:
return $default(_that.id,_that.sessionId,_that.observationSummary,_that.keyObservations,_that.actionsTaken,_that.followUps,_that.actionStatuses,_that.externalRecords,_that.durationSeconds,_that.confirmedAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionSummaryModel implements SessionSummaryModel {
  const _SessionSummaryModel({required this.id, @JsonKey(name: 'session_id') required this.sessionId, @JsonKey(name: 'observation_summary') this.observationSummary = '', @JsonKey(name: 'key_observations') required final  List<String> keyObservations, @JsonKey(name: 'actions_taken') required final  List<String> actionsTaken, @JsonKey(name: 'follow_ups') required final  List<FollowUpModel> followUps, @JsonKey(name: 'action_statuses') final  List<Map<String, dynamic>> actionStatuses = const <Map<String, dynamic>>[], @JsonKey(name: 'external_records') final  List<Map<String, dynamic>> externalRecords = const <Map<String, dynamic>>[], @JsonKey(name: 'duration_seconds') this.durationSeconds, @JsonKey(name: 'confirmed_at') this.confirmedAt, @JsonKey(name: 'created_at') this.createdAt}): _keyObservations = keyObservations,_actionsTaken = actionsTaken,_followUps = followUps,_actionStatuses = actionStatuses,_externalRecords = externalRecords;
  factory _SessionSummaryModel.fromJson(Map<String, dynamic> json) => _$SessionSummaryModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'session_id') final  String sessionId;
@override@JsonKey(name: 'observation_summary') final  String observationSummary;
 final  List<String> _keyObservations;
@override@JsonKey(name: 'key_observations') List<String> get keyObservations {
  if (_keyObservations is EqualUnmodifiableListView) return _keyObservations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keyObservations);
}

 final  List<String> _actionsTaken;
@override@JsonKey(name: 'actions_taken') List<String> get actionsTaken {
  if (_actionsTaken is EqualUnmodifiableListView) return _actionsTaken;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actionsTaken);
}

 final  List<FollowUpModel> _followUps;
@override@JsonKey(name: 'follow_ups') List<FollowUpModel> get followUps {
  if (_followUps is EqualUnmodifiableListView) return _followUps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_followUps);
}

 final  List<Map<String, dynamic>> _actionStatuses;
@override@JsonKey(name: 'action_statuses') List<Map<String, dynamic>> get actionStatuses {
  if (_actionStatuses is EqualUnmodifiableListView) return _actionStatuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actionStatuses);
}

 final  List<Map<String, dynamic>> _externalRecords;
@override@JsonKey(name: 'external_records') List<Map<String, dynamic>> get externalRecords {
  if (_externalRecords is EqualUnmodifiableListView) return _externalRecords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_externalRecords);
}

@override@JsonKey(name: 'duration_seconds') final  int? durationSeconds;
@override@JsonKey(name: 'confirmed_at') final  DateTime? confirmedAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of SessionSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionSummaryModelCopyWith<_SessionSummaryModel> get copyWith => __$SessionSummaryModelCopyWithImpl<_SessionSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.observationSummary, observationSummary) || other.observationSummary == observationSummary)&&const DeepCollectionEquality().equals(other._keyObservations, _keyObservations)&&const DeepCollectionEquality().equals(other._actionsTaken, _actionsTaken)&&const DeepCollectionEquality().equals(other._followUps, _followUps)&&const DeepCollectionEquality().equals(other._actionStatuses, _actionStatuses)&&const DeepCollectionEquality().equals(other._externalRecords, _externalRecords)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,observationSummary,const DeepCollectionEquality().hash(_keyObservations),const DeepCollectionEquality().hash(_actionsTaken),const DeepCollectionEquality().hash(_followUps),const DeepCollectionEquality().hash(_actionStatuses),const DeepCollectionEquality().hash(_externalRecords),durationSeconds,confirmedAt,createdAt);

@override
String toString() {
  return 'SessionSummaryModel(id: $id, sessionId: $sessionId, observationSummary: $observationSummary, keyObservations: $keyObservations, actionsTaken: $actionsTaken, followUps: $followUps, actionStatuses: $actionStatuses, externalRecords: $externalRecords, durationSeconds: $durationSeconds, confirmedAt: $confirmedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SessionSummaryModelCopyWith<$Res> implements $SessionSummaryModelCopyWith<$Res> {
  factory _$SessionSummaryModelCopyWith(_SessionSummaryModel value, $Res Function(_SessionSummaryModel) _then) = __$SessionSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'session_id') String sessionId,@JsonKey(name: 'observation_summary') String observationSummary,@JsonKey(name: 'key_observations') List<String> keyObservations,@JsonKey(name: 'actions_taken') List<String> actionsTaken,@JsonKey(name: 'follow_ups') List<FollowUpModel> followUps,@JsonKey(name: 'action_statuses') List<Map<String, dynamic>> actionStatuses,@JsonKey(name: 'external_records') List<Map<String, dynamic>> externalRecords,@JsonKey(name: 'duration_seconds') int? durationSeconds,@JsonKey(name: 'confirmed_at') DateTime? confirmedAt,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$SessionSummaryModelCopyWithImpl<$Res>
    implements _$SessionSummaryModelCopyWith<$Res> {
  __$SessionSummaryModelCopyWithImpl(this._self, this._then);

  final _SessionSummaryModel _self;
  final $Res Function(_SessionSummaryModel) _then;

/// Create a copy of SessionSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? observationSummary = null,Object? keyObservations = null,Object? actionsTaken = null,Object? followUps = null,Object? actionStatuses = null,Object? externalRecords = null,Object? durationSeconds = freezed,Object? confirmedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_SessionSummaryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,observationSummary: null == observationSummary ? _self.observationSummary : observationSummary // ignore: cast_nullable_to_non_nullable
as String,keyObservations: null == keyObservations ? _self._keyObservations : keyObservations // ignore: cast_nullable_to_non_nullable
as List<String>,actionsTaken: null == actionsTaken ? _self._actionsTaken : actionsTaken // ignore: cast_nullable_to_non_nullable
as List<String>,followUps: null == followUps ? _self._followUps : followUps // ignore: cast_nullable_to_non_nullable
as List<FollowUpModel>,actionStatuses: null == actionStatuses ? _self._actionStatuses : actionStatuses // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,externalRecords: null == externalRecords ? _self._externalRecords : externalRecords // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$FollowUpModel {

 String get description; String get priority;@JsonKey(name: 'due_date') DateTime? get dueDate;
/// Create a copy of FollowUpModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowUpModelCopyWith<FollowUpModel> get copyWith => _$FollowUpModelCopyWithImpl<FollowUpModel>(this as FollowUpModel, _$identity);

  /// Serializes this FollowUpModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowUpModel&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,priority,dueDate);

@override
String toString() {
  return 'FollowUpModel(description: $description, priority: $priority, dueDate: $dueDate)';
}


}

/// @nodoc
abstract mixin class $FollowUpModelCopyWith<$Res>  {
  factory $FollowUpModelCopyWith(FollowUpModel value, $Res Function(FollowUpModel) _then) = _$FollowUpModelCopyWithImpl;
@useResult
$Res call({
 String description, String priority,@JsonKey(name: 'due_date') DateTime? dueDate
});




}
/// @nodoc
class _$FollowUpModelCopyWithImpl<$Res>
    implements $FollowUpModelCopyWith<$Res> {
  _$FollowUpModelCopyWithImpl(this._self, this._then);

  final FollowUpModel _self;
  final $Res Function(FollowUpModel) _then;

/// Create a copy of FollowUpModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = null,Object? priority = null,Object? dueDate = freezed,}) {
  return _then(_self.copyWith(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowUpModel].
extension FollowUpModelPatterns on FollowUpModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowUpModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowUpModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowUpModel value)  $default,){
final _that = this;
switch (_that) {
case _FollowUpModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowUpModel value)?  $default,){
final _that = this;
switch (_that) {
case _FollowUpModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String description,  String priority, @JsonKey(name: 'due_date')  DateTime? dueDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowUpModel() when $default != null:
return $default(_that.description,_that.priority,_that.dueDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String description,  String priority, @JsonKey(name: 'due_date')  DateTime? dueDate)  $default,) {final _that = this;
switch (_that) {
case _FollowUpModel():
return $default(_that.description,_that.priority,_that.dueDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String description,  String priority, @JsonKey(name: 'due_date')  DateTime? dueDate)?  $default,) {final _that = this;
switch (_that) {
case _FollowUpModel() when $default != null:
return $default(_that.description,_that.priority,_that.dueDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowUpModel implements FollowUpModel {
  const _FollowUpModel({required this.description, this.priority = 'medium', @JsonKey(name: 'due_date') this.dueDate});
  factory _FollowUpModel.fromJson(Map<String, dynamic> json) => _$FollowUpModelFromJson(json);

@override final  String description;
@override@JsonKey() final  String priority;
@override@JsonKey(name: 'due_date') final  DateTime? dueDate;

/// Create a copy of FollowUpModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowUpModelCopyWith<_FollowUpModel> get copyWith => __$FollowUpModelCopyWithImpl<_FollowUpModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowUpModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowUpModel&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,priority,dueDate);

@override
String toString() {
  return 'FollowUpModel(description: $description, priority: $priority, dueDate: $dueDate)';
}


}

/// @nodoc
abstract mixin class _$FollowUpModelCopyWith<$Res> implements $FollowUpModelCopyWith<$Res> {
  factory _$FollowUpModelCopyWith(_FollowUpModel value, $Res Function(_FollowUpModel) _then) = __$FollowUpModelCopyWithImpl;
@override @useResult
$Res call({
 String description, String priority,@JsonKey(name: 'due_date') DateTime? dueDate
});




}
/// @nodoc
class __$FollowUpModelCopyWithImpl<$Res>
    implements _$FollowUpModelCopyWith<$Res> {
  __$FollowUpModelCopyWithImpl(this._self, this._then);

  final _FollowUpModel _self;
  final $Res Function(_FollowUpModel) _then;

/// Create a copy of FollowUpModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = null,Object? priority = null,Object? dueDate = freezed,}) {
  return _then(_FollowUpModel(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
