// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduler_service.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPlannedTransactionCollection on Isar {
  IsarCollection<PlannedTransaction> get plannedTransactions =>
      this.collection();
}

const PlannedTransactionSchema = CollectionSchema(
  name: r'PlannedTransaction',
  id: -2424200687949680708,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.string,
    ),
    r'amount': PropertySchema(
      id: 1,
      name: r'amount',
      type: IsarType.double,
    ),
    r'categoryUuid': PropertySchema(
      id: 2,
      name: r'categoryUuid',
      type: IsarType.string,
    ),
    r'encryptedDescription': PropertySchema(
      id: 3,
      name: r'encryptedDescription',
      type: IsarType.string,
    ),
    r'frequencyDays': PropertySchema(
      id: 4,
      name: r'frequencyDays',
      type: IsarType.long,
    ),
    r'lastExecuted': PropertySchema(
      id: 5,
      name: r'lastExecuted',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _plannedTransactionEstimateSize,
  serialize: _plannedTransactionSerialize,
  deserialize: _plannedTransactionDeserialize,
  deserializeProp: _plannedTransactionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _plannedTransactionGetId,
  getLinks: _plannedTransactionGetLinks,
  attach: _plannedTransactionAttach,
  version: '3.1.0+1',
);

int _plannedTransactionEstimateSize(
  PlannedTransaction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.accountId.length * 3;
  bytesCount += 3 + object.categoryUuid.length * 3;
  bytesCount += 3 + object.encryptedDescription.length * 3;
  return bytesCount;
}

void _plannedTransactionSerialize(
  PlannedTransaction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accountId);
  writer.writeDouble(offsets[1], object.amount);
  writer.writeString(offsets[2], object.categoryUuid);
  writer.writeString(offsets[3], object.encryptedDescription);
  writer.writeLong(offsets[4], object.frequencyDays);
  writer.writeDateTime(offsets[5], object.lastExecuted);
}

PlannedTransaction _plannedTransactionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlannedTransaction();
  object.accountId = reader.readString(offsets[0]);
  object.amount = reader.readDouble(offsets[1]);
  object.categoryUuid = reader.readString(offsets[2]);
  object.encryptedDescription = reader.readString(offsets[3]);
  object.frequencyDays = reader.readLong(offsets[4]);
  object.id = id;
  object.lastExecuted = reader.readDateTime(offsets[5]);
  return object;
}

P _plannedTransactionDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _plannedTransactionGetId(PlannedTransaction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _plannedTransactionGetLinks(
    PlannedTransaction object) {
  return [];
}

void _plannedTransactionAttach(
    IsarCollection<dynamic> col, Id id, PlannedTransaction object) {
  object.id = id;
}

extension PlannedTransactionQueryWhereSort
    on QueryBuilder<PlannedTransaction, PlannedTransaction, QWhere> {
  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PlannedTransactionQueryWhere
    on QueryBuilder<PlannedTransaction, PlannedTransaction, QWhereClause> {
  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterWhereClause>
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

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterWhereClause>
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
}

extension PlannedTransactionQueryFilter
    on QueryBuilder<PlannedTransaction, PlannedTransaction, QFilterCondition> {
  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      accountIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      accountIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      accountIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      accountIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accountId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      accountIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      accountIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      accountIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      accountIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accountId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      accountIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: '',
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      accountIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accountId',
        value: '',
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
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

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
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

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
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

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
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

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
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

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
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

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      categoryUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      categoryUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      categoryUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      categoryUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      encryptedDescriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'encryptedDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      encryptedDescriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'encryptedDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      encryptedDescriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'encryptedDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      encryptedDescriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'encryptedDescription',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      encryptedDescriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'encryptedDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      encryptedDescriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'encryptedDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      encryptedDescriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'encryptedDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      encryptedDescriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'encryptedDescription',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      encryptedDescriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'encryptedDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      encryptedDescriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'encryptedDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      frequencyDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequencyDays',
        value: value,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      frequencyDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'frequencyDays',
        value: value,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      frequencyDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'frequencyDays',
        value: value,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      frequencyDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'frequencyDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
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

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
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

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
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

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      lastExecutedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastExecuted',
        value: value,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      lastExecutedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastExecuted',
        value: value,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      lastExecutedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastExecuted',
        value: value,
      ));
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterFilterCondition>
      lastExecutedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastExecuted',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PlannedTransactionQueryObject
    on QueryBuilder<PlannedTransaction, PlannedTransaction, QFilterCondition> {}

extension PlannedTransactionQueryLinks
    on QueryBuilder<PlannedTransaction, PlannedTransaction, QFilterCondition> {}

extension PlannedTransactionQuerySortBy
    on QueryBuilder<PlannedTransaction, PlannedTransaction, QSortBy> {
  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByCategoryUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByCategoryUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.desc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByEncryptedDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedDescription', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByEncryptedDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedDescription', Sort.desc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByFrequencyDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequencyDays', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByFrequencyDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequencyDays', Sort.desc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByLastExecuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastExecuted', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      sortByLastExecutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastExecuted', Sort.desc);
    });
  }
}

extension PlannedTransactionQuerySortThenBy
    on QueryBuilder<PlannedTransaction, PlannedTransaction, QSortThenBy> {
  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByCategoryUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByCategoryUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryUuid', Sort.desc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByEncryptedDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedDescription', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByEncryptedDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'encryptedDescription', Sort.desc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByFrequencyDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequencyDays', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByFrequencyDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequencyDays', Sort.desc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByLastExecuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastExecuted', Sort.asc);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QAfterSortBy>
      thenByLastExecutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastExecuted', Sort.desc);
    });
  }
}

extension PlannedTransactionQueryWhereDistinct
    on QueryBuilder<PlannedTransaction, PlannedTransaction, QDistinct> {
  QueryBuilder<PlannedTransaction, PlannedTransaction, QDistinct>
      distinctByAccountId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QDistinct>
      distinctByCategoryUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QDistinct>
      distinctByEncryptedDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'encryptedDescription',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QDistinct>
      distinctByFrequencyDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frequencyDays');
    });
  }

  QueryBuilder<PlannedTransaction, PlannedTransaction, QDistinct>
      distinctByLastExecuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastExecuted');
    });
  }
}

extension PlannedTransactionQueryProperty
    on QueryBuilder<PlannedTransaction, PlannedTransaction, QQueryProperty> {
  QueryBuilder<PlannedTransaction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PlannedTransaction, String, QQueryOperations>
      accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<PlannedTransaction, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<PlannedTransaction, String, QQueryOperations>
      categoryUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryUuid');
    });
  }

  QueryBuilder<PlannedTransaction, String, QQueryOperations>
      encryptedDescriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'encryptedDescription');
    });
  }

  QueryBuilder<PlannedTransaction, int, QQueryOperations>
      frequencyDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frequencyDays');
    });
  }

  QueryBuilder<PlannedTransaction, DateTime, QQueryOperations>
      lastExecutedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastExecuted');
    });
  }
}
