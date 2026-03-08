// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_attachment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaAttachmentModel {

 String get id;@JsonKey(name: 'session_id') String get sessionId; MediaType get type;@JsonKey(name: 'storage_path') String get storagePath;@JsonKey(name: 'thumbnail_path') String? get thumbnailPath;@JsonKey(name: 'ai_analysis') String? get aiAnalysis;@JsonKey(name: 'mime_type') String? get mimeType;@JsonKey(name: 'file_size_bytes') int? get fileSizeBytes;@JsonKey(name: 'analysis_status') String get analysisStatus; Map<String, dynamic> get metadata;@JsonKey(name: 'uploaded_at') DateTime? get uploadedAt;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of MediaAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaAttachmentModelCopyWith<MediaAttachmentModel> get copyWith => _$MediaAttachmentModelCopyWithImpl<MediaAttachmentModel>(this as MediaAttachmentModel, _$identity);

  /// Serializes this MediaAttachmentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaAttachmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.type, type) || other.type == type)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.aiAnalysis, aiAnalysis) || other.aiAnalysis == aiAnalysis)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileSizeBytes, fileSizeBytes) || other.fileSizeBytes == fileSizeBytes)&&(identical(other.analysisStatus, analysisStatus) || other.analysisStatus == analysisStatus)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,type,storagePath,thumbnailPath,aiAnalysis,mimeType,fileSizeBytes,analysisStatus,const DeepCollectionEquality().hash(metadata),uploadedAt,createdAt);

@override
String toString() {
  return 'MediaAttachmentModel(id: $id, sessionId: $sessionId, type: $type, storagePath: $storagePath, thumbnailPath: $thumbnailPath, aiAnalysis: $aiAnalysis, mimeType: $mimeType, fileSizeBytes: $fileSizeBytes, analysisStatus: $analysisStatus, metadata: $metadata, uploadedAt: $uploadedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MediaAttachmentModelCopyWith<$Res>  {
  factory $MediaAttachmentModelCopyWith(MediaAttachmentModel value, $Res Function(MediaAttachmentModel) _then) = _$MediaAttachmentModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'session_id') String sessionId, MediaType type,@JsonKey(name: 'storage_path') String storagePath,@JsonKey(name: 'thumbnail_path') String? thumbnailPath,@JsonKey(name: 'ai_analysis') String? aiAnalysis,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'file_size_bytes') int? fileSizeBytes,@JsonKey(name: 'analysis_status') String analysisStatus, Map<String, dynamic> metadata,@JsonKey(name: 'uploaded_at') DateTime? uploadedAt,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$MediaAttachmentModelCopyWithImpl<$Res>
    implements $MediaAttachmentModelCopyWith<$Res> {
  _$MediaAttachmentModelCopyWithImpl(this._self, this._then);

  final MediaAttachmentModel _self;
  final $Res Function(MediaAttachmentModel) _then;

/// Create a copy of MediaAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? type = null,Object? storagePath = null,Object? thumbnailPath = freezed,Object? aiAnalysis = freezed,Object? mimeType = freezed,Object? fileSizeBytes = freezed,Object? analysisStatus = null,Object? metadata = null,Object? uploadedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MediaType,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,aiAnalysis: freezed == aiAnalysis ? _self.aiAnalysis : aiAnalysis // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,fileSizeBytes: freezed == fileSizeBytes ? _self.fileSizeBytes : fileSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,analysisStatus: null == analysisStatus ? _self.analysisStatus : analysisStatus // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaAttachmentModel].
extension MediaAttachmentModelPatterns on MediaAttachmentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaAttachmentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaAttachmentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaAttachmentModel value)  $default,){
final _that = this;
switch (_that) {
case _MediaAttachmentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaAttachmentModel value)?  $default,){
final _that = this;
switch (_that) {
case _MediaAttachmentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'session_id')  String sessionId,  MediaType type, @JsonKey(name: 'storage_path')  String storagePath, @JsonKey(name: 'thumbnail_path')  String? thumbnailPath, @JsonKey(name: 'ai_analysis')  String? aiAnalysis, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'file_size_bytes')  int? fileSizeBytes, @JsonKey(name: 'analysis_status')  String analysisStatus,  Map<String, dynamic> metadata, @JsonKey(name: 'uploaded_at')  DateTime? uploadedAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaAttachmentModel() when $default != null:
return $default(_that.id,_that.sessionId,_that.type,_that.storagePath,_that.thumbnailPath,_that.aiAnalysis,_that.mimeType,_that.fileSizeBytes,_that.analysisStatus,_that.metadata,_that.uploadedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'session_id')  String sessionId,  MediaType type, @JsonKey(name: 'storage_path')  String storagePath, @JsonKey(name: 'thumbnail_path')  String? thumbnailPath, @JsonKey(name: 'ai_analysis')  String? aiAnalysis, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'file_size_bytes')  int? fileSizeBytes, @JsonKey(name: 'analysis_status')  String analysisStatus,  Map<String, dynamic> metadata, @JsonKey(name: 'uploaded_at')  DateTime? uploadedAt, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _MediaAttachmentModel():
return $default(_that.id,_that.sessionId,_that.type,_that.storagePath,_that.thumbnailPath,_that.aiAnalysis,_that.mimeType,_that.fileSizeBytes,_that.analysisStatus,_that.metadata,_that.uploadedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'session_id')  String sessionId,  MediaType type, @JsonKey(name: 'storage_path')  String storagePath, @JsonKey(name: 'thumbnail_path')  String? thumbnailPath, @JsonKey(name: 'ai_analysis')  String? aiAnalysis, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'file_size_bytes')  int? fileSizeBytes, @JsonKey(name: 'analysis_status')  String analysisStatus,  Map<String, dynamic> metadata, @JsonKey(name: 'uploaded_at')  DateTime? uploadedAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MediaAttachmentModel() when $default != null:
return $default(_that.id,_that.sessionId,_that.type,_that.storagePath,_that.thumbnailPath,_that.aiAnalysis,_that.mimeType,_that.fileSizeBytes,_that.analysisStatus,_that.metadata,_that.uploadedAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaAttachmentModel implements MediaAttachmentModel {
  const _MediaAttachmentModel({required this.id, @JsonKey(name: 'session_id') required this.sessionId, required this.type, @JsonKey(name: 'storage_path') required this.storagePath, @JsonKey(name: 'thumbnail_path') this.thumbnailPath, @JsonKey(name: 'ai_analysis') this.aiAnalysis, @JsonKey(name: 'mime_type') this.mimeType, @JsonKey(name: 'file_size_bytes') this.fileSizeBytes, @JsonKey(name: 'analysis_status') this.analysisStatus = 'pending', final  Map<String, dynamic> metadata = const <String, dynamic>{}, @JsonKey(name: 'uploaded_at') this.uploadedAt, @JsonKey(name: 'created_at') this.createdAt}): _metadata = metadata;
  factory _MediaAttachmentModel.fromJson(Map<String, dynamic> json) => _$MediaAttachmentModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'session_id') final  String sessionId;
@override final  MediaType type;
@override@JsonKey(name: 'storage_path') final  String storagePath;
@override@JsonKey(name: 'thumbnail_path') final  String? thumbnailPath;
@override@JsonKey(name: 'ai_analysis') final  String? aiAnalysis;
@override@JsonKey(name: 'mime_type') final  String? mimeType;
@override@JsonKey(name: 'file_size_bytes') final  int? fileSizeBytes;
@override@JsonKey(name: 'analysis_status') final  String analysisStatus;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override@JsonKey(name: 'uploaded_at') final  DateTime? uploadedAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of MediaAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaAttachmentModelCopyWith<_MediaAttachmentModel> get copyWith => __$MediaAttachmentModelCopyWithImpl<_MediaAttachmentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaAttachmentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaAttachmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.type, type) || other.type == type)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.aiAnalysis, aiAnalysis) || other.aiAnalysis == aiAnalysis)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileSizeBytes, fileSizeBytes) || other.fileSizeBytes == fileSizeBytes)&&(identical(other.analysisStatus, analysisStatus) || other.analysisStatus == analysisStatus)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,type,storagePath,thumbnailPath,aiAnalysis,mimeType,fileSizeBytes,analysisStatus,const DeepCollectionEquality().hash(_metadata),uploadedAt,createdAt);

@override
String toString() {
  return 'MediaAttachmentModel(id: $id, sessionId: $sessionId, type: $type, storagePath: $storagePath, thumbnailPath: $thumbnailPath, aiAnalysis: $aiAnalysis, mimeType: $mimeType, fileSizeBytes: $fileSizeBytes, analysisStatus: $analysisStatus, metadata: $metadata, uploadedAt: $uploadedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MediaAttachmentModelCopyWith<$Res> implements $MediaAttachmentModelCopyWith<$Res> {
  factory _$MediaAttachmentModelCopyWith(_MediaAttachmentModel value, $Res Function(_MediaAttachmentModel) _then) = __$MediaAttachmentModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'session_id') String sessionId, MediaType type,@JsonKey(name: 'storage_path') String storagePath,@JsonKey(name: 'thumbnail_path') String? thumbnailPath,@JsonKey(name: 'ai_analysis') String? aiAnalysis,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'file_size_bytes') int? fileSizeBytes,@JsonKey(name: 'analysis_status') String analysisStatus, Map<String, dynamic> metadata,@JsonKey(name: 'uploaded_at') DateTime? uploadedAt,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$MediaAttachmentModelCopyWithImpl<$Res>
    implements _$MediaAttachmentModelCopyWith<$Res> {
  __$MediaAttachmentModelCopyWithImpl(this._self, this._then);

  final _MediaAttachmentModel _self;
  final $Res Function(_MediaAttachmentModel) _then;

/// Create a copy of MediaAttachmentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? type = null,Object? storagePath = null,Object? thumbnailPath = freezed,Object? aiAnalysis = freezed,Object? mimeType = freezed,Object? fileSizeBytes = freezed,Object? analysisStatus = null,Object? metadata = null,Object? uploadedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_MediaAttachmentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MediaType,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,aiAnalysis: freezed == aiAnalysis ? _self.aiAnalysis : aiAnalysis // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,fileSizeBytes: freezed == fileSizeBytes ? _self.fileSizeBytes : fileSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,analysisStatus: null == analysisStatus ? _self.analysisStatus : analysisStatus // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
