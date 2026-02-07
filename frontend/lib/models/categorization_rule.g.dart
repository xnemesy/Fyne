// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorization_rule.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCategorizationRuleCollection on Isar {
  IsarCollection<CategorizationRule> get categorizationRules =>
      this.collection();
}

const CategorizationRuleSchema = CollectionSchema(
  name: r'CategorizationRule',
  id: -2490749478185163550,
  properties: {
    r'categoryId': PropertySchema(
      id: 0,
      name: r'categoryId',
      type: IsarType.string,
    ),
    r'categoryName': PropertySchema(
      id: 1,
      name: r'categoryName',
      type: IsarType.string,
    ),
    r'isCustom': PropertySchema(
      id: 2,
      name: r'isCustom',
      type: IsarType.bool,
    ),
    r'pattern': PropertySchema(
      id: 3,
      name: r'pattern',
      type: IsarType.string,
    )
  },
  estimateSize: _categorizationRuleEstimateSize,
  serialize: _categorizationRuleSerialize,
  deserialize: _categorizationRuleDeserialize,
  deserializeProp: _categorizationRuleDeserializeProp,
  idName: r'id',
  indexes: {
    r'pattern': IndexSchema(
      id: 7754415363613759321,
      name: r'pattern',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'pattern',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _categorizationRuleGetId,
  getLinks: _categorizationRuleGetLinks,
  attach: _categorizationRuleAttach,
  version: '3.1.0+1',
);

int _categorizationRuleEstimateSize(
  CategorizationRule object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.categoryId.length * 3;
  bytesCount += 3 + object.categoryName.length * 3;
  bytesCount += 3 + object.pattern.length * 3;
  return bytesCount;
}

void _categorizationRuleSerialize(
  CategorizationRule object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.categoryId);
  writer.writeString(offsets[1], object.categoryName);
  writer.writeBool(offsets[2], object.isCustom);
  writer.writeString(offsets[3], object.pattern);
}

CategorizationRule _categorizationRuleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CategorizationRule(
    categoryId: reader.readString(offsets[0]),
    categoryName: reader.readString(offsets[1]),
    isCustom: reader.readBoolOrNull(offsets[2]) ?? true,
    pattern: reader.readString(offsets[3]),
  );
  object.id = id;
  return object;
}

P _categorizationRuleDeserializeProp<P>(
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
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _categorizationRuleGetId(CategorizationRule object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _categorizationRuleGetLinks(
    CategorizationRule object) {
  return [];
}

void _categorizationRuleAttach(
    IsarCollection<dynamic> col, Id id, CategorizationRule object) {
  object.id = id;
}

extension CategorizationRuleByIndex on IsarCollection<CategorizationRule> {
  Future<CategorizationRule?> getByPattern(String pattern) {
    return getByIndex(r'pattern', [pattern]);
  }

  CategorizationRule? getByPatternSync(String pattern) {
    return getByIndexSync(r'pattern', [pattern]);
  }

  Future<bool> deleteByPattern(String pattern) {
    return deleteByIndex(r'pattern', [pattern]);
  }

  bool deleteByPatternSync(String pattern) {
    return deleteByIndexSync(r'pattern', [pattern]);
  }

  Future<List<CategorizationRule?>> getAllByPattern(
      List<String> patternValues) {
    final values = patternValues.map((e) => [e]).toList();
    return getAllByIndex(r'pattern', values);
  }

  List<CategorizationRule?> getAllByPatternSync(List<String> patternValues) {
    final values = patternValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'pattern', values);
  }

  Future<int> deleteAllByPattern(List<String> patternValues) {
    final values = patternValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'pattern', values);
  }

  int deleteAllByPatternSync(List<String> patternValues) {
    final values = patternValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'pattern', values);
  }

  Future<Id> putByPattern(CategorizationRule object) {
    return putByIndex(r'pattern', object);
  }

  Id putByPatternSync(CategorizationRule object, {bool saveLinks = true}) {
    return putByIndexSync(r'pattern', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPattern(List<CategorizationRule> objects) {
    return putAllByIndex(r'pattern', objects);
  }

  List<Id> putAllByPatternSync(List<CategorizationRule> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'pattern', objects, saveLinks: saveLinks);
  }
}

extension CategorizationRuleQueryWhereSort
    on QueryBuilder<CategorizationRule, CategorizationRule, QWhere> {
  QueryBuilder<CategorizationRule, CategorizationRule, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CategorizationRuleQueryWhere
    on QueryBuilder<CategorizationRule, CategorizationRule, QWhereClause> {
  QueryBuilder<CategorizationRule, CategorizationRule, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterWhereClause>
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

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterWhereClause>
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

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterWhereClause>
      patternEqualTo(String pattern) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'pattern',
        value: [pattern],
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterWhereClause>
      patternNotEqualTo(String pattern) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pattern',
              lower: [],
              upper: [pattern],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pattern',
              lower: [pattern],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pattern',
              lower: [pattern],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pattern',
              lower: [],
              upper: [pattern],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CategorizationRuleQueryFilter
    on QueryBuilder<CategorizationRule, CategorizationRule, QFilterCondition> {
  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      categoryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
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

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
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

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
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

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      isCustomEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCustom',
        value: value,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      patternEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      patternGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      patternLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      patternBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pattern',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      patternStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      patternEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      patternContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pattern',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      patternMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pattern',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      patternIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pattern',
        value: '',
      ));
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterFilterCondition>
      patternIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pattern',
        value: '',
      ));
    });
  }
}

extension CategorizationRuleQueryObject
    on QueryBuilder<CategorizationRule, CategorizationRule, QFilterCondition> {}

extension CategorizationRuleQueryLinks
    on QueryBuilder<CategorizationRule, CategorizationRule, QFilterCondition> {}

extension CategorizationRuleQuerySortBy
    on QueryBuilder<CategorizationRule, CategorizationRule, QSortBy> {
  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      sortByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      sortByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      sortByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      sortByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      sortByIsCustom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.asc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      sortByIsCustomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.desc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      sortByPattern() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.asc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      sortByPatternDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.desc);
    });
  }
}

extension CategorizationRuleQuerySortThenBy
    on QueryBuilder<CategorizationRule, CategorizationRule, QSortThenBy> {
  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      thenByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      thenByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      thenByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      thenByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      thenByIsCustom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.asc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      thenByIsCustomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.desc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      thenByPattern() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.asc);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QAfterSortBy>
      thenByPatternDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pattern', Sort.desc);
    });
  }
}

extension CategorizationRuleQueryWhereDistinct
    on QueryBuilder<CategorizationRule, CategorizationRule, QDistinct> {
  QueryBuilder<CategorizationRule, CategorizationRule, QDistinct>
      distinctByCategoryId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QDistinct>
      distinctByCategoryName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QDistinct>
      distinctByIsCustom() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCustom');
    });
  }

  QueryBuilder<CategorizationRule, CategorizationRule, QDistinct>
      distinctByPattern({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pattern', caseSensitive: caseSensitive);
    });
  }
}

extension CategorizationRuleQueryProperty
    on QueryBuilder<CategorizationRule, CategorizationRule, QQueryProperty> {
  QueryBuilder<CategorizationRule, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CategorizationRule, String, QQueryOperations>
      categoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryId');
    });
  }

  QueryBuilder<CategorizationRule, String, QQueryOperations>
      categoryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryName');
    });
  }

  QueryBuilder<CategorizationRule, bool, QQueryOperations> isCustomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCustom');
    });
  }

  QueryBuilder<CategorizationRule, String, QQueryOperations> patternProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pattern');
    });
  }
}
