import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_renderer.freezed.dart';

@freezed
abstract class Renderer with _$Renderer {
  const factory Renderer.musicResponsiveListItem(RendererMusicResponsiveListItem data) = _MusicResponsiveListItem;
  const factory Renderer.musicTwoRowItem(RendererMusicTwoRowItem data) = _MusicTwoRowItem;
  const factory Renderer.musicCarouselShelf(RendererMusicCarouselShelf data) = _MusicCarouselShelf;
  const factory Renderer.musicShelf(RendererMusicShelf data) = _MusicShelf;

  // Private constructor required by freezed for mixins
  const Renderer._();
}

@freezed
abstract class RendererMusicResponsiveListItem with _$RendererMusicResponsiveListItem {
  const factory RendererMusicResponsiveListItem({
    required Map<String, dynamic> flexColumns,
    required Map<String, dynamic> thumbnail,
    required Map<String, dynamic> overlay,
    required Map<String, dynamic> navigationEndpoint,
  }) = _RendererMusicResponsiveListItem;
}

@freezed
abstract class RendererMusicTwoRowItem with _$RendererMusicTwoRowItem {
  const factory RendererMusicTwoRowItem({
    required Map<String, dynamic> title,
    required Map<String, dynamic> subtitle,
    required Map<String, dynamic> navigationEndpoint,
    required Map<String, dynamic> thumbnailRenderer,
  }) = _RendererMusicTwoRowItem;
}

@freezed
abstract class RendererMusicCarouselShelf with _$RendererMusicCarouselShelf {
  const factory RendererMusicCarouselShelf({
    required Map<String, dynamic> contents,
    required Map<String, dynamic> header,
  }) = _RendererMusicCarouselShelf;
}

@freezed
abstract class RendererMusicShelf with _$RendererMusicShelf {
  const factory RendererMusicShelf({
    required Map<String, dynamic> contents,
    required Map<String, dynamic> title,
  }) = _RendererMusicShelf;
}
