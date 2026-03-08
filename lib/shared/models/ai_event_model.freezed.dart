// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_event_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiEventModel {

 String get id;@JsonKey(name: 'session_id') String get sessionId; AiEventType get type; String get content; String get source; AiEventStatus get status;@JsonKey(name: 'requires_confirmation') bool get requiresConfirmation;@JsonKey(name: 'external_record_id') String? get externalRecordId;@JsonKey(name: 'external_record_url') String? get externalRecordUrl;@JsonKey(name: 'action_label') String? get actionLabel; Map<String, dynamic>? get metadata; double? get confidence;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of AiEventModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiEventModelCopyWith<AiEventModel> get copyWith => _$AiEventModelCopyWithImpl<AiEventModel>(this as AiEventModel, _$identity);

  /// Serializes this AiEventModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiEventModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.type, type) || other.type == type)&&(identical(other.content, content) || other.content == content)&&(identical(other.source, source) || other.source == source)&&(identical(other.status, status) || other.status == status)&&(identical(other.requiresConfirmation, requiresConfirmation) || other.requiresConfirmation == requiresConfirmation)&&(identical(other.externalRecordId, externalRecordId) || other.externalRecordId == externalRecordId)&&(identical(other.externalRecordUrl, externalRecordUrl) || other.externalRecordUrl == externalRecordUrl)&&(identical(other.actionLabel, actionLabel) || other.actionLabel == actionLabel)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,type,content,source,status,requiresConfirmation,externalRecordId,externalRecordUrl,actionLabel,const DeepCollectionEquality().hash(metadata),confidence,createdAt);

@override
String toString() {
  return 'AiEventModel(id: $id, sessionId: $sessionId, type: $type, content: $content, source: $source, status: $status, requiresConfirmation: $requiresConfirmation, externalRecordId: $externalRecordId, externalRecordUrl: $externalRecordUrl, actionLabel: $actionLabel, metadata: $metadata, confidence: $confidence, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AiEventModelCopyWith<$Res>  {
  factory $AiEventModelCopyWith(AiEventModel value, $Res Function(AiEventModel) _then) = _$AiEventModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'session_id') String sessionId, AiEventType type, String content, String source, AiEventStatus status,@JsonKey(name: 'requires_confirmation') bool requiresConfirmation,@JsonKey(name: 'external_record_id') String? externalRecordId,@JsonKey(name: 'external_record_url') String? externalRecordUrl,@JsonKey(name: 'action_label') String? actionLabel, Map<String, dynamic>? metadata, double? confidence,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$AiEventModelCopyWithImpl<$Res>
    implements $AiEventModelCopyWith<$Res> {
  _$AiEventModelCopyWithImpl(this._self, this._then);

  final AiEventModel _self;
  final $Res Function(AiEventModel) _then;

/// Create a copy of AiEventModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? type = null,Object? content = null,Object? source = null,Object? status = null,Object? requiresConfirmation = null,Object? externalRecordId = freezed,Object? externalRecordUrl = freezed,Object? actionLabel = freezed,Object? metadata = freezed,Object? confidence = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AiEventType,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AiEventStatus,requiresConfirmation: null == requiresConfirmation ? _self.requiresConfirmation : requiresConfirmation // ignore: cast_nullable_to_non_nullable
as bool,externalRecordId: freezed == externalRecordId ? _self.externalRecordId : externalRecordId // ignore: cast_nullable_to_non_nullable
as String?,externalRecordUrl: freezed == externalRecordUrl ? _self.externalRecordUrl : externalRecordUrl // ignore: cast_nullable_to_non_nullable
as String?,actionLabel: freezed == actionLabel ? _self.actionLabel : actionLabel // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AiEventModel].
extension AiEventModelPatterns on AiEventModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiEventModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiEventModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiEventModel value)  $default,){
final _that = this;
switch (_that) {
case _AiEventModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiEventModel value)?  $default,){
final _that = this;
switch (_that) {
case _AiEventModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'session_id')  String sessionId,  AiEventType type,  String content,  String source,  AiEventStatus status, @JsonKey(name: 'requires_confirmation')  bool requiresConfirmation, @JsonKey(name: 'external_record_id')  String? externalRecordId, @JsonKey(name: 'external_record_url')  String? externalRecordUrl, @JsonKey(name: 'action_label')  String? actionLabel,  Map<String, dynamic>? metadata,  double? confidence, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiEventModel() when $default != null:
return $default(_that.id,_that.sessionId,_that.type,_that.content,_that.source,_that.status,_that.requiresConfirmation,_that.externalRecordId,_that.externalRecordUrl,_that.actionLabel,_that.metadata,_that.confidence,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'session_id')  String sessionId,  AiEventType type,  String content,  String source,  AiEventStatus status, @JsonKey(name: 'requires_confirmation')  bool requiresConfirmation, @JsonKey(name: 'external_record_id')  String? externalRecordId, @JsonKey(name: 'external_record_url')  String? externalRecordUrl, @JsonKey(name: 'action_label')  String? actionLabel,  Map<String, dynamic>? metadata,  double? confidence, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AiEventModel():
return $default(_that.id,_that.sessionId,_that.type,_that.content,_that.source,_that.status,_that.requiresConfirmation,_that.externalRecordId,_that.externalRecordUrl,_that.actionLabel,_that.metadata,_that.confidence,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'session_id')  String sessionId,  AiEventType type,  String content,  String source,  AiEventStatus status, @JsonKey(name: 'requires_confirmation')  bool requiresConfirmation, @JsonKey(name: 'external_record_id')  String? externalRecordId, @JsonKey(name: 'external_record_url')  String? externalRecordUrl, @JsonKey(name: 'action_label')  String? actionLabel,  Map<String, dynamic>? metadata,  double? confidence, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AiEventModel() when $default != null:
return $default(_that.id,_that.sessionId,_that.type,_that.content,_that.source,_that.status,_that.requiresConfirmation,_that.externalRecordId,_that.externalRecordUrl,_that.actionLabel,_that.metadata,_that.confidence,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AiEventModel implements AiEventModel {
  const _AiEventModel({required this.id, @JsonKey(name: 'session_id') required this.sessionId, required this.type, required this.content, this.source = 'ai', this.status = AiEventStatus.completed, @JsonKey(name: 'requires_confirmation') this.requiresConfirmation = false, @JsonKey(name: 'external_record_id') this.externalRecordId, @JsonKey(name: 'external_record_url') this.externalRecordUrl, @JsonKey(name: 'action_label') this.actionLabel, final  Map<String, dynamic>? metadata, this.confidence, @JsonKey(name: 'created_at') this.createdAt}): _metadata = metadata;
  factory _AiEventModel.fromJson(Map<String, dynamic> json) => _$AiEventModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'session_id') final  String sessionId;
@override final  AiEventType type;
@override final  String content;
@override@JsonKey() final  String source;
@override@JsonKey() final  AiEventStatus status;
@override@JsonKey(name: 'requires_confirmation') final  bool requiresConfirmation;
@override@JsonKey(name: 'external_record_id') final  String? externalRecordId;
@override@JsonKey(name: 'external_record_url') final  String? externalRecordUrl;
@override@JsonKey(name: 'action_label') final  String? actionLabel;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  double? confidence;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of AiEventModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiEventModelCopyWith<_AiEventModel> get copyWith => __$AiEventModelCopyWithImpl<_AiEventModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiEventModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiEventModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.type, type) || other.type == type)&&(identical(other.content, content) || other.content == content)&&(identical(other.source, source) || other.source == source)&&(identical(other.status, status) || other.status == status)&&(identical(other.requiresConfirmation, requiresConfirmation) || other.requiresConfirmation == requiresConfirmation)&&(identical(other.externalRecordId, externalRecordId) || other.externalRecordId == externalRecordId)&&(identical(other.externalRecordUrl, externalRecordUrl) || other.externalRecordUrl == externalRecordUrl)&&(identical(other.actionLabel, actionLabel) || other.actionLabel == actionLabel)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,type,content,source,status,requiresConfirmation,externalRecordId,externalRecordUrl,actionLabel,const DeepCollectionEquality().hash(_metadata),confidence,createdAt);

@override
String toString() {
  return 'AiEventModel(id: $id, sessionId: $sessionId, type: $type, content: $content, source: $source, status: $status, requiresConfirmation: $requiresConfirmation, externalRecordId: $externalRecordId, externalRecordUrl: $externalRecordUrl, actionLabel: $actionLabel, metadata: $metadata, confidence: $confidence, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AiEventModelCopyWith<$Res> implements $AiEventModelCopyWith<$Res> {
  factory _$AiEventModelCopyWith(_AiEventModel value, $Res Function(_AiEventModel) _then) = __$AiEventModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'session_id') String sessionId, AiEventType type, String content, String source, AiEventStatus status,@JsonKey(name: 'requires_confirmation') bool requiresConfirmation,@JsonKey(name: 'external_record_id') String? externalRecordId,@JsonKey(name: 'external_record_url') String? externalRecordUrl,@JsonKey(name: 'action_label') String? actionLabel, Map<String, dynamic>? metadata, double? confidence,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$AiEventModelCopyWithImpl<$Res>
    implements _$AiEventModelCopyWith<$Res> {
  __$AiEventModelCopyWithImpl(this._self, this._then);

  final _AiEventModel _self;
  final $Res Function(_AiEventModel) _then;

/// Create a copy of AiEventModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? type = null,Object? content = null,Object? source = null,Object? status = null,Object? requiresConfirmation = null,Object? externalRecordId = freezed,Object? externalRecordUrl = freezed,Object? actionLabel = freezed,Object? metadata = freezed,Object? confidence = freezed,Object? createdAt = freezed,}) {
  return _then(_AiEventModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AiEventType,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AiEventStatus,requiresConfirmation: null == requiresConfirmation ? _self.requiresConfirmation : requiresConfirmation // ignore: cast_nullable_to_non_nullable
as bool,externalRecordId: freezed == externalRecordId ? _self.externalRecordId : externalRecordId // ignore: cast_nullable_to_non_nullable
as String?,externalRecordUrl: freezed == externalRecordUrl ? _self.externalRecordUrl : externalRecordUrl // ignore: cast_nullable_to_non_nullable
as String?,actionLabel: freezed == actionLabel ? _self.actionLabel : actionLabel // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
