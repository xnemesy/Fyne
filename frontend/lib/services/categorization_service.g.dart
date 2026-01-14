// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorization_service.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCategoryOverrideCollection on Isar {
  IsarCollection<CategoryOverride> get categoryOverrides => this.collection();
}

const CategoryOverrideSchema = CollectionSchema(
  name: r'CategoryOverride',
  id: -1442284902461188789,
  properties: {
    r'categoryUuid': PropertySchema(
      id: 0,
      name: r'categoryUuid',
      type: IsarType.string,
    ),
    r'decryptedCategoryName': PropertySchema(
      id: 1,
      name: r'decryptedCategoryName',
      type: IsarType.string,
    ),
    r'keyword': PropertySchema(
      id: 2,
      name: r'keyword',
      type: IsarType.string,
    )
  },
  estimateSize: _categoryOverrideEstimateSize,
  serialize: _categoryOverrideSerialize,
  deserialize: _categoryOverrideDeserialize,
  deserializeProp: _categoryOverrideDeserializeProp,
  idName: r'id',
  indexes: {
    r'keyword': IndexSchema(
      id: 5840366397742622134,
      name: r'keyword',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'keyword',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _categoryOverrideGetId,
  getLinks: _categoryOverrideGetLinks,
  attach: _categoryOverrideAttach,
  version: '3.1.0+1',
);

int _categoryOverrideEstimateSize(
  CategoryOverride object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.categoryUuid.length * 3;
  bytesCount += 3 + object.decryptedCategoryName.length * 3;
  bytesCount += 3 + object.keyword.length * 3;
  return bytesCount;
}

void _categoryOverrideSerialize(
  CategoryOverride object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.categoryUuid);
  writer.writeString(offsets[1], object.decryptedCategoryName);
  writer.writeString(offsets[2], object.keyword);
}

CategoryOverride _categoryOverrideDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CategoryOverride();
  object.categoryUuid = reader.readString(offsets[0]);
  object.decryptedCategoryName = reader.readString(offsets[1]);
  object.id = id;
  object.keyword = reader.readString(offsets[2]);
  return object;
}

P _categoryOverrideDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _categoryOverrideGetId(CategoryOverride object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _categoryOverrideGetLinks(CategoryOverride object) {
  return [];
}

void _categoryOverrideAttach(
    IsarCollection<dynamic> col, Id id, CategoryOverride object) {
  object.id = id;
}

extension CategoryOverrideByIndex on IsarCollection<CategoryOverride> {
  Future<CategoryOverride?> getByKeyword(String keyword) {
    return getByIndex(r'keyword', [keyword]);
  }

  CategoryOverride? getByKeywordSync(String keyword) {
    return getByIndexSync(r'keyword', [keyword]);
  }

  Future<bool> deleteByKeyword(String keyword) {
    return deleteByIndex(r'keyword', [keyword]);
  }

  bool deleteByKeywordSync(String keyword) {
    return deleteByIndexSync(r'keyword', [keyword]);
  }

  Future<List<CategoryOverride?>> getAllByKeyword(List<String> keywordValues) {
    final values = keywordValues.map((e) => [e]).toList();
    return getAllByIndex(r'keyword', values);
  }

  List<CategoryOverride?> getAllByKeywordSync(List<String> keywordValues) {
    final values = keywordValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'keyword', values);
  }

  Future<int> deleteAllByKeyword(List<String> keywordValues) {
    final values = keywordValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'keyword', values);
  }

  int deleteAllByKeywordSync(List<String> keywordValues) {
    final values = keywordValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'keyword', values);
  }

  Future<Id> putByKeyword(CategoryOverride object) {
    return putByIndex(r'keyword', object);
  }

  Id putByKeywordSync(CategoryOverride object, {bool saveLinks = true}) {
    return putByIndexSync(r'keyword', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKeyword(List<CategoryOverride> objects) {
    return putAllByIndex(r'keyword', objects);
  }

  List<Id> putAllByKeywordSync(List<CategoryOverride> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'keyword', objects, saveLinks: saveLinks);
  }
}

extension CategoryOverrideQueryWhereSort
    on QueryBuilder<CategoryOverride, CategoryOverride, QWhere> {
  QueryBuilder<CategoryOverride, CategoryOverride, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CategoryOverrideQueryWhere
    on QueryBuilder<CategoryOverride, CategoryOverride, QWhereClause> {
  QueryBuilder<CategoryOverride, CategoryOverride, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterWhereClause>
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

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterWhereClause> idBetween(
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

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterWhereClause>
      keywordEqualTo(String keyword) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'keyword',
        value: [keyword],
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterWhereClause>
      keywordNotEqualTo(String keyword) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyword',
              lower: [],
              upper: [keyword],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyword',
              lower: [keyword],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyword',
              lower: [keyword],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyword',
              lower: [],
              upper: [keyword],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CategoryOverrideQueryFilter
    on QueryBuilder<CategoryOverride, CategoryOverride, QFilterCondition> {
  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      categoryUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      categoryUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      categoryUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      categoryUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      categoryUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      categoryUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      categoryUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      categoryUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      categoryUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      categoryUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      decryptedCategoryNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      decryptedCategoryNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'decryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      decryptedCategoryNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'decryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      decryptedCategoryNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'decryptedCategoryName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      decryptedCategoryNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'decryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      decryptedCategoryNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'decryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      decryptedCategoryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'decryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      decryptedCategoryNameMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'decryptedCategoryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      decryptedCategoryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'decryptedCategoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      decryptedCategoryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'decryptedCategoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
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

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
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

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
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

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      keywordEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      keywordGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      keywordLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      keywordBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'keyword',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      keywordStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      keywordEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      keywordContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'keyword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      keywordMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'keyword',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      keywordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keyword',
        value: '',
      ));
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterFilterCondition>
      keywordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'keyword',
        value: '',
      ));
    });
  }
}

extension CategoryOverrideQueryObject
    on QueryBuilder<CategoryOverride, CategoryOverride, QFilterCondition> {}

extension CategoryOverrideQueryLinks
    on QueryBuilder<CategoryOverride, CategoryOverride, QFilterCondition> {}

extension CategoryOverrideQuerySortBy
    on QueryBuilder<CategoryOverride, CategoryOverride, QSortBy> {
  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      sortByCategoryUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.asc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      sortByCategoryUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.desc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      sortByDecryptedCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decryptedCategoryName', Sort.asc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      sortByDecryptedCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decryptedCategoryName', Sort.desc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      sortByKeyword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.asc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      sortByKeywordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.desc);
    });
  }
}

extension CategoryOverrideQuerySortThenBy
    on QueryBuilder<CategoryOverride, CategoryOverride, QSortThenBy> {
  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      thenByCategoryUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.asc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      thenByCategoryUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.desc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      thenByDecryptedCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decryptedCategoryName', Sort.asc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      thenByDecryptedCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'decryptedCategoryName', Sort.desc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      thenByKeyword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.asc);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QAfterSortBy>
      thenByKeywordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyword', Sort.desc);
    });
  }
}

extension CategoryOverrideQueryWhereDistinct
    on QueryBuilder<CategoryOverride, CategoryOverride, QDistinct> {
  QueryBuilder<CategoryOverride, CategoryOverride, QDistinct>
      distinctByCategoryUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QDistinct>
      distinctByDecryptedCategoryName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'decryptedCategoryName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CategoryOverride, CategoryOverride, QDistinct> distinctByKeyword(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keyword', caseSensitive: caseSensitive);
    });
  }
}

extension CategoryOverrideQueryProperty
    on QueryBuilder<CategoryOverride, CategoryOverride, QQueryProperty> {
  QueryBuilder<CategoryOverride, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CategoryOverride, String, QQueryOperations>
      categoryUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryUuid');
    });
  }

  QueryBuilder<CategoryOverride, String, QQueryOperations>
      decryptedCategoryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'decryptedCategoryName');
    });
  }

  QueryBuilder<CategoryOverride, String, QQueryOperations> keywordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keyword');
    });
  }
}
