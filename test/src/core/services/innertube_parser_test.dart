import 'package:flutter_test/flutter_test.dart';
import 'package:oxide_player/src/core/services/innertube/innertube_parser.dart';

void main() {
  late InnerTubeParser parser;

  setUp(() {
    parser = InnerTubeParser();
  });

  group('InnerTubeParser - parseDuration', () {
    test('parses MM:SS format correctly', () {
      expect(parser.parseDuration('3:45'), equals(225));
      expect(parser.parseDuration('0:30'), equals(30));
      expect(parser.parseDuration('10:00'), equals(600));
    });

    test('parses HH:MM:SS format correctly', () {
      expect(parser.parseDuration('1:00:00'), equals(3600));
      expect(parser.parseDuration('2:30:45'), equals(9045));
      expect(parser.parseDuration('0:05:30'), equals(330));
    });

    test('returns 0 for invalid formats', () {
      expect(parser.parseDuration('invalid'), equals(0));
      expect(parser.parseDuration(''), equals(0));
      expect(parser.parseDuration('abc:def'), equals(0));
    });
  });

  group('InnerTubeParser - parseSingleSong with artist parsing', () {
    test('parses song with category prefix (Song • Artist format)', () {
      // This simulates the YouTube Music format where "Song" comes before artist
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Сьогодні'},
                ],
              },
            },
          },
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Song'},
                  {'text': ' • '},
                  {
                    'text': 'Цвях',
                    'navigationEndpoint': {
                      'browseEndpoint': {
                        'browseId': 'UCexample123',
                      },
                    },
                  },
                ],
              },
            },
          },
        ],
        'playlistItemData': {'videoId': 'testVideoId123'},
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.title, equals('Сьогодні'));
      expect(result.artist, equals('Цвях'));
      expect(result.artistId, equals('UCexample123'));
      expect(result.videoId, equals('testVideoId123'));
    });

    test('parses song with Ukrainian category prefix (Пісня • Artist)', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Тест пісня'},
                ],
              },
            },
          },
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Пісня'},
                  {'text': ' • '},
                  {'text': 'Український Виконавець'},
                ],
              },
            },
          },
        ],
        'playlistItemData': {'videoId': 'video123'},
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.artist, equals('Український Виконавець'));
      expect(result.category, equals('Пісня'));
    });

    test('parses song with Video category prefix', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Music Video Title'},
                ],
              },
            },
          },
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Video'},
                  {'text': ' • '},
                  {'text': 'Artist Name'},
                  {'text': ' • '},
                  {'text': '1.5M views'},
                ],
              },
            },
          },
        ],
        'navigationEndpoint': {'watchEndpoint': {'videoId': 'vid456'}},
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.artist, equals('Artist Name'));
      expect(result.category, equals('Video'));
    });

    test('parses song without category prefix (Artist directly)', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Direct Song'},
                ],
              },
            },
          },
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {
                    'text': 'Direct Artist',
                    'navigationEndpoint': {
                      'browseEndpoint': {
                        'browseId': 'UCdirect',
                      },
                    },
                  },
                ],
              },
            },
          },
        ],
        'playlistItemData': {'videoId': 'direct123'},
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.artist, equals('Direct Artist'));
      expect(result.artistId, equals('UCdirect'));
    });

    test('stops parsing artist at separator after artist name', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Test Song'},
                ],
              },
            },
          },
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Song'},
                  {'text': ' • '},
                  {'text': 'Real Artist'},
                  {'text': ' • '},
                  {'text': 'Album Name'},
                  {'text': ' • '},
                  {'text': '3:45'},
                ],
              },
            },
          },
        ],
        'playlistItemData': {'videoId': 'test123'},
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.artist, equals('Real Artist'));
      // Should NOT include "Album Name" or duration
      expect(result.artist, isNot(contains('Album')));
      expect(result.artist, isNot(contains(':')));
    });

    test('returns null for empty title', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': ''},
                ],
              },
            },
          },
        ],
      };

      final result = parser.parseSingleSong(mrlir);
      expect(result, isNull);
    });

    test('returns null when no videoId found', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Title Without Video'},
                ],
              },
            },
          },
        ],
        // No playlistItemData, navigationEndpoint, overlay, etc.
      };

      final result = parser.parseSingleSong(mrlir);
      expect(result, isNull);
    });

    test('extracts videoId from overlay play button', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Overlay Test'},
                ],
              },
            },
          },
        ],
        'overlay': {
          'musicItemThumbnailOverlayRenderer': {
            'content': {
              'musicPlayButtonRenderer': {
                'playNavigationEndpoint': {
                  'watchEndpoint': {
                    'videoId': 'overlayVideoId',
                    'playlistId': 'RDAMVM_overlay',
                  },
                },
              },
            },
          },
        },
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.videoId, equals('overlayVideoId'));
      expect(result.playlistId, equals('RDAMVM_overlay'));
    });

    test('extracts videoId from menu items queue endpoint', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Menu Test'},
                ],
              },
            },
          },
        ],
        'menu': {
          'menuRenderer': {
            'items': [
              {
                'menuServiceItemRenderer': {
                  'serviceEndpoint': {
                    'queueAddEndpoint': {
                      'queueTarget': {
                        'videoId': 'menuVideoId',
                      },
                    },
                  },
                },
              },
            ],
          },
        },
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.videoId, equals('menuVideoId'));
    });

    test('extracts thumbnail URL correctly', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Thumbnail Test'},
                ],
              },
            },
          },
        ],
        'playlistItemData': {'videoId': 'thumb123'},
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': '//i.ytimg.com/small.jpg'},
                {'url': '//i.ytimg.com/large.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      // Should use last (largest) thumbnail and prepend https:
      expect(result!.thumbnailUrl, equals('https://i.ytimg.com/large.jpg'));
    });

    test('extracts duration from fixedColumns', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Duration Test'},
                ],
              },
            },
          },
        ],
        'playlistItemData': {'videoId': 'dur123'},
        'fixedColumns': [
          {
            'musicResponsiveListItemFixedColumnRenderer': {
              'text': {
                'runs': [
                  {'text': '4:20'},
                ],
              },
            },
          },
        ],
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.duration, equals(260)); // 4*60 + 20 = 260 seconds
    });
  });

  group('InnerTubeParser - parsePlaylistPanelItem', () {
    test('parses playlist panel item correctly', () {
      final renderer = {
        'videoId': 'playlistVideo1',
        'title': {
          'runs': [
            {'text': 'Playlist Song'},
          ],
        },
        'shortBylineText': {
          'runs': [
            {
              'text': 'Playlist Artist',
              'navigationEndpoint': {
                'browseEndpoint': {
                  'browseId': 'UCplaylistArtist',
                },
              },
            },
          ],
        },
        'thumbnail': {
          'thumbnails': [
            {'url': 'https://example.com/playlist_thumb.jpg'},
          ],
        },
        'lengthText': {
          'runs': [
            {'text': '2:30'},
          ],
        },
      };

      final result = parser.parsePlaylistPanelItem(renderer);

      expect(result, isNotNull);
      expect(result!.videoId, equals('playlistVideo1'));
      expect(result.title, equals('Playlist Song'));
      expect(result.artist, equals('Playlist Artist'));
      expect(result.artistId, equals('UCplaylistArtist'));
      expect(result.duration, equals(150)); // 2*60 + 30
    });

    test('uses longBylineText as fallback', () {
      final renderer = {
        'videoId': 'fallbackVideo',
        'title': {
          'runs': [
            {'text': 'Fallback Song'},
          ],
        },
        'longBylineText': {
          'runs': [
            {'text': 'Long Byline Artist'},
          ],
        },
        'thumbnail': {
          'thumbnails': [
            {'url': 'https://example.com/thumb.jpg'},
          ],
        },
      };

      final result = parser.parsePlaylistPanelItem(renderer);

      expect(result, isNotNull);
      expect(result!.artist, equals('Long Byline Artist'));
    });

    test('returns null for missing videoId', () {
      final renderer = {
        'title': {
          'runs': [
            {'text': 'No Video ID'},
          ],
        },
      };

      final result = parser.parsePlaylistPanelItem(renderer);
      expect(result, isNull);
    });

    test('returns null for empty title', () {
      final renderer = {
        'videoId': 'hasVideo',
        'title': {
          'runs': [
            {'text': ''},
          ],
        },
      };

      final result = parser.parsePlaylistPanelItem(renderer);
      expect(result, isNull);
    });
  });

  group('InnerTubeParser - findArtistBrowseIdRecursive', () {
    test('finds UC prefixed browseId in nested structure', () {
      final data = {
        'level1': {
          'level2': {
            'browseId': 'UCtest123',
          },
        },
      };

      final result = parser.findArtistBrowseIdRecursive(data);
      expect(result, equals('UCtest123'));
    });

    test('finds UA prefixed browseId', () {
      final data = {
        'some': {
          'nested': {
            'data': [
              {'browseId': 'UAtest456'},
            ],
          },
        },
      };

      final result = parser.findArtistBrowseIdRecursive(data);
      expect(result, equals('UAtest456'));
    });

    test('ignores non-artist browseIds', () {
      final data = {
        'browseId': 'VLPLA123', // Playlist ID
        'nested': {
          'browseId': 'MPREb_test', // Album ID
        },
      };

      final result = parser.findArtistBrowseIdRecursive(data);
      expect(result, isNull);
    });

    test('returns first artist browseId found', () {
      final data = {
        'first': {
          'browseId': 'UCfirst',
        },
        'second': {
          'browseId': 'UCsecond',
        },
      };

      final result = parser.findArtistBrowseIdRecursive(data);
      expect(result, equals('UCfirst'));
    });
  });

  group('InnerTubeParser - findContinuationToken', () {
    test('finds token in continuations array', () {
      final data = {
        'continuations': [
          {
            'nextContinuationData': {
              'continuation': 'token123',
            },
          },
        ],
      };

      final result = parser.findContinuationToken(data);
      expect(result, equals('token123'));
    });

    test('finds token in nextRadioContinuationData', () {
      final data = {
        'continuations': [
          {
            'nextRadioContinuationData': {
              'continuation': 'radioToken',
            },
          },
        ],
      };

      final result = parser.findContinuationToken(data);
      expect(result, equals('radioToken'));
    });

    test('finds token in continuationEndpoint', () {
      final data = {
        'nested': {
          'continuationEndpoint': {
            'continuationCommand': {
              'token': 'endpointToken',
            },
          },
        },
      };

      final result = parser.findContinuationToken(data);
      expect(result, equals('endpointToken'));
    });

    test('returns null when no continuation found', () {
      final data = {
        'some': 'data',
        'without': 'continuation',
      };

      final result = parser.findContinuationToken(data);
      expect(result, isNull);
    });
  });

  group('InnerTubeParser - recursiveFindItems', () {
    test('finds all items with specified renderer key', () {
      final data = {
        'content': {
          'musicResponsiveListItemRenderer': {
            'title': 'Item 1',
          },
          'nested': {
            'musicResponsiveListItemRenderer': {
              'title': 'Item 2',
            },
          },
        },
        'list': [
          {
            'musicResponsiveListItemRenderer': {
              'title': 'Item 3',
            },
          },
        ],
      };

      final results = parser.recursiveFindItems(data, 'musicResponsiveListItemRenderer');

      expect(results.length, equals(3));
      expect(results[0]['title'], equals('Item 1'));
      expect(results[1]['title'], equals('Item 2'));
      expect(results[2]['title'], equals('Item 3'));
    });

    test('returns empty list when key not found', () {
      final data = {
        'some': 'data',
      };

      final results = parser.recursiveFindItems(data, 'nonExistentRenderer');
      expect(results, isEmpty);
    });
  });

  group('InnerTubeParser - Artist Parsing Edge Cases', () {
    test('handles Cyrillic artist names correctly', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Пісня Тест'},
                ],
              },
            },
          },
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Song'},
                  {'text': ' • '},
                  {'text': 'Океан Ельзи'},
                ],
              },
            },
          },
        ],
        'playlistItemData': {'videoId': 'cyrillic123'},
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.artist, equals('Океан Ельзи'));
    });

    test('handles Japanese artist names correctly', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Japanese Song'},
                ],
              },
            },
          },
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Song'},
                  {'text': ' • '},
                  {'text': '米津玄師'},
                ],
              },
            },
          },
        ],
        'playlistItemData': {'videoId': 'japan123'},
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.artist, equals('米津玄師'));
    });

    test('handles artist with views count (should stop before views)', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Popular Song'},
                ],
              },
            },
          },
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Famous Artist'},
                  {'text': ' • '},
                  {'text': '10M views'},
                ],
              },
            },
          },
        ],
        'playlistItemData': {'videoId': 'views123'},
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.artist, equals('Famous Artist'));
      expect(result.artist, isNot(contains('views')));
    });

    test('handles Ukrainian views count (переглядів)', () {
      final mrlir = {
        'flexColumns': [
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Українська Пісня'},
                ],
              },
            },
          },
          {
            'musicResponsiveListItemFlexColumnRenderer': {
              'text': {
                'runs': [
                  {'text': 'Кліпс'},
                  {'text': ' • '},
                  {'text': '500 тис. переглядів'},
                ],
              },
            },
          },
        ],
        'playlistItemData': {'videoId': 'ukr123'},
        'thumbnail': {
          'musicThumbnailRenderer': {
            'thumbnail': {
              'thumbnails': [
                {'url': 'https://example.com/thumb.jpg'},
              ],
            },
          },
        },
      };

      final result = parser.parseSingleSong(mrlir);

      expect(result, isNotNull);
      expect(result!.artist, equals('Кліпс'));
      expect(result.artist, isNot(contains('переглядів')));
    });
  });
}
