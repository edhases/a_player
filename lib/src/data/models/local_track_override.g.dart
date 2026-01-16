// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_track_override.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalTrackOverrideCollection on Isar {
  IsarCollection<LocalTrackOverride> get localTrackOverrides =>
      this.collection();
}

const LocalTrackOverrideSchema = CollectionSchema(
  name: r'LocalTrackOverride',
  id: -4932042334841198877,
  properties: {
    r'correctArtist': PropertySchema(
      id: 0,
      name: r'correctArtist',
      type: IsarType.string,
    ),
    r'correctTitle': PropertySchema(
      id: 1,
      name: r'correctTitle',
      type: IsarType.string,
    ),
    r'filePath': PropertySchema(
      id: 2,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'thumbnailUrl': PropertySchema(
      id: 3,
      name: r'thumbnailUrl',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 4,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'youtubeId': PropertySchema(
      id: 5,
      name: r'youtubeId',
      type: IsarType.string,
    )
  },
  estimateSize: _localTrackOverrideEstimateSize,
  serialize: _localTrackOverrideSerialize,
  deserialize: _localTrackOverrideDeserialize,
  deserializeProp: _localTrackOverrideDeserializeProp,
  idName: r'id',
  indexes: {
    r'filePath': IndexSchema(
      id: 2918041768256347220,
      name: r'filePath',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'filePath',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localTrackOverrideGetId,
  getLinks: _localTrackOverrideGetLinks,
  attach: _localTrackOverrideAttach,
  version: '3.1.0+1',
);

int _localTrackOverrideEstimateSize(
  LocalTrackOverride object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.correctArtist;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.correctTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.filePath.length * 3;
  {
    final value = object.thumbnailUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.youtubeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _localTrackOverrideSerialize(
  LocalTrackOverride object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.correctArtist);
  writer.writeString(offsets[1], object.correctTitle);
  writer.writeString(offsets[2], object.filePath);
  writer.writeString(offsets[3], object.thumbnailUrl);
  writer.writeDateTime(offsets[4], object.updatedAt);
  writer.writeString(offsets[5], object.youtubeId);
}

LocalTrackOverride _localTrackOverrideDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalTrackOverride();
  object.correctArtist = reader.readStringOrNull(offsets[0]);
  object.correctTitle = reader.readStringOrNull(offsets[1]);
  object.filePath = reader.readString(offsets[2]);
  object.id = id;
  object.thumbnailUrl = reader.readStringOrNull(offsets[3]);
  object.updatedAt = reader.readDateTime(offsets[4]);
  object.youtubeId = reader.readStringOrNull(offsets[5]);
  return object;
}

P _localTrackOverrideDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localTrackOverrideGetId(LocalTrackOverride object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localTrackOverrideGetLinks(
    LocalTrackOverride object) {
  return [];
}

void _localTrackOverrideAttach(
    IsarCollection<dynamic> col, Id id, LocalTrackOverride object) {
  object.id = id;
}

extension LocalTrackOverrideByIndex on IsarCollection<LocalTrackOverride> {
  Future<LocalTrackOverride?> getByFilePath(String filePath) {
    return getByIndex(r'filePath', [filePath]);
  }

  LocalTrackOverride? getByFilePathSync(String filePath) {
    return getByIndexSync(r'filePath', [filePath]);
  }

  Future<bool> deleteByFilePath(String filePath) {
    return deleteByIndex(r'filePath', [filePath]);
  }

  bool deleteByFilePathSync(String filePath) {
    return deleteByIndexSync(r'filePath', [filePath]);
  }

  Future<List<LocalTrackOverride?>> getAllByFilePath(
      List<String> filePathValues) {
    final values = filePathValues.map((e) => [e]).toList();
    return getAllByIndex(r'filePath', values);
  }

  List<LocalTrackOverride?> getAllByFilePathSync(List<String> filePathValues) {
    final values = filePathValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'filePath', values);
  }

  Future<int> deleteAllByFilePath(List<String> filePathValues) {
    final values = filePathValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'filePath', values);
  }

  int deleteAllByFilePathSync(List<String> filePathValues) {
    final values = filePathValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'filePath', values);
  }

  Future<Id> putByFilePath(LocalTrackOverride object) {
    return putByIndex(r'filePath', object);
  }

  Id putByFilePathSync(LocalTrackOverride object, {bool saveLinks = true}) {
    return putByIndexSync(r'filePath', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFilePath(List<LocalTrackOverride> objects) {
    return putAllByIndex(r'filePath', objects);
  }

  List<Id> putAllByFilePathSync(List<LocalTrackOverride> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'filePath', objects, saveLinks: saveLinks);
  }
}

extension LocalTrackOverrideQueryWhereSort
    on QueryBuilder<LocalTrackOverride, LocalTrackOverride, QWhere> {
  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalTrackOverrideQueryWhere
    on QueryBuilder<LocalTrackOverride, LocalTrackOverride, QWhereClause> {
  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterWhereClause>
      filePathEqualTo(String filePath) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'filePath',
        value: [filePath],
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterWhereClause>
      filePathNotEqualTo(String filePath) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'filePath',
              lower: [],
              upper: [filePath],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'filePath',
              lower: [filePath],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'filePath',
              lower: [filePath],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'filePath',
              lower: [],
              upper: [filePath],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalTrackOverrideQueryFilter
    on QueryBuilder<LocalTrackOverride, LocalTrackOverride, QFilterCondition> {
  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'correctArtist',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'correctArtist',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correctArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'correctArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'correctArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'correctArtist',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'correctArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'correctArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'correctArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'correctArtist',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correctArtist',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctArtistIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'correctArtist',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'correctTitle',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'correctTitle',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correctTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'correctTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'correctTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'correctTitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'correctTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'correctTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'correctTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'correctTitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correctTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      correctTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'correctTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      filePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      filePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      filePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      filePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      filePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      filePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      filePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      filePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'thumbnailUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'thumbnailUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      thumbnailUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'youtubeId',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'youtubeId',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'youtubeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'youtubeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'youtubeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'youtubeId',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterFilterCondition>
      youtubeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'youtubeId',
        value: '',
      ));
    });
  }
}

extension LocalTrackOverrideQueryObject
    on QueryBuilder<LocalTrackOverride, LocalTrackOverride, QFilterCondition> {}

extension LocalTrackOverrideQueryLinks
    on QueryBuilder<LocalTrackOverride, LocalTrackOverride, QFilterCondition> {}

extension LocalTrackOverrideQuerySortBy
    on QueryBuilder<LocalTrackOverride, LocalTrackOverride, QSortBy> {
  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByCorrectArtist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctArtist', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByCorrectArtistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctArtist', Sort.desc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByCorrectTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctTitle', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByCorrectTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctTitle', Sort.desc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByYoutubeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      sortByYoutubeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.desc);
    });
  }
}

extension LocalTrackOverrideQuerySortThenBy
    on QueryBuilder<LocalTrackOverride, LocalTrackOverride, QSortThenBy> {
  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByCorrectArtist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctArtist', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByCorrectArtistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctArtist', Sort.desc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByCorrectTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctTitle', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByCorrectTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctTitle', Sort.desc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByYoutubeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.asc);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QAfterSortBy>
      thenByYoutubeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'youtubeId', Sort.desc);
    });
  }
}

extension LocalTrackOverrideQueryWhereDistinct
    on QueryBuilder<LocalTrackOverride, LocalTrackOverride, QDistinct> {
  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QDistinct>
      distinctByCorrectArtist({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'correctArtist',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QDistinct>
      distinctByCorrectTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'correctTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QDistinct>
      distinctByFilePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QDistinct>
      distinctByThumbnailUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thumbnailUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<LocalTrackOverride, LocalTrackOverride, QDistinct>
      distinctByYoutubeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'youtubeId', caseSensitive: caseSensitive);
    });
  }
}

extension LocalTrackOverrideQueryProperty
    on QueryBuilder<LocalTrackOverride, LocalTrackOverride, QQueryProperty> {
  QueryBuilder<LocalTrackOverride, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalTrackOverride, String?, QQueryOperations>
      correctArtistProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'correctArtist');
    });
  }

  QueryBuilder<LocalTrackOverride, String?, QQueryOperations>
      correctTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'correctTitle');
    });
  }

  QueryBuilder<LocalTrackOverride, String, QQueryOperations>
      filePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filePath');
    });
  }

  QueryBuilder<LocalTrackOverride, String?, QQueryOperations>
      thumbnailUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailUrl');
    });
  }

  QueryBuilder<LocalTrackOverride, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<LocalTrackOverride, String?, QQueryOperations>
      youtubeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'youtubeId');
    });
  }
}
