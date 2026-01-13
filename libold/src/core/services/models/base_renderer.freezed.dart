// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'base_renderer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Renderer {
  Object get data;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Renderer &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  @override
  String toString() {
    return 'Renderer(data: $data)';
  }
}

/// @nodoc
class $RendererCopyWith<$Res> {
  $RendererCopyWith(Renderer _, $Res Function(Renderer) __);
}

/// Adds pattern-matching-related methods to [Renderer].
extension RendererPatterns on Renderer {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_MusicResponsiveListItem value)? musicResponsiveListItem,
    TResult Function(_MusicTwoRowItem value)? musicTwoRowItem,
    TResult Function(_MusicCarouselShelf value)? musicCarouselShelf,
    TResult Function(_MusicShelf value)? musicShelf,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MusicResponsiveListItem() when musicResponsiveListItem != null:
        return musicResponsiveListItem(_that);
      case _MusicTwoRowItem() when musicTwoRowItem != null:
        return musicTwoRowItem(_that);
      case _MusicCarouselShelf() when musicCarouselShelf != null:
        return musicCarouselShelf(_that);
      case _MusicShelf() when musicShelf != null:
        return musicShelf(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_MusicResponsiveListItem value)
        musicResponsiveListItem,
    required TResult Function(_MusicTwoRowItem value) musicTwoRowItem,
    required TResult Function(_MusicCarouselShelf value) musicCarouselShelf,
    required TResult Function(_MusicShelf value) musicShelf,
  }) {
    final _that = this;
    switch (_that) {
      case _MusicResponsiveListItem():
        return musicResponsiveListItem(_that);
      case _MusicTwoRowItem():
        return musicTwoRowItem(_that);
      case _MusicCarouselShelf():
        return musicCarouselShelf(_that);
      case _MusicShelf():
        return musicShelf(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_MusicResponsiveListItem value)? musicResponsiveListItem,
    TResult? Function(_MusicTwoRowItem value)? musicTwoRowItem,
    TResult? Function(_MusicCarouselShelf value)? musicCarouselShelf,
    TResult? Function(_MusicShelf value)? musicShelf,
  }) {
    final _that = this;
    switch (_that) {
      case _MusicResponsiveListItem() when musicResponsiveListItem != null:
        return musicResponsiveListItem(_that);
      case _MusicTwoRowItem() when musicTwoRowItem != null:
        return musicTwoRowItem(_that);
      case _MusicCarouselShelf() when musicCarouselShelf != null:
        return musicCarouselShelf(_that);
      case _MusicShelf() when musicShelf != null:
        return musicShelf(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(RendererMusicResponsiveListItem data)?
        musicResponsiveListItem,
    TResult Function(RendererMusicTwoRowItem data)? musicTwoRowItem,
    TResult Function(RendererMusicCarouselShelf data)? musicCarouselShelf,
    TResult Function(RendererMusicShelf data)? musicShelf,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MusicResponsiveListItem() when musicResponsiveListItem != null:
        return musicResponsiveListItem(_that.data);
      case _MusicTwoRowItem() when musicTwoRowItem != null:
        return musicTwoRowItem(_that.data);
      case _MusicCarouselShelf() when musicCarouselShelf != null:
        return musicCarouselShelf(_that.data);
      case _MusicShelf() when musicShelf != null:
        return musicShelf(_that.data);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(RendererMusicResponsiveListItem data)
        musicResponsiveListItem,
    required TResult Function(RendererMusicTwoRowItem data) musicTwoRowItem,
    required TResult Function(RendererMusicCarouselShelf data)
        musicCarouselShelf,
    required TResult Function(RendererMusicShelf data) musicShelf,
  }) {
    final _that = this;
    switch (_that) {
      case _MusicResponsiveListItem():
        return musicResponsiveListItem(_that.data);
      case _MusicTwoRowItem():
        return musicTwoRowItem(_that.data);
      case _MusicCarouselShelf():
        return musicCarouselShelf(_that.data);
      case _MusicShelf():
        return musicShelf(_that.data);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(RendererMusicResponsiveListItem data)?
        musicResponsiveListItem,
    TResult? Function(RendererMusicTwoRowItem data)? musicTwoRowItem,
    TResult? Function(RendererMusicCarouselShelf data)? musicCarouselShelf,
    TResult? Function(RendererMusicShelf data)? musicShelf,
  }) {
    final _that = this;
    switch (_that) {
      case _MusicResponsiveListItem() when musicResponsiveListItem != null:
        return musicResponsiveListItem(_that.data);
      case _MusicTwoRowItem() when musicTwoRowItem != null:
        return musicTwoRowItem(_that.data);
      case _MusicCarouselShelf() when musicCarouselShelf != null:
        return musicCarouselShelf(_that.data);
      case _MusicShelf() when musicShelf != null:
        return musicShelf(_that.data);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MusicResponsiveListItem extends Renderer {
  const _MusicResponsiveListItem(this.data) : super._();

  @override
  final RendererMusicResponsiveListItem data;

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MusicResponsiveListItemCopyWith<_MusicResponsiveListItem> get copyWith =>
      __$MusicResponsiveListItemCopyWithImpl<_MusicResponsiveListItem>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MusicResponsiveListItem &&
            (identical(other.data, data) || other.data == data));
  }

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() {
    return 'Renderer.musicResponsiveListItem(data: $data)';
  }
}

/// @nodoc
abstract mixin class _$MusicResponsiveListItemCopyWith<$Res>
    implements $RendererCopyWith<$Res> {
  factory _$MusicResponsiveListItemCopyWith(_MusicResponsiveListItem value,
          $Res Function(_MusicResponsiveListItem) _then) =
      __$MusicResponsiveListItemCopyWithImpl;
  @useResult
  $Res call({RendererMusicResponsiveListItem data});

  $RendererMusicResponsiveListItemCopyWith<$Res> get data;
}

/// @nodoc
class __$MusicResponsiveListItemCopyWithImpl<$Res>
    implements _$MusicResponsiveListItemCopyWith<$Res> {
  __$MusicResponsiveListItemCopyWithImpl(this._self, this._then);

  final _MusicResponsiveListItem _self;
  final $Res Function(_MusicResponsiveListItem) _then;

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? data = null,
  }) {
    return _then(_MusicResponsiveListItem(
      null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as RendererMusicResponsiveListItem,
    ));
  }

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RendererMusicResponsiveListItemCopyWith<$Res> get data {
    return $RendererMusicResponsiveListItemCopyWith<$Res>(_self.data, (value) {
      return _then(_self.copyWith(data: value));
    });
  }
}

/// @nodoc

class _MusicTwoRowItem extends Renderer {
  const _MusicTwoRowItem(this.data) : super._();

  @override
  final RendererMusicTwoRowItem data;

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MusicTwoRowItemCopyWith<_MusicTwoRowItem> get copyWith =>
      __$MusicTwoRowItemCopyWithImpl<_MusicTwoRowItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MusicTwoRowItem &&
            (identical(other.data, data) || other.data == data));
  }

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() {
    return 'Renderer.musicTwoRowItem(data: $data)';
  }
}

/// @nodoc
abstract mixin class _$MusicTwoRowItemCopyWith<$Res>
    implements $RendererCopyWith<$Res> {
  factory _$MusicTwoRowItemCopyWith(
          _MusicTwoRowItem value, $Res Function(_MusicTwoRowItem) _then) =
      __$MusicTwoRowItemCopyWithImpl;
  @useResult
  $Res call({RendererMusicTwoRowItem data});

  $RendererMusicTwoRowItemCopyWith<$Res> get data;
}

/// @nodoc
class __$MusicTwoRowItemCopyWithImpl<$Res>
    implements _$MusicTwoRowItemCopyWith<$Res> {
  __$MusicTwoRowItemCopyWithImpl(this._self, this._then);

  final _MusicTwoRowItem _self;
  final $Res Function(_MusicTwoRowItem) _then;

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? data = null,
  }) {
    return _then(_MusicTwoRowItem(
      null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as RendererMusicTwoRowItem,
    ));
  }

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RendererMusicTwoRowItemCopyWith<$Res> get data {
    return $RendererMusicTwoRowItemCopyWith<$Res>(_self.data, (value) {
      return _then(_self.copyWith(data: value));
    });
  }
}

/// @nodoc

class _MusicCarouselShelf extends Renderer {
  const _MusicCarouselShelf(this.data) : super._();

  @override
  final RendererMusicCarouselShelf data;

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MusicCarouselShelfCopyWith<_MusicCarouselShelf> get copyWith =>
      __$MusicCarouselShelfCopyWithImpl<_MusicCarouselShelf>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MusicCarouselShelf &&
            (identical(other.data, data) || other.data == data));
  }

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() {
    return 'Renderer.musicCarouselShelf(data: $data)';
  }
}

/// @nodoc
abstract mixin class _$MusicCarouselShelfCopyWith<$Res>
    implements $RendererCopyWith<$Res> {
  factory _$MusicCarouselShelfCopyWith(
          _MusicCarouselShelf value, $Res Function(_MusicCarouselShelf) _then) =
      __$MusicCarouselShelfCopyWithImpl;
  @useResult
  $Res call({RendererMusicCarouselShelf data});

  $RendererMusicCarouselShelfCopyWith<$Res> get data;
}

/// @nodoc
class __$MusicCarouselShelfCopyWithImpl<$Res>
    implements _$MusicCarouselShelfCopyWith<$Res> {
  __$MusicCarouselShelfCopyWithImpl(this._self, this._then);

  final _MusicCarouselShelf _self;
  final $Res Function(_MusicCarouselShelf) _then;

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? data = null,
  }) {
    return _then(_MusicCarouselShelf(
      null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as RendererMusicCarouselShelf,
    ));
  }

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RendererMusicCarouselShelfCopyWith<$Res> get data {
    return $RendererMusicCarouselShelfCopyWith<$Res>(_self.data, (value) {
      return _then(_self.copyWith(data: value));
    });
  }
}

/// @nodoc

class _MusicShelf extends Renderer {
  const _MusicShelf(this.data) : super._();

  @override
  final RendererMusicShelf data;

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MusicShelfCopyWith<_MusicShelf> get copyWith =>
      __$MusicShelfCopyWithImpl<_MusicShelf>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MusicShelf &&
            (identical(other.data, data) || other.data == data));
  }

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() {
    return 'Renderer.musicShelf(data: $data)';
  }
}

/// @nodoc
abstract mixin class _$MusicShelfCopyWith<$Res>
    implements $RendererCopyWith<$Res> {
  factory _$MusicShelfCopyWith(
          _MusicShelf value, $Res Function(_MusicShelf) _then) =
      __$MusicShelfCopyWithImpl;
  @useResult
  $Res call({RendererMusicShelf data});

  $RendererMusicShelfCopyWith<$Res> get data;
}

/// @nodoc
class __$MusicShelfCopyWithImpl<$Res> implements _$MusicShelfCopyWith<$Res> {
  __$MusicShelfCopyWithImpl(this._self, this._then);

  final _MusicShelf _self;
  final $Res Function(_MusicShelf) _then;

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? data = null,
  }) {
    return _then(_MusicShelf(
      null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as RendererMusicShelf,
    ));
  }

  /// Create a copy of Renderer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RendererMusicShelfCopyWith<$Res> get data {
    return $RendererMusicShelfCopyWith<$Res>(_self.data, (value) {
      return _then(_self.copyWith(data: value));
    });
  }
}

/// @nodoc
mixin _$RendererMusicResponsiveListItem {
  Map<String, dynamic> get flexColumns;
  Map<String, dynamic> get thumbnail;
  Map<String, dynamic> get overlay;
  Map<String, dynamic> get navigationEndpoint;

  /// Create a copy of RendererMusicResponsiveListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RendererMusicResponsiveListItemCopyWith<RendererMusicResponsiveListItem>
      get copyWith => _$RendererMusicResponsiveListItemCopyWithImpl<
              RendererMusicResponsiveListItem>(
          this as RendererMusicResponsiveListItem, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RendererMusicResponsiveListItem &&
            const DeepCollectionEquality()
                .equals(other.flexColumns, flexColumns) &&
            const DeepCollectionEquality().equals(other.thumbnail, thumbnail) &&
            const DeepCollectionEquality().equals(other.overlay, overlay) &&
            const DeepCollectionEquality()
                .equals(other.navigationEndpoint, navigationEndpoint));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(flexColumns),
      const DeepCollectionEquality().hash(thumbnail),
      const DeepCollectionEquality().hash(overlay),
      const DeepCollectionEquality().hash(navigationEndpoint));

  @override
  String toString() {
    return 'RendererMusicResponsiveListItem(flexColumns: $flexColumns, thumbnail: $thumbnail, overlay: $overlay, navigationEndpoint: $navigationEndpoint)';
  }
}

/// @nodoc
abstract mixin class $RendererMusicResponsiveListItemCopyWith<$Res> {
  factory $RendererMusicResponsiveListItemCopyWith(
          RendererMusicResponsiveListItem value,
          $Res Function(RendererMusicResponsiveListItem) _then) =
      _$RendererMusicResponsiveListItemCopyWithImpl;
  @useResult
  $Res call(
      {Map<String, dynamic> flexColumns,
      Map<String, dynamic> thumbnail,
      Map<String, dynamic> overlay,
      Map<String, dynamic> navigationEndpoint});
}

/// @nodoc
class _$RendererMusicResponsiveListItemCopyWithImpl<$Res>
    implements $RendererMusicResponsiveListItemCopyWith<$Res> {
  _$RendererMusicResponsiveListItemCopyWithImpl(this._self, this._then);

  final RendererMusicResponsiveListItem _self;
  final $Res Function(RendererMusicResponsiveListItem) _then;

  /// Create a copy of RendererMusicResponsiveListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? flexColumns = null,
    Object? thumbnail = null,
    Object? overlay = null,
    Object? navigationEndpoint = null,
  }) {
    return _then(_self.copyWith(
      flexColumns: null == flexColumns
          ? _self.flexColumns
          : flexColumns // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      thumbnail: null == thumbnail
          ? _self.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      overlay: null == overlay
          ? _self.overlay
          : overlay // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      navigationEndpoint: null == navigationEndpoint
          ? _self.navigationEndpoint
          : navigationEndpoint // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RendererMusicResponsiveListItem].
extension RendererMusicResponsiveListItemPatterns
    on RendererMusicResponsiveListItem {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RendererMusicResponsiveListItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RendererMusicResponsiveListItem() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RendererMusicResponsiveListItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicResponsiveListItem():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RendererMusicResponsiveListItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicResponsiveListItem() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            Map<String, dynamic> flexColumns,
            Map<String, dynamic> thumbnail,
            Map<String, dynamic> overlay,
            Map<String, dynamic> navigationEndpoint)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RendererMusicResponsiveListItem() when $default != null:
        return $default(_that.flexColumns, _that.thumbnail, _that.overlay,
            _that.navigationEndpoint);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            Map<String, dynamic> flexColumns,
            Map<String, dynamic> thumbnail,
            Map<String, dynamic> overlay,
            Map<String, dynamic> navigationEndpoint)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicResponsiveListItem():
        return $default(_that.flexColumns, _that.thumbnail, _that.overlay,
            _that.navigationEndpoint);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            Map<String, dynamic> flexColumns,
            Map<String, dynamic> thumbnail,
            Map<String, dynamic> overlay,
            Map<String, dynamic> navigationEndpoint)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicResponsiveListItem() when $default != null:
        return $default(_that.flexColumns, _that.thumbnail, _that.overlay,
            _that.navigationEndpoint);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RendererMusicResponsiveListItem
    implements RendererMusicResponsiveListItem {
  const _RendererMusicResponsiveListItem(
      {required final Map<String, dynamic> flexColumns,
      required final Map<String, dynamic> thumbnail,
      required final Map<String, dynamic> overlay,
      required final Map<String, dynamic> navigationEndpoint})
      : _flexColumns = flexColumns,
        _thumbnail = thumbnail,
        _overlay = overlay,
        _navigationEndpoint = navigationEndpoint;

  final Map<String, dynamic> _flexColumns;
  @override
  Map<String, dynamic> get flexColumns {
    if (_flexColumns is EqualUnmodifiableMapView) return _flexColumns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_flexColumns);
  }

  final Map<String, dynamic> _thumbnail;
  @override
  Map<String, dynamic> get thumbnail {
    if (_thumbnail is EqualUnmodifiableMapView) return _thumbnail;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_thumbnail);
  }

  final Map<String, dynamic> _overlay;
  @override
  Map<String, dynamic> get overlay {
    if (_overlay is EqualUnmodifiableMapView) return _overlay;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_overlay);
  }

  final Map<String, dynamic> _navigationEndpoint;
  @override
  Map<String, dynamic> get navigationEndpoint {
    if (_navigationEndpoint is EqualUnmodifiableMapView)
      return _navigationEndpoint;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_navigationEndpoint);
  }

  /// Create a copy of RendererMusicResponsiveListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RendererMusicResponsiveListItemCopyWith<_RendererMusicResponsiveListItem>
      get copyWith => __$RendererMusicResponsiveListItemCopyWithImpl<
          _RendererMusicResponsiveListItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RendererMusicResponsiveListItem &&
            const DeepCollectionEquality()
                .equals(other._flexColumns, _flexColumns) &&
            const DeepCollectionEquality()
                .equals(other._thumbnail, _thumbnail) &&
            const DeepCollectionEquality().equals(other._overlay, _overlay) &&
            const DeepCollectionEquality()
                .equals(other._navigationEndpoint, _navigationEndpoint));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_flexColumns),
      const DeepCollectionEquality().hash(_thumbnail),
      const DeepCollectionEquality().hash(_overlay),
      const DeepCollectionEquality().hash(_navigationEndpoint));

  @override
  String toString() {
    return 'RendererMusicResponsiveListItem(flexColumns: $flexColumns, thumbnail: $thumbnail, overlay: $overlay, navigationEndpoint: $navigationEndpoint)';
  }
}

/// @nodoc
abstract mixin class _$RendererMusicResponsiveListItemCopyWith<$Res>
    implements $RendererMusicResponsiveListItemCopyWith<$Res> {
  factory _$RendererMusicResponsiveListItemCopyWith(
          _RendererMusicResponsiveListItem value,
          $Res Function(_RendererMusicResponsiveListItem) _then) =
      __$RendererMusicResponsiveListItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {Map<String, dynamic> flexColumns,
      Map<String, dynamic> thumbnail,
      Map<String, dynamic> overlay,
      Map<String, dynamic> navigationEndpoint});
}

/// @nodoc
class __$RendererMusicResponsiveListItemCopyWithImpl<$Res>
    implements _$RendererMusicResponsiveListItemCopyWith<$Res> {
  __$RendererMusicResponsiveListItemCopyWithImpl(this._self, this._then);

  final _RendererMusicResponsiveListItem _self;
  final $Res Function(_RendererMusicResponsiveListItem) _then;

  /// Create a copy of RendererMusicResponsiveListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? flexColumns = null,
    Object? thumbnail = null,
    Object? overlay = null,
    Object? navigationEndpoint = null,
  }) {
    return _then(_RendererMusicResponsiveListItem(
      flexColumns: null == flexColumns
          ? _self._flexColumns
          : flexColumns // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      thumbnail: null == thumbnail
          ? _self._thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      overlay: null == overlay
          ? _self._overlay
          : overlay // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      navigationEndpoint: null == navigationEndpoint
          ? _self._navigationEndpoint
          : navigationEndpoint // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
mixin _$RendererMusicTwoRowItem {
  Map<String, dynamic> get title;
  Map<String, dynamic> get subtitle;
  Map<String, dynamic> get navigationEndpoint;
  Map<String, dynamic> get thumbnailRenderer;

  /// Create a copy of RendererMusicTwoRowItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RendererMusicTwoRowItemCopyWith<RendererMusicTwoRowItem> get copyWith =>
      _$RendererMusicTwoRowItemCopyWithImpl<RendererMusicTwoRowItem>(
          this as RendererMusicTwoRowItem, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RendererMusicTwoRowItem &&
            const DeepCollectionEquality().equals(other.title, title) &&
            const DeepCollectionEquality().equals(other.subtitle, subtitle) &&
            const DeepCollectionEquality()
                .equals(other.navigationEndpoint, navigationEndpoint) &&
            const DeepCollectionEquality()
                .equals(other.thumbnailRenderer, thumbnailRenderer));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(title),
      const DeepCollectionEquality().hash(subtitle),
      const DeepCollectionEquality().hash(navigationEndpoint),
      const DeepCollectionEquality().hash(thumbnailRenderer));

  @override
  String toString() {
    return 'RendererMusicTwoRowItem(title: $title, subtitle: $subtitle, navigationEndpoint: $navigationEndpoint, thumbnailRenderer: $thumbnailRenderer)';
  }
}

/// @nodoc
abstract mixin class $RendererMusicTwoRowItemCopyWith<$Res> {
  factory $RendererMusicTwoRowItemCopyWith(RendererMusicTwoRowItem value,
          $Res Function(RendererMusicTwoRowItem) _then) =
      _$RendererMusicTwoRowItemCopyWithImpl;
  @useResult
  $Res call(
      {Map<String, dynamic> title,
      Map<String, dynamic> subtitle,
      Map<String, dynamic> navigationEndpoint,
      Map<String, dynamic> thumbnailRenderer});
}

/// @nodoc
class _$RendererMusicTwoRowItemCopyWithImpl<$Res>
    implements $RendererMusicTwoRowItemCopyWith<$Res> {
  _$RendererMusicTwoRowItemCopyWithImpl(this._self, this._then);

  final RendererMusicTwoRowItem _self;
  final $Res Function(RendererMusicTwoRowItem) _then;

  /// Create a copy of RendererMusicTwoRowItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? subtitle = null,
    Object? navigationEndpoint = null,
    Object? thumbnailRenderer = null,
  }) {
    return _then(_self.copyWith(
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      subtitle: null == subtitle
          ? _self.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      navigationEndpoint: null == navigationEndpoint
          ? _self.navigationEndpoint
          : navigationEndpoint // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      thumbnailRenderer: null == thumbnailRenderer
          ? _self.thumbnailRenderer
          : thumbnailRenderer // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RendererMusicTwoRowItem].
extension RendererMusicTwoRowItemPatterns on RendererMusicTwoRowItem {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RendererMusicTwoRowItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RendererMusicTwoRowItem() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RendererMusicTwoRowItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicTwoRowItem():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RendererMusicTwoRowItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicTwoRowItem() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            Map<String, dynamic> title,
            Map<String, dynamic> subtitle,
            Map<String, dynamic> navigationEndpoint,
            Map<String, dynamic> thumbnailRenderer)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RendererMusicTwoRowItem() when $default != null:
        return $default(_that.title, _that.subtitle, _that.navigationEndpoint,
            _that.thumbnailRenderer);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            Map<String, dynamic> title,
            Map<String, dynamic> subtitle,
            Map<String, dynamic> navigationEndpoint,
            Map<String, dynamic> thumbnailRenderer)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicTwoRowItem():
        return $default(_that.title, _that.subtitle, _that.navigationEndpoint,
            _that.thumbnailRenderer);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            Map<String, dynamic> title,
            Map<String, dynamic> subtitle,
            Map<String, dynamic> navigationEndpoint,
            Map<String, dynamic> thumbnailRenderer)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicTwoRowItem() when $default != null:
        return $default(_that.title, _that.subtitle, _that.navigationEndpoint,
            _that.thumbnailRenderer);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RendererMusicTwoRowItem implements RendererMusicTwoRowItem {
  const _RendererMusicTwoRowItem(
      {required final Map<String, dynamic> title,
      required final Map<String, dynamic> subtitle,
      required final Map<String, dynamic> navigationEndpoint,
      required final Map<String, dynamic> thumbnailRenderer})
      : _title = title,
        _subtitle = subtitle,
        _navigationEndpoint = navigationEndpoint,
        _thumbnailRenderer = thumbnailRenderer;

  final Map<String, dynamic> _title;
  @override
  Map<String, dynamic> get title {
    if (_title is EqualUnmodifiableMapView) return _title;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_title);
  }

  final Map<String, dynamic> _subtitle;
  @override
  Map<String, dynamic> get subtitle {
    if (_subtitle is EqualUnmodifiableMapView) return _subtitle;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_subtitle);
  }

  final Map<String, dynamic> _navigationEndpoint;
  @override
  Map<String, dynamic> get navigationEndpoint {
    if (_navigationEndpoint is EqualUnmodifiableMapView)
      return _navigationEndpoint;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_navigationEndpoint);
  }

  final Map<String, dynamic> _thumbnailRenderer;
  @override
  Map<String, dynamic> get thumbnailRenderer {
    if (_thumbnailRenderer is EqualUnmodifiableMapView)
      return _thumbnailRenderer;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_thumbnailRenderer);
  }

  /// Create a copy of RendererMusicTwoRowItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RendererMusicTwoRowItemCopyWith<_RendererMusicTwoRowItem> get copyWith =>
      __$RendererMusicTwoRowItemCopyWithImpl<_RendererMusicTwoRowItem>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RendererMusicTwoRowItem &&
            const DeepCollectionEquality().equals(other._title, _title) &&
            const DeepCollectionEquality().equals(other._subtitle, _subtitle) &&
            const DeepCollectionEquality()
                .equals(other._navigationEndpoint, _navigationEndpoint) &&
            const DeepCollectionEquality()
                .equals(other._thumbnailRenderer, _thumbnailRenderer));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_title),
      const DeepCollectionEquality().hash(_subtitle),
      const DeepCollectionEquality().hash(_navigationEndpoint),
      const DeepCollectionEquality().hash(_thumbnailRenderer));

  @override
  String toString() {
    return 'RendererMusicTwoRowItem(title: $title, subtitle: $subtitle, navigationEndpoint: $navigationEndpoint, thumbnailRenderer: $thumbnailRenderer)';
  }
}

/// @nodoc
abstract mixin class _$RendererMusicTwoRowItemCopyWith<$Res>
    implements $RendererMusicTwoRowItemCopyWith<$Res> {
  factory _$RendererMusicTwoRowItemCopyWith(_RendererMusicTwoRowItem value,
          $Res Function(_RendererMusicTwoRowItem) _then) =
      __$RendererMusicTwoRowItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {Map<String, dynamic> title,
      Map<String, dynamic> subtitle,
      Map<String, dynamic> navigationEndpoint,
      Map<String, dynamic> thumbnailRenderer});
}

/// @nodoc
class __$RendererMusicTwoRowItemCopyWithImpl<$Res>
    implements _$RendererMusicTwoRowItemCopyWith<$Res> {
  __$RendererMusicTwoRowItemCopyWithImpl(this._self, this._then);

  final _RendererMusicTwoRowItem _self;
  final $Res Function(_RendererMusicTwoRowItem) _then;

  /// Create a copy of RendererMusicTwoRowItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? title = null,
    Object? subtitle = null,
    Object? navigationEndpoint = null,
    Object? thumbnailRenderer = null,
  }) {
    return _then(_RendererMusicTwoRowItem(
      title: null == title
          ? _self._title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      subtitle: null == subtitle
          ? _self._subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      navigationEndpoint: null == navigationEndpoint
          ? _self._navigationEndpoint
          : navigationEndpoint // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      thumbnailRenderer: null == thumbnailRenderer
          ? _self._thumbnailRenderer
          : thumbnailRenderer // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
mixin _$RendererMusicCarouselShelf {
  Map<String, dynamic> get contents;
  Map<String, dynamic> get header;

  /// Create a copy of RendererMusicCarouselShelf
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RendererMusicCarouselShelfCopyWith<RendererMusicCarouselShelf>
      get copyWith =>
          _$RendererMusicCarouselShelfCopyWithImpl<RendererMusicCarouselShelf>(
              this as RendererMusicCarouselShelf, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RendererMusicCarouselShelf &&
            const DeepCollectionEquality().equals(other.contents, contents) &&
            const DeepCollectionEquality().equals(other.header, header));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(contents),
      const DeepCollectionEquality().hash(header));

  @override
  String toString() {
    return 'RendererMusicCarouselShelf(contents: $contents, header: $header)';
  }
}

/// @nodoc
abstract mixin class $RendererMusicCarouselShelfCopyWith<$Res> {
  factory $RendererMusicCarouselShelfCopyWith(RendererMusicCarouselShelf value,
          $Res Function(RendererMusicCarouselShelf) _then) =
      _$RendererMusicCarouselShelfCopyWithImpl;
  @useResult
  $Res call({Map<String, dynamic> contents, Map<String, dynamic> header});
}

/// @nodoc
class _$RendererMusicCarouselShelfCopyWithImpl<$Res>
    implements $RendererMusicCarouselShelfCopyWith<$Res> {
  _$RendererMusicCarouselShelfCopyWithImpl(this._self, this._then);

  final RendererMusicCarouselShelf _self;
  final $Res Function(RendererMusicCarouselShelf) _then;

  /// Create a copy of RendererMusicCarouselShelf
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contents = null,
    Object? header = null,
  }) {
    return _then(_self.copyWith(
      contents: null == contents
          ? _self.contents
          : contents // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      header: null == header
          ? _self.header
          : header // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RendererMusicCarouselShelf].
extension RendererMusicCarouselShelfPatterns on RendererMusicCarouselShelf {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RendererMusicCarouselShelf value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RendererMusicCarouselShelf() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RendererMusicCarouselShelf value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicCarouselShelf():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RendererMusicCarouselShelf value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicCarouselShelf() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            Map<String, dynamic> contents, Map<String, dynamic> header)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RendererMusicCarouselShelf() when $default != null:
        return $default(_that.contents, _that.header);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(Map<String, dynamic> contents, Map<String, dynamic> header)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicCarouselShelf():
        return $default(_that.contents, _that.header);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            Map<String, dynamic> contents, Map<String, dynamic> header)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicCarouselShelf() when $default != null:
        return $default(_that.contents, _that.header);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RendererMusicCarouselShelf implements RendererMusicCarouselShelf {
  const _RendererMusicCarouselShelf(
      {required final Map<String, dynamic> contents,
      required final Map<String, dynamic> header})
      : _contents = contents,
        _header = header;

  final Map<String, dynamic> _contents;
  @override
  Map<String, dynamic> get contents {
    if (_contents is EqualUnmodifiableMapView) return _contents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_contents);
  }

  final Map<String, dynamic> _header;
  @override
  Map<String, dynamic> get header {
    if (_header is EqualUnmodifiableMapView) return _header;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_header);
  }

  /// Create a copy of RendererMusicCarouselShelf
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RendererMusicCarouselShelfCopyWith<_RendererMusicCarouselShelf>
      get copyWith => __$RendererMusicCarouselShelfCopyWithImpl<
          _RendererMusicCarouselShelf>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RendererMusicCarouselShelf &&
            const DeepCollectionEquality().equals(other._contents, _contents) &&
            const DeepCollectionEquality().equals(other._header, _header));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_contents),
      const DeepCollectionEquality().hash(_header));

  @override
  String toString() {
    return 'RendererMusicCarouselShelf(contents: $contents, header: $header)';
  }
}

/// @nodoc
abstract mixin class _$RendererMusicCarouselShelfCopyWith<$Res>
    implements $RendererMusicCarouselShelfCopyWith<$Res> {
  factory _$RendererMusicCarouselShelfCopyWith(
          _RendererMusicCarouselShelf value,
          $Res Function(_RendererMusicCarouselShelf) _then) =
      __$RendererMusicCarouselShelfCopyWithImpl;
  @override
  @useResult
  $Res call({Map<String, dynamic> contents, Map<String, dynamic> header});
}

/// @nodoc
class __$RendererMusicCarouselShelfCopyWithImpl<$Res>
    implements _$RendererMusicCarouselShelfCopyWith<$Res> {
  __$RendererMusicCarouselShelfCopyWithImpl(this._self, this._then);

  final _RendererMusicCarouselShelf _self;
  final $Res Function(_RendererMusicCarouselShelf) _then;

  /// Create a copy of RendererMusicCarouselShelf
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? contents = null,
    Object? header = null,
  }) {
    return _then(_RendererMusicCarouselShelf(
      contents: null == contents
          ? _self._contents
          : contents // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      header: null == header
          ? _self._header
          : header // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
mixin _$RendererMusicShelf {
  Map<String, dynamic> get contents;
  Map<String, dynamic> get title;

  /// Create a copy of RendererMusicShelf
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RendererMusicShelfCopyWith<RendererMusicShelf> get copyWith =>
      _$RendererMusicShelfCopyWithImpl<RendererMusicShelf>(
          this as RendererMusicShelf, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RendererMusicShelf &&
            const DeepCollectionEquality().equals(other.contents, contents) &&
            const DeepCollectionEquality().equals(other.title, title));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(contents),
      const DeepCollectionEquality().hash(title));

  @override
  String toString() {
    return 'RendererMusicShelf(contents: $contents, title: $title)';
  }
}

/// @nodoc
abstract mixin class $RendererMusicShelfCopyWith<$Res> {
  factory $RendererMusicShelfCopyWith(
          RendererMusicShelf value, $Res Function(RendererMusicShelf) _then) =
      _$RendererMusicShelfCopyWithImpl;
  @useResult
  $Res call({Map<String, dynamic> contents, Map<String, dynamic> title});
}

/// @nodoc
class _$RendererMusicShelfCopyWithImpl<$Res>
    implements $RendererMusicShelfCopyWith<$Res> {
  _$RendererMusicShelfCopyWithImpl(this._self, this._then);

  final RendererMusicShelf _self;
  final $Res Function(RendererMusicShelf) _then;

  /// Create a copy of RendererMusicShelf
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? contents = null,
    Object? title = null,
  }) {
    return _then(_self.copyWith(
      contents: null == contents
          ? _self.contents
          : contents // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RendererMusicShelf].
extension RendererMusicShelfPatterns on RendererMusicShelf {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RendererMusicShelf value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RendererMusicShelf() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RendererMusicShelf value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicShelf():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RendererMusicShelf value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicShelf() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(Map<String, dynamic> contents, Map<String, dynamic> title)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RendererMusicShelf() when $default != null:
        return $default(_that.contents, _that.title);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(Map<String, dynamic> contents, Map<String, dynamic> title)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicShelf():
        return $default(_that.contents, _that.title);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            Map<String, dynamic> contents, Map<String, dynamic> title)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RendererMusicShelf() when $default != null:
        return $default(_that.contents, _that.title);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RendererMusicShelf implements RendererMusicShelf {
  const _RendererMusicShelf(
      {required final Map<String, dynamic> contents,
      required final Map<String, dynamic> title})
      : _contents = contents,
        _title = title;

  final Map<String, dynamic> _contents;
  @override
  Map<String, dynamic> get contents {
    if (_contents is EqualUnmodifiableMapView) return _contents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_contents);
  }

  final Map<String, dynamic> _title;
  @override
  Map<String, dynamic> get title {
    if (_title is EqualUnmodifiableMapView) return _title;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_title);
  }

  /// Create a copy of RendererMusicShelf
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RendererMusicShelfCopyWith<_RendererMusicShelf> get copyWith =>
      __$RendererMusicShelfCopyWithImpl<_RendererMusicShelf>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RendererMusicShelf &&
            const DeepCollectionEquality().equals(other._contents, _contents) &&
            const DeepCollectionEquality().equals(other._title, _title));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_contents),
      const DeepCollectionEquality().hash(_title));

  @override
  String toString() {
    return 'RendererMusicShelf(contents: $contents, title: $title)';
  }
}

/// @nodoc
abstract mixin class _$RendererMusicShelfCopyWith<$Res>
    implements $RendererMusicShelfCopyWith<$Res> {
  factory _$RendererMusicShelfCopyWith(
          _RendererMusicShelf value, $Res Function(_RendererMusicShelf) _then) =
      __$RendererMusicShelfCopyWithImpl;
  @override
  @useResult
  $Res call({Map<String, dynamic> contents, Map<String, dynamic> title});
}

/// @nodoc
class __$RendererMusicShelfCopyWithImpl<$Res>
    implements _$RendererMusicShelfCopyWith<$Res> {
  __$RendererMusicShelfCopyWithImpl(this._self, this._then);

  final _RendererMusicShelf _self;
  final $Res Function(_RendererMusicShelf) _then;

  /// Create a copy of RendererMusicShelf
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? contents = null,
    Object? title = null,
  }) {
    return _then(_RendererMusicShelf(
      contents: null == contents
          ? _self._contents
          : contents // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      title: null == title
          ? _self._title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

// dart format on
