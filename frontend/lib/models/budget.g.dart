// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBudgetCollection on Isar {
  IsarCollection<Budget> get budgets => this.collection();
}

const BudgetSchema = CollectionSchema(
  name: r'Budget',
  id: -3383598594604670326,
  properties: {
    r'categoryUuid': PropertySchema(
      id: 0,
      name: r'categoryUuid',
      type: IsarType.string,
    ),
    r'currentSpent': PropertySchema(
      id: 1,
      name: r'currentSpent',
      type: IsarType.double,
    ),
    r'encryptedCategoryName': PropertySchema(
      id: 2,
      name: r'encryptedCategoryName',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'isOverBudget': PropertySchema(
      id: 4,
      name: r'isOverBudget',
      type: IsarType.bool,
    ),
    r'limitAmount': PropertySchema(
      id: 5,
      name: r'limitAmount',
      type: IsarType.double,
    ),
    r'progress': PropertySchema(
      id: 6,
      name: r'progress',
      type: IsarType.double,
    ),
    r'remaining': PropertySchema(
      id: 7,
      name: r'remaining',
      type: IsarType.double,
    )
  },
  estimateSize: _budgetEstimateSize,
  serialize: _budgetSerialize,
  deserialize: _budgetDeserialize,
  deserializeProp: _budgetDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _budgetGetId,
  getLinks: _budgetGetLinks,
  attach: _budgetAttach,
  version: '3.1.0+1',
);

int _budgetEstimateSize(
  Budget object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.categoryUuid.length * 3;
  bytesCount += 3 + object.encryptedCategoryName.length * 3;
  bytesCount += 3 + object.id.length * 3;
  return bytesCount;
}

void _budgetSerialize(
  Budget object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.categoryUuid);
  writer.writeDouble(offsets[1], object.currentSpent);
  writer.writeString(offsets[2], object.encryptedCategoryName);
  writer.writeString(offsets[3], object.id);
  writer.writeBool(offsets[4], object.isOverBudget);
  writer.writeDouble(offsets[5], object.limitAmount);
  writer.writeDouble(offsets[6], object.progress);
  writer.writeDouble(offsets[7], object.remaining);
}

Budget _budgetDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Budget(
    categoryUuid: reader.readString(offsets[0]),
    currentSpent: reader.readDouble(offsets[1]),
    encryptedCategoryName: reader.readString(offsets[2]),
    id: reader.readString(offsets[3]),
    limitAmount: reader.readDouble(offsets[5]),
  );
  object.isarId = id;
  return object;
}

P _budgetDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _budgetGetId(Budget object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _budgetGetLinks(Budget object) {
  return [];
}

void _budgetAttach(IsarCollection<dynamic> col, Id id, Budget object) {
  object.isarId = id;
}

extension BudgetByIndex on IsarCollection<Budget> {
  Future<Budget?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  Budget? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<Budget?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<Budget?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(Budget object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(Budget object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<Budget> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<Budget> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension BudgetQueryWhereSort on QueryBuilder<Budget, Budget, QWhere> {
  QueryBuilder<Budget, Budget, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BudgetQueryWhere on QueryBuilder<Budget, Budget, QWhereClause> {
  QueryBuilder<Budget, Budget, QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Budget, Budget, QAfterWhereClause> isarIdGreaterThan(Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<Budget, Budget, QAfterWhereClause> isarIdLessThan(Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<Budget, Budget, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterWhereClause> idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterWhereClause> idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension BudgetQueryFilter on QueryBuilder<Budget, Budget, QFilterCondition> {
  QueryBuilder<Budget, Budget, QAfterFilterCondition> categoryUuidEqualTo(
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

  QueryBuilder<Budget, Budget, QAfterFilterCondition> categoryUuidGreaterThan(
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

  QueryBuilder<Budget, Budget, QAfterFilterCondition> categoryUuidLessThan(
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

  QueryBuilder<Budget, Budget, QAfterFilterCondition> categoryUuidBetween(
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

  QueryBuilder<Budget, Budget, QAfterFilterCondition> categoryUuidStartsWith(
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

  QueryBuilder<Budget, Budget, QAfterFilterCondition> categoryUuidEndsWith(
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

  QueryBuilder<Budget, Budget, QAfterFilterCondition> categoryUuidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> categoryUuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> categoryUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> categoryUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> currentSpentEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentSpent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> currentSpentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentSpent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> currentSpentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentSpent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> currentSpentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentSpent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition>
      encryptedCategoryNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'encryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition>
      encryptedCategoryNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'encryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition>
      encryptedCategoryNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'encryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition>
      encryptedCategoryNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'encryptedCategoryName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition>
      encryptedCategoryNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'encryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition>
      encryptedCategoryNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'encryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition>
      encryptedCategoryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'encryptedCategoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition>
      encryptedCategoryNameMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'encryptedCategoryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition>
      encryptedCategoryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'encryptedCategoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition>
      encryptedCategoryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'encryptedCategoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> idContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> idMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> isOverBudgetEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isOverBudget',
        value: value,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> limitAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'limitAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> limitAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'limitAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> limitAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'limitAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> limitAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'limitAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> progressEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> progressGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> progressLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> progressBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'progress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> remainingEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remaining',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> remainingGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remaining',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> remainingLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remaining',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Budget, Budget, QAfterFilterCondition> remainingBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remaining',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension BudgetQueryObject on QueryBuilder<Budget, Budget, QFilterCondition> {}

extension BudgetQueryLinks on QueryBuilder<Budget, Budget, QFilterCondition> {}

extension BudgetQuerySortBy on QueryBuilder<Budget, Budget, QSortBy> {
  QueryBuilder<Budget, Budget, QAfterSortBy> sortByCategoryUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByCategoryUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByCurrentSpent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentSpent', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByCurrentSpentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentSpent', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByEncryptedCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedCategoryName', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByEncryptedCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedCategoryName', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByIsOverBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverBudget', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByIsOverBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverBudget', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByLimitAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limitAmount', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByLimitAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limitAmount', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remaining', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> sortByRemainingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remaining', Sort.desc);
    });
  }
}

extension BudgetQuerySortThenBy on QueryBuilder<Budget, Budget, QSortThenBy> {
  QueryBuilder<Budget, Budget, QAfterSortBy> thenByCategoryUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByCategoryUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByCurrentSpent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentSpent', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByCurrentSpentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentSpent', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByEncryptedCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedCategoryName', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByEncryptedCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedCategoryName', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByIsOverBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverBudget', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByIsOverBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOverBudget', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByLimitAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limitAmount', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByLimitAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limitAmount', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remaining', Sort.asc);
    });
  }

  QueryBuilder<Budget, Budget, QAfterSortBy> thenByRemainingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remaining', Sort.desc);
    });
  }
}

extension BudgetQueryWhereDistinct on QueryBuilder<Budget, Budget, QDistinct> {
  QueryBuilder<Budget, Budget, QDistinct> distinctByCategoryUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Budget, Budget, QDistinct> distinctByCurrentSpent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentSpent');
    });
  }

  QueryBuilder<Budget, Budget, QDistinct> distinctByEncryptedCategoryName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'encryptedCategoryName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Budget, Budget, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Budget, Budget, QDistinct> distinctByIsOverBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOverBudget');
    });
  }

  QueryBuilder<Budget, Budget, QDistinct> distinctByLimitAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'limitAmount');
    });
  }

  QueryBuilder<Budget, Budget, QDistinct> distinctByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progress');
    });
  }

  QueryBuilder<Budget, Budget, QDistinct> distinctByRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remaining');
    });
  }
}

extension BudgetQueryProperty on QueryBuilder<Budget, Budget, QQueryProperty> {
  QueryBuilder<Budget, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<Budget, String, QQueryOperations> categoryUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryUuid');
    });
  }

  QueryBuilder<Budget, double, QQueryOperations> currentSpentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentSpent');
    });
  }

  QueryBuilder<Budget, String, QQueryOperations>
      encryptedCategoryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'encryptedCategoryName');
    });
  }

  QueryBuilder<Budget, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Budget, bool, QQueryOperations> isOverBudgetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOverBudget');
    });
  }

  QueryBuilder<Budget, double, QQueryOperations> limitAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'limitAmount');
    });
  }

  QueryBuilder<Budget, double, QQueryOperations> progressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progress');
    });
  }

  QueryBuilder<Budget, double, QQueryOperations> remainingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remaining');
    });
  }
}
