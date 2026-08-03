// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReviewCardsTable extends ReviewCards
    with TableInfo<$ReviewCardsTable, ReviewCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterMeta = const VerificationMeta(
    'character',
  );
  @override
  late final GeneratedColumn<String> character = GeneratedColumn<String>(
    'character',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CardType, int> cardType =
      GeneratedColumn<int>(
        'card_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CardType>($ReviewCardsTable.$convertercardType);
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    character,
    cardType,
    easeFactor,
    intervalDays,
    repetitions,
    dueDate,
    lastReviewedAt,
    lapses,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character')) {
      context.handle(
        _characterMeta,
        character.isAcceptableOrUnknown(data['character']!, _characterMeta),
      );
    } else if (isInserting) {
      context.missing(_characterMeta);
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {character, cardType};
  @override
  ReviewCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewCard(
      character: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character'],
      )!,
      cardType: $ReviewCardsTable.$convertercardType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}card_type'],
        )!,
      ),
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
    );
  }

  @override
  $ReviewCardsTable createAlias(String alias) {
    return $ReviewCardsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CardType, int, int> $convertercardType =
      const EnumIndexConverter<CardType>(CardType.values);
}

class ReviewCard extends DataClass implements Insertable<ReviewCard> {
  final String character;
  final CardType cardType;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueDate;
  final DateTime? lastReviewedAt;
  final int lapses;
  const ReviewCard({
    required this.character,
    required this.cardType,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueDate,
    this.lastReviewedAt,
    required this.lapses,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character'] = Variable<String>(character);
    {
      map['card_type'] = Variable<int>(
        $ReviewCardsTable.$convertercardType.toSql(cardType),
      );
    }
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    map['due_date'] = Variable<DateTime>(dueDate);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    map['lapses'] = Variable<int>(lapses);
    return map;
  }

  ReviewCardsCompanion toCompanion(bool nullToAbsent) {
    return ReviewCardsCompanion(
      character: Value(character),
      cardType: Value(cardType),
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      dueDate: Value(dueDate),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      lapses: Value(lapses),
    );
  }

  factory ReviewCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewCard(
      character: serializer.fromJson<String>(json['character']),
      cardType: $ReviewCardsTable.$convertercardType.fromJson(
        serializer.fromJson<int>(json['cardType']),
      ),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      lapses: serializer.fromJson<int>(json['lapses']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'character': serializer.toJson<String>(character),
      'cardType': serializer.toJson<int>(
        $ReviewCardsTable.$convertercardType.toJson(cardType),
      ),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'lapses': serializer.toJson<int>(lapses),
    };
  }

  ReviewCard copyWith({
    String? character,
    CardType? cardType,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? dueDate,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    int? lapses,
  }) => ReviewCard(
    character: character ?? this.character,
    cardType: cardType ?? this.cardType,
    easeFactor: easeFactor ?? this.easeFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    dueDate: dueDate ?? this.dueDate,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    lapses: lapses ?? this.lapses,
  );
  ReviewCard copyWithCompanion(ReviewCardsCompanion data) {
    return ReviewCard(
      character: data.character.present ? data.character.value : this.character,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewCard(')
          ..write('character: $character, ')
          ..write('cardType: $cardType, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('dueDate: $dueDate, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('lapses: $lapses')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    character,
    cardType,
    easeFactor,
    intervalDays,
    repetitions,
    dueDate,
    lastReviewedAt,
    lapses,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewCard &&
          other.character == this.character &&
          other.cardType == this.cardType &&
          other.easeFactor == this.easeFactor &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.dueDate == this.dueDate &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.lapses == this.lapses);
}

class ReviewCardsCompanion extends UpdateCompanion<ReviewCard> {
  final Value<String> character;
  final Value<CardType> cardType;
  final Value<double> easeFactor;
  final Value<int> intervalDays;
  final Value<int> repetitions;
  final Value<DateTime> dueDate;
  final Value<DateTime?> lastReviewedAt;
  final Value<int> lapses;
  final Value<int> rowid;
  const ReviewCardsCompanion({
    this.character = const Value.absent(),
    this.cardType = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.lapses = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewCardsCompanion.insert({
    required String character,
    required CardType cardType,
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    required DateTime dueDate,
    this.lastReviewedAt = const Value.absent(),
    this.lapses = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : character = Value(character),
       cardType = Value(cardType),
       dueDate = Value(dueDate);
  static Insertable<ReviewCard> custom({
    Expression<String>? character,
    Expression<int>? cardType,
    Expression<double>? easeFactor,
    Expression<int>? intervalDays,
    Expression<int>? repetitions,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? lastReviewedAt,
    Expression<int>? lapses,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (character != null) 'character': character,
      if (cardType != null) 'card_type': cardType,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (dueDate != null) 'due_date': dueDate,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (lapses != null) 'lapses': lapses,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewCardsCompanion copyWith({
    Value<String>? character,
    Value<CardType>? cardType,
    Value<double>? easeFactor,
    Value<int>? intervalDays,
    Value<int>? repetitions,
    Value<DateTime>? dueDate,
    Value<DateTime?>? lastReviewedAt,
    Value<int>? lapses,
    Value<int>? rowid,
  }) {
    return ReviewCardsCompanion(
      character: character ?? this.character,
      cardType: cardType ?? this.cardType,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      dueDate: dueDate ?? this.dueDate,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      lapses: lapses ?? this.lapses,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (character.present) {
      map['character'] = Variable<String>(character.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<int>(
        $ReviewCardsTable.$convertercardType.toSql(cardType.value),
      );
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewCardsCompanion(')
          ..write('character: $character, ')
          ..write('cardType: $cardType, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('dueDate: $dueDate, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('lapses: $lapses, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogTable extends ReviewLog
    with TableInfo<$ReviewLogTable, ReviewLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _characterMeta = const VerificationMeta(
    'character',
  );
  @override
  late final GeneratedColumn<String> character = GeneratedColumn<String>(
    'character',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CardType, int> cardType =
      GeneratedColumn<int>(
        'card_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CardType>($ReviewLogTable.$convertercardType);
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<int> quality = GeneratedColumn<int>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultingIntervalDaysMeta =
      const VerificationMeta('resultingIntervalDays');
  @override
  late final GeneratedColumn<int> resultingIntervalDays = GeneratedColumn<int>(
    'resulting_interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    character,
    cardType,
    reviewedAt,
    quality,
    resultingIntervalDays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('character')) {
      context.handle(
        _characterMeta,
        character.isAcceptableOrUnknown(data['character']!, _characterMeta),
      );
    } else if (isInserting) {
      context.missing(_characterMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('resulting_interval_days')) {
      context.handle(
        _resultingIntervalDaysMeta,
        resultingIntervalDays.isAcceptableOrUnknown(
          data['resulting_interval_days']!,
          _resultingIntervalDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resultingIntervalDaysMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      character: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character'],
      )!,
      cardType: $ReviewLogTable.$convertercardType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}card_type'],
        )!,
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quality'],
      )!,
      resultingIntervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resulting_interval_days'],
      )!,
    );
  }

  @override
  $ReviewLogTable createAlias(String alias) {
    return $ReviewLogTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CardType, int, int> $convertercardType =
      const EnumIndexConverter<CardType>(CardType.values);
}

class ReviewLogData extends DataClass implements Insertable<ReviewLogData> {
  final int id;
  final String character;
  final CardType cardType;
  final DateTime reviewedAt;
  final int quality;
  final int resultingIntervalDays;
  const ReviewLogData({
    required this.id,
    required this.character,
    required this.cardType,
    required this.reviewedAt,
    required this.quality,
    required this.resultingIntervalDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['character'] = Variable<String>(character);
    {
      map['card_type'] = Variable<int>(
        $ReviewLogTable.$convertercardType.toSql(cardType),
      );
    }
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['quality'] = Variable<int>(quality);
    map['resulting_interval_days'] = Variable<int>(resultingIntervalDays);
    return map;
  }

  ReviewLogCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogCompanion(
      id: Value(id),
      character: Value(character),
      cardType: Value(cardType),
      reviewedAt: Value(reviewedAt),
      quality: Value(quality),
      resultingIntervalDays: Value(resultingIntervalDays),
    );
  }

  factory ReviewLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLogData(
      id: serializer.fromJson<int>(json['id']),
      character: serializer.fromJson<String>(json['character']),
      cardType: $ReviewLogTable.$convertercardType.fromJson(
        serializer.fromJson<int>(json['cardType']),
      ),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      quality: serializer.fromJson<int>(json['quality']),
      resultingIntervalDays: serializer.fromJson<int>(
        json['resultingIntervalDays'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'character': serializer.toJson<String>(character),
      'cardType': serializer.toJson<int>(
        $ReviewLogTable.$convertercardType.toJson(cardType),
      ),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'quality': serializer.toJson<int>(quality),
      'resultingIntervalDays': serializer.toJson<int>(resultingIntervalDays),
    };
  }

  ReviewLogData copyWith({
    int? id,
    String? character,
    CardType? cardType,
    DateTime? reviewedAt,
    int? quality,
    int? resultingIntervalDays,
  }) => ReviewLogData(
    id: id ?? this.id,
    character: character ?? this.character,
    cardType: cardType ?? this.cardType,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    quality: quality ?? this.quality,
    resultingIntervalDays: resultingIntervalDays ?? this.resultingIntervalDays,
  );
  ReviewLogData copyWithCompanion(ReviewLogCompanion data) {
    return ReviewLogData(
      id: data.id.present ? data.id.value : this.id,
      character: data.character.present ? data.character.value : this.character,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      quality: data.quality.present ? data.quality.value : this.quality,
      resultingIntervalDays: data.resultingIntervalDays.present
          ? data.resultingIntervalDays.value
          : this.resultingIntervalDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogData(')
          ..write('id: $id, ')
          ..write('character: $character, ')
          ..write('cardType: $cardType, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('quality: $quality, ')
          ..write('resultingIntervalDays: $resultingIntervalDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    character,
    cardType,
    reviewedAt,
    quality,
    resultingIntervalDays,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLogData &&
          other.id == this.id &&
          other.character == this.character &&
          other.cardType == this.cardType &&
          other.reviewedAt == this.reviewedAt &&
          other.quality == this.quality &&
          other.resultingIntervalDays == this.resultingIntervalDays);
}

class ReviewLogCompanion extends UpdateCompanion<ReviewLogData> {
  final Value<int> id;
  final Value<String> character;
  final Value<CardType> cardType;
  final Value<DateTime> reviewedAt;
  final Value<int> quality;
  final Value<int> resultingIntervalDays;
  const ReviewLogCompanion({
    this.id = const Value.absent(),
    this.character = const Value.absent(),
    this.cardType = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.quality = const Value.absent(),
    this.resultingIntervalDays = const Value.absent(),
  });
  ReviewLogCompanion.insert({
    this.id = const Value.absent(),
    required String character,
    required CardType cardType,
    required DateTime reviewedAt,
    required int quality,
    required int resultingIntervalDays,
  }) : character = Value(character),
       cardType = Value(cardType),
       reviewedAt = Value(reviewedAt),
       quality = Value(quality),
       resultingIntervalDays = Value(resultingIntervalDays);
  static Insertable<ReviewLogData> custom({
    Expression<int>? id,
    Expression<String>? character,
    Expression<int>? cardType,
    Expression<DateTime>? reviewedAt,
    Expression<int>? quality,
    Expression<int>? resultingIntervalDays,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (character != null) 'character': character,
      if (cardType != null) 'card_type': cardType,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (quality != null) 'quality': quality,
      if (resultingIntervalDays != null)
        'resulting_interval_days': resultingIntervalDays,
    });
  }

  ReviewLogCompanion copyWith({
    Value<int>? id,
    Value<String>? character,
    Value<CardType>? cardType,
    Value<DateTime>? reviewedAt,
    Value<int>? quality,
    Value<int>? resultingIntervalDays,
  }) {
    return ReviewLogCompanion(
      id: id ?? this.id,
      character: character ?? this.character,
      cardType: cardType ?? this.cardType,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      quality: quality ?? this.quality,
      resultingIntervalDays:
          resultingIntervalDays ?? this.resultingIntervalDays,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (character.present) {
      map['character'] = Variable<String>(character.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<int>(
        $ReviewLogTable.$convertercardType.toSql(cardType.value),
      );
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (quality.present) {
      map['quality'] = Variable<int>(quality.value);
    }
    if (resultingIntervalDays.present) {
      map['resulting_interval_days'] = Variable<int>(
        resultingIntervalDays.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogCompanion(')
          ..write('id: $id, ')
          ..write('character: $character, ')
          ..write('cardType: $cardType, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('quality: $quality, ')
          ..write('resultingIntervalDays: $resultingIntervalDays')
          ..write(')'))
        .toString();
  }
}

class $KanjiNotesTable extends KanjiNotes
    with TableInfo<$KanjiNotesTable, KanjiNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KanjiNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterMeta = const VerificationMeta(
    'character',
  );
  @override
  late final GeneratedColumn<String> character = GeneratedColumn<String>(
    'character',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storyKeywordMeta = const VerificationMeta(
    'storyKeyword',
  );
  @override
  late final GeneratedColumn<String> storyKeyword = GeneratedColumn<String>(
    'story_keyword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _storyMeta = const VerificationMeta('story');
  @override
  late final GeneratedColumn<String> story = GeneratedColumn<String>(
    'story',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    character,
    storyKeyword,
    story,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kanji_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<KanjiNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character')) {
      context.handle(
        _characterMeta,
        character.isAcceptableOrUnknown(data['character']!, _characterMeta),
      );
    } else if (isInserting) {
      context.missing(_characterMeta);
    }
    if (data.containsKey('story_keyword')) {
      context.handle(
        _storyKeywordMeta,
        storyKeyword.isAcceptableOrUnknown(
          data['story_keyword']!,
          _storyKeywordMeta,
        ),
      );
    }
    if (data.containsKey('story')) {
      context.handle(
        _storyMeta,
        story.isAcceptableOrUnknown(data['story']!, _storyMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {character};
  @override
  KanjiNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KanjiNote(
      character: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character'],
      )!,
      storyKeyword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}story_keyword'],
      )!,
      story: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}story'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $KanjiNotesTable createAlias(String alias) {
    return $KanjiNotesTable(attachedDatabase, alias);
  }
}

class KanjiNote extends DataClass implements Insertable<KanjiNote> {
  final String character;
  final String storyKeyword;
  final String story;
  final DateTime? updatedAt;
  const KanjiNote({
    required this.character,
    required this.storyKeyword,
    required this.story,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character'] = Variable<String>(character);
    map['story_keyword'] = Variable<String>(storyKeyword);
    map['story'] = Variable<String>(story);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  KanjiNotesCompanion toCompanion(bool nullToAbsent) {
    return KanjiNotesCompanion(
      character: Value(character),
      storyKeyword: Value(storyKeyword),
      story: Value(story),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory KanjiNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KanjiNote(
      character: serializer.fromJson<String>(json['character']),
      storyKeyword: serializer.fromJson<String>(json['storyKeyword']),
      story: serializer.fromJson<String>(json['story']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'character': serializer.toJson<String>(character),
      'storyKeyword': serializer.toJson<String>(storyKeyword),
      'story': serializer.toJson<String>(story),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  KanjiNote copyWith({
    String? character,
    String? storyKeyword,
    String? story,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => KanjiNote(
    character: character ?? this.character,
    storyKeyword: storyKeyword ?? this.storyKeyword,
    story: story ?? this.story,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  KanjiNote copyWithCompanion(KanjiNotesCompanion data) {
    return KanjiNote(
      character: data.character.present ? data.character.value : this.character,
      storyKeyword: data.storyKeyword.present
          ? data.storyKeyword.value
          : this.storyKeyword,
      story: data.story.present ? data.story.value : this.story,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KanjiNote(')
          ..write('character: $character, ')
          ..write('storyKeyword: $storyKeyword, ')
          ..write('story: $story, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(character, storyKeyword, story, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KanjiNote &&
          other.character == this.character &&
          other.storyKeyword == this.storyKeyword &&
          other.story == this.story &&
          other.updatedAt == this.updatedAt);
}

class KanjiNotesCompanion extends UpdateCompanion<KanjiNote> {
  final Value<String> character;
  final Value<String> storyKeyword;
  final Value<String> story;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const KanjiNotesCompanion({
    this.character = const Value.absent(),
    this.storyKeyword = const Value.absent(),
    this.story = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KanjiNotesCompanion.insert({
    required String character,
    this.storyKeyword = const Value.absent(),
    this.story = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : character = Value(character);
  static Insertable<KanjiNote> custom({
    Expression<String>? character,
    Expression<String>? storyKeyword,
    Expression<String>? story,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (character != null) 'character': character,
      if (storyKeyword != null) 'story_keyword': storyKeyword,
      if (story != null) 'story': story,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KanjiNotesCompanion copyWith({
    Value<String>? character,
    Value<String>? storyKeyword,
    Value<String>? story,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return KanjiNotesCompanion(
      character: character ?? this.character,
      storyKeyword: storyKeyword ?? this.storyKeyword,
      story: story ?? this.story,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (character.present) {
      map['character'] = Variable<String>(character.value);
    }
    if (storyKeyword.present) {
      map['story_keyword'] = Variable<String>(storyKeyword.value);
    }
    if (story.present) {
      map['story'] = Variable<String>(story.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KanjiNotesCompanion(')
          ..write('character: $character, ')
          ..write('storyKeyword: $storyKeyword, ')
          ..write('story: $story, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KanjiStaticTable extends KanjiStatic
    with TableInfo<$KanjiStaticTable, KanjiStaticData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KanjiStaticTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterMeta = const VerificationMeta(
    'character',
  );
  @override
  late final GeneratedColumn<String> character = GeneratedColumn<String>(
    'character',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jlptLevelMeta = const VerificationMeta(
    'jlptLevel',
  );
  @override
  late final GeneratedColumn<int> jlptLevel = GeneratedColumn<int>(
    'jlpt_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rtkIndexMeta = const VerificationMeta(
    'rtkIndex',
  );
  @override
  late final GeneratedColumn<int> rtkIndex = GeneratedColumn<int>(
    'rtk_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelRankMeta = const VerificationMeta(
    'levelRank',
  );
  @override
  late final GeneratedColumn<int> levelRank = GeneratedColumn<int>(
    'level_rank',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    character,
    jlptLevel,
    rtkIndex,
    levelRank,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kanji_static';
  @override
  VerificationContext validateIntegrity(
    Insertable<KanjiStaticData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character')) {
      context.handle(
        _characterMeta,
        character.isAcceptableOrUnknown(data['character']!, _characterMeta),
      );
    } else if (isInserting) {
      context.missing(_characterMeta);
    }
    if (data.containsKey('jlpt_level')) {
      context.handle(
        _jlptLevelMeta,
        jlptLevel.isAcceptableOrUnknown(data['jlpt_level']!, _jlptLevelMeta),
      );
    }
    if (data.containsKey('rtk_index')) {
      context.handle(
        _rtkIndexMeta,
        rtkIndex.isAcceptableOrUnknown(data['rtk_index']!, _rtkIndexMeta),
      );
    }
    if (data.containsKey('level_rank')) {
      context.handle(
        _levelRankMeta,
        levelRank.isAcceptableOrUnknown(data['level_rank']!, _levelRankMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {character};
  @override
  KanjiStaticData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KanjiStaticData(
      character: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character'],
      )!,
      jlptLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jlpt_level'],
      ),
      rtkIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rtk_index'],
      ),
      levelRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level_rank'],
      ),
    );
  }

  @override
  $KanjiStaticTable createAlias(String alias) {
    return $KanjiStaticTable(attachedDatabase, alias);
  }
}

class KanjiStaticData extends DataClass implements Insertable<KanjiStaticData> {
  final String character;
  final int? jlptLevel;
  final int? rtkIndex;
  final int? levelRank;
  const KanjiStaticData({
    required this.character,
    this.jlptLevel,
    this.rtkIndex,
    this.levelRank,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character'] = Variable<String>(character);
    if (!nullToAbsent || jlptLevel != null) {
      map['jlpt_level'] = Variable<int>(jlptLevel);
    }
    if (!nullToAbsent || rtkIndex != null) {
      map['rtk_index'] = Variable<int>(rtkIndex);
    }
    if (!nullToAbsent || levelRank != null) {
      map['level_rank'] = Variable<int>(levelRank);
    }
    return map;
  }

  KanjiStaticCompanion toCompanion(bool nullToAbsent) {
    return KanjiStaticCompanion(
      character: Value(character),
      jlptLevel: jlptLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(jlptLevel),
      rtkIndex: rtkIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(rtkIndex),
      levelRank: levelRank == null && nullToAbsent
          ? const Value.absent()
          : Value(levelRank),
    );
  }

  factory KanjiStaticData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KanjiStaticData(
      character: serializer.fromJson<String>(json['character']),
      jlptLevel: serializer.fromJson<int?>(json['jlptLevel']),
      rtkIndex: serializer.fromJson<int?>(json['rtkIndex']),
      levelRank: serializer.fromJson<int?>(json['levelRank']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'character': serializer.toJson<String>(character),
      'jlptLevel': serializer.toJson<int?>(jlptLevel),
      'rtkIndex': serializer.toJson<int?>(rtkIndex),
      'levelRank': serializer.toJson<int?>(levelRank),
    };
  }

  KanjiStaticData copyWith({
    String? character,
    Value<int?> jlptLevel = const Value.absent(),
    Value<int?> rtkIndex = const Value.absent(),
    Value<int?> levelRank = const Value.absent(),
  }) => KanjiStaticData(
    character: character ?? this.character,
    jlptLevel: jlptLevel.present ? jlptLevel.value : this.jlptLevel,
    rtkIndex: rtkIndex.present ? rtkIndex.value : this.rtkIndex,
    levelRank: levelRank.present ? levelRank.value : this.levelRank,
  );
  KanjiStaticData copyWithCompanion(KanjiStaticCompanion data) {
    return KanjiStaticData(
      character: data.character.present ? data.character.value : this.character,
      jlptLevel: data.jlptLevel.present ? data.jlptLevel.value : this.jlptLevel,
      rtkIndex: data.rtkIndex.present ? data.rtkIndex.value : this.rtkIndex,
      levelRank: data.levelRank.present ? data.levelRank.value : this.levelRank,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KanjiStaticData(')
          ..write('character: $character, ')
          ..write('jlptLevel: $jlptLevel, ')
          ..write('rtkIndex: $rtkIndex, ')
          ..write('levelRank: $levelRank')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(character, jlptLevel, rtkIndex, levelRank);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KanjiStaticData &&
          other.character == this.character &&
          other.jlptLevel == this.jlptLevel &&
          other.rtkIndex == this.rtkIndex &&
          other.levelRank == this.levelRank);
}

class KanjiStaticCompanion extends UpdateCompanion<KanjiStaticData> {
  final Value<String> character;
  final Value<int?> jlptLevel;
  final Value<int?> rtkIndex;
  final Value<int?> levelRank;
  final Value<int> rowid;
  const KanjiStaticCompanion({
    this.character = const Value.absent(),
    this.jlptLevel = const Value.absent(),
    this.rtkIndex = const Value.absent(),
    this.levelRank = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KanjiStaticCompanion.insert({
    required String character,
    this.jlptLevel = const Value.absent(),
    this.rtkIndex = const Value.absent(),
    this.levelRank = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : character = Value(character);
  static Insertable<KanjiStaticData> custom({
    Expression<String>? character,
    Expression<int>? jlptLevel,
    Expression<int>? rtkIndex,
    Expression<int>? levelRank,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (character != null) 'character': character,
      if (jlptLevel != null) 'jlpt_level': jlptLevel,
      if (rtkIndex != null) 'rtk_index': rtkIndex,
      if (levelRank != null) 'level_rank': levelRank,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KanjiStaticCompanion copyWith({
    Value<String>? character,
    Value<int?>? jlptLevel,
    Value<int?>? rtkIndex,
    Value<int?>? levelRank,
    Value<int>? rowid,
  }) {
    return KanjiStaticCompanion(
      character: character ?? this.character,
      jlptLevel: jlptLevel ?? this.jlptLevel,
      rtkIndex: rtkIndex ?? this.rtkIndex,
      levelRank: levelRank ?? this.levelRank,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (character.present) {
      map['character'] = Variable<String>(character.value);
    }
    if (jlptLevel.present) {
      map['jlpt_level'] = Variable<int>(jlptLevel.value);
    }
    if (rtkIndex.present) {
      map['rtk_index'] = Variable<int>(rtkIndex.value);
    }
    if (levelRank.present) {
      map['level_rank'] = Variable<int>(levelRank.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KanjiStaticCompanion(')
          ..write('character: $character, ')
          ..write('jlptLevel: $jlptLevel, ')
          ..write('rtkIndex: $rtkIndex, ')
          ..write('levelRank: $levelRank, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompositaProgressTable extends CompositaProgress
    with TableInfo<$CompositaProgressTable, CompositaProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompositaProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterMeta = const VerificationMeta(
    'character',
  );
  @override
  late final GeneratedColumn<String> character = GeneratedColumn<String>(
    'character',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CompositaDirection, int>
  direction =
      GeneratedColumn<int>(
        'direction',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<CompositaDirection>(
        $CompositaProgressTable.$converterdirection,
      );
  static const VerificationMeta _firstPassedAtMeta = const VerificationMeta(
    'firstPassedAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstPassedAt =
      GeneratedColumn<DateTime>(
        'first_passed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    character,
    word,
    direction,
    firstPassedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'composita_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompositaProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character')) {
      context.handle(
        _characterMeta,
        character.isAcceptableOrUnknown(data['character']!, _characterMeta),
      );
    } else if (isInserting) {
      context.missing(_characterMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('first_passed_at')) {
      context.handle(
        _firstPassedAtMeta,
        firstPassedAt.isAcceptableOrUnknown(
          data['first_passed_at']!,
          _firstPassedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstPassedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {character, word, direction};
  @override
  CompositaProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompositaProgressData(
      character: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      direction: $CompositaProgressTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}direction'],
        )!,
      ),
      firstPassedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_passed_at'],
      )!,
    );
  }

  @override
  $CompositaProgressTable createAlias(String alias) {
    return $CompositaProgressTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CompositaDirection, int, int> $converterdirection =
      const EnumIndexConverter<CompositaDirection>(CompositaDirection.values);
}

class CompositaProgressData extends DataClass
    implements Insertable<CompositaProgressData> {
  final String character;
  final String word;
  final CompositaDirection direction;
  final DateTime firstPassedAt;
  const CompositaProgressData({
    required this.character,
    required this.word,
    required this.direction,
    required this.firstPassedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character'] = Variable<String>(character);
    map['word'] = Variable<String>(word);
    {
      map['direction'] = Variable<int>(
        $CompositaProgressTable.$converterdirection.toSql(direction),
      );
    }
    map['first_passed_at'] = Variable<DateTime>(firstPassedAt);
    return map;
  }

  CompositaProgressCompanion toCompanion(bool nullToAbsent) {
    return CompositaProgressCompanion(
      character: Value(character),
      word: Value(word),
      direction: Value(direction),
      firstPassedAt: Value(firstPassedAt),
    );
  }

  factory CompositaProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompositaProgressData(
      character: serializer.fromJson<String>(json['character']),
      word: serializer.fromJson<String>(json['word']),
      direction: $CompositaProgressTable.$converterdirection.fromJson(
        serializer.fromJson<int>(json['direction']),
      ),
      firstPassedAt: serializer.fromJson<DateTime>(json['firstPassedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'character': serializer.toJson<String>(character),
      'word': serializer.toJson<String>(word),
      'direction': serializer.toJson<int>(
        $CompositaProgressTable.$converterdirection.toJson(direction),
      ),
      'firstPassedAt': serializer.toJson<DateTime>(firstPassedAt),
    };
  }

  CompositaProgressData copyWith({
    String? character,
    String? word,
    CompositaDirection? direction,
    DateTime? firstPassedAt,
  }) => CompositaProgressData(
    character: character ?? this.character,
    word: word ?? this.word,
    direction: direction ?? this.direction,
    firstPassedAt: firstPassedAt ?? this.firstPassedAt,
  );
  CompositaProgressData copyWithCompanion(CompositaProgressCompanion data) {
    return CompositaProgressData(
      character: data.character.present ? data.character.value : this.character,
      word: data.word.present ? data.word.value : this.word,
      direction: data.direction.present ? data.direction.value : this.direction,
      firstPassedAt: data.firstPassedAt.present
          ? data.firstPassedAt.value
          : this.firstPassedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompositaProgressData(')
          ..write('character: $character, ')
          ..write('word: $word, ')
          ..write('direction: $direction, ')
          ..write('firstPassedAt: $firstPassedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(character, word, direction, firstPassedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompositaProgressData &&
          other.character == this.character &&
          other.word == this.word &&
          other.direction == this.direction &&
          other.firstPassedAt == this.firstPassedAt);
}

class CompositaProgressCompanion
    extends UpdateCompanion<CompositaProgressData> {
  final Value<String> character;
  final Value<String> word;
  final Value<CompositaDirection> direction;
  final Value<DateTime> firstPassedAt;
  final Value<int> rowid;
  const CompositaProgressCompanion({
    this.character = const Value.absent(),
    this.word = const Value.absent(),
    this.direction = const Value.absent(),
    this.firstPassedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompositaProgressCompanion.insert({
    required String character,
    required String word,
    required CompositaDirection direction,
    required DateTime firstPassedAt,
    this.rowid = const Value.absent(),
  }) : character = Value(character),
       word = Value(word),
       direction = Value(direction),
       firstPassedAt = Value(firstPassedAt);
  static Insertable<CompositaProgressData> custom({
    Expression<String>? character,
    Expression<String>? word,
    Expression<int>? direction,
    Expression<DateTime>? firstPassedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (character != null) 'character': character,
      if (word != null) 'word': word,
      if (direction != null) 'direction': direction,
      if (firstPassedAt != null) 'first_passed_at': firstPassedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompositaProgressCompanion copyWith({
    Value<String>? character,
    Value<String>? word,
    Value<CompositaDirection>? direction,
    Value<DateTime>? firstPassedAt,
    Value<int>? rowid,
  }) {
    return CompositaProgressCompanion(
      character: character ?? this.character,
      word: word ?? this.word,
      direction: direction ?? this.direction,
      firstPassedAt: firstPassedAt ?? this.firstPassedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (character.present) {
      map['character'] = Variable<String>(character.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (direction.present) {
      map['direction'] = Variable<int>(
        $CompositaProgressTable.$converterdirection.toSql(direction.value),
      );
    }
    if (firstPassedAt.present) {
      map['first_passed_at'] = Variable<DateTime>(firstPassedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompositaProgressCompanion(')
          ..write('character: $character, ')
          ..write('word: $word, ')
          ..write('direction: $direction, ')
          ..write('firstPassedAt: $firstPassedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomCompositaTable extends CustomComposita
    with TableInfo<$CustomCompositaTable, CustomCompositaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomCompositaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterMeta = const VerificationMeta(
    'character',
  );
  @override
  late final GeneratedColumn<String> character = GeneratedColumn<String>(
    'character',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [character, word];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_composita';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomCompositaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character')) {
      context.handle(
        _characterMeta,
        character.isAcceptableOrUnknown(data['character']!, _characterMeta),
      );
    } else if (isInserting) {
      context.missing(_characterMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {character, word};
  @override
  CustomCompositaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomCompositaData(
      character: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
    );
  }

  @override
  $CustomCompositaTable createAlias(String alias) {
    return $CustomCompositaTable(attachedDatabase, alias);
  }
}

class CustomCompositaData extends DataClass
    implements Insertable<CustomCompositaData> {
  final String character;
  final String word;
  const CustomCompositaData({required this.character, required this.word});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character'] = Variable<String>(character);
    map['word'] = Variable<String>(word);
    return map;
  }

  CustomCompositaCompanion toCompanion(bool nullToAbsent) {
    return CustomCompositaCompanion(
      character: Value(character),
      word: Value(word),
    );
  }

  factory CustomCompositaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomCompositaData(
      character: serializer.fromJson<String>(json['character']),
      word: serializer.fromJson<String>(json['word']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'character': serializer.toJson<String>(character),
      'word': serializer.toJson<String>(word),
    };
  }

  CustomCompositaData copyWith({String? character, String? word}) =>
      CustomCompositaData(
        character: character ?? this.character,
        word: word ?? this.word,
      );
  CustomCompositaData copyWithCompanion(CustomCompositaCompanion data) {
    return CustomCompositaData(
      character: data.character.present ? data.character.value : this.character,
      word: data.word.present ? data.word.value : this.word,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomCompositaData(')
          ..write('character: $character, ')
          ..write('word: $word')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(character, word);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomCompositaData &&
          other.character == this.character &&
          other.word == this.word);
}

class CustomCompositaCompanion extends UpdateCompanion<CustomCompositaData> {
  final Value<String> character;
  final Value<String> word;
  final Value<int> rowid;
  const CustomCompositaCompanion({
    this.character = const Value.absent(),
    this.word = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomCompositaCompanion.insert({
    required String character,
    required String word,
    this.rowid = const Value.absent(),
  }) : character = Value(character),
       word = Value(word);
  static Insertable<CustomCompositaData> custom({
    Expression<String>? character,
    Expression<String>? word,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (character != null) 'character': character,
      if (word != null) 'word': word,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomCompositaCompanion copyWith({
    Value<String>? character,
    Value<String>? word,
    Value<int>? rowid,
  }) {
    return CustomCompositaCompanion(
      character: character ?? this.character,
      word: word ?? this.word,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (character.present) {
      map['character'] = Variable<String>(character.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomCompositaCompanion(')
          ..write('character: $character, ')
          ..write('word: $word, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserCompositaTable extends UserComposita
    with TableInfo<$UserCompositaTable, UserCompositaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCompositaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _characterMeta = const VerificationMeta(
    'character',
  );
  @override
  late final GeneratedColumn<String> character = GeneratedColumn<String>(
    'character',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [character, word, reading, meaning];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_composita';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserCompositaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('character')) {
      context.handle(
        _characterMeta,
        character.isAcceptableOrUnknown(data['character']!, _characterMeta),
      );
    } else if (isInserting) {
      context.missing(_characterMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {character, word};
  @override
  UserCompositaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserCompositaData(
      character: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
    );
  }

  @override
  $UserCompositaTable createAlias(String alias) {
    return $UserCompositaTable(attachedDatabase, alias);
  }
}

class UserCompositaData extends DataClass
    implements Insertable<UserCompositaData> {
  final String character;
  final String word;
  final String reading;
  final String meaning;
  const UserCompositaData({
    required this.character,
    required this.word,
    required this.reading,
    required this.meaning,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['character'] = Variable<String>(character);
    map['word'] = Variable<String>(word);
    map['reading'] = Variable<String>(reading);
    map['meaning'] = Variable<String>(meaning);
    return map;
  }

  UserCompositaCompanion toCompanion(bool nullToAbsent) {
    return UserCompositaCompanion(
      character: Value(character),
      word: Value(word),
      reading: Value(reading),
      meaning: Value(meaning),
    );
  }

  factory UserCompositaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserCompositaData(
      character: serializer.fromJson<String>(json['character']),
      word: serializer.fromJson<String>(json['word']),
      reading: serializer.fromJson<String>(json['reading']),
      meaning: serializer.fromJson<String>(json['meaning']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'character': serializer.toJson<String>(character),
      'word': serializer.toJson<String>(word),
      'reading': serializer.toJson<String>(reading),
      'meaning': serializer.toJson<String>(meaning),
    };
  }

  UserCompositaData copyWith({
    String? character,
    String? word,
    String? reading,
    String? meaning,
  }) => UserCompositaData(
    character: character ?? this.character,
    word: word ?? this.word,
    reading: reading ?? this.reading,
    meaning: meaning ?? this.meaning,
  );
  UserCompositaData copyWithCompanion(UserCompositaCompanion data) {
    return UserCompositaData(
      character: data.character.present ? data.character.value : this.character,
      word: data.word.present ? data.word.value : this.word,
      reading: data.reading.present ? data.reading.value : this.reading,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserCompositaData(')
          ..write('character: $character, ')
          ..write('word: $word, ')
          ..write('reading: $reading, ')
          ..write('meaning: $meaning')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(character, word, reading, meaning);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserCompositaData &&
          other.character == this.character &&
          other.word == this.word &&
          other.reading == this.reading &&
          other.meaning == this.meaning);
}

class UserCompositaCompanion extends UpdateCompanion<UserCompositaData> {
  final Value<String> character;
  final Value<String> word;
  final Value<String> reading;
  final Value<String> meaning;
  final Value<int> rowid;
  const UserCompositaCompanion({
    this.character = const Value.absent(),
    this.word = const Value.absent(),
    this.reading = const Value.absent(),
    this.meaning = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserCompositaCompanion.insert({
    required String character,
    required String word,
    required String reading,
    required String meaning,
    this.rowid = const Value.absent(),
  }) : character = Value(character),
       word = Value(word),
       reading = Value(reading),
       meaning = Value(meaning);
  static Insertable<UserCompositaData> custom({
    Expression<String>? character,
    Expression<String>? word,
    Expression<String>? reading,
    Expression<String>? meaning,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (character != null) 'character': character,
      if (word != null) 'word': word,
      if (reading != null) 'reading': reading,
      if (meaning != null) 'meaning': meaning,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserCompositaCompanion copyWith({
    Value<String>? character,
    Value<String>? word,
    Value<String>? reading,
    Value<String>? meaning,
    Value<int>? rowid,
  }) {
    return UserCompositaCompanion(
      character: character ?? this.character,
      word: word ?? this.word,
      reading: reading ?? this.reading,
      meaning: meaning ?? this.meaning,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (character.present) {
      map['character'] = Variable<String>(character.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCompositaCompanion(')
          ..write('character: $character, ')
          ..write('word: $word, ')
          ..write('reading: $reading, ')
          ..write('meaning: $meaning, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReviewCardsTable reviewCards = $ReviewCardsTable(this);
  late final $ReviewLogTable reviewLog = $ReviewLogTable(this);
  late final $KanjiNotesTable kanjiNotes = $KanjiNotesTable(this);
  late final $KanjiStaticTable kanjiStatic = $KanjiStaticTable(this);
  late final $CompositaProgressTable compositaProgress =
      $CompositaProgressTable(this);
  late final $CustomCompositaTable customComposita = $CustomCompositaTable(
    this,
  );
  late final $UserCompositaTable userComposita = $UserCompositaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    reviewCards,
    reviewLog,
    kanjiNotes,
    kanjiStatic,
    compositaProgress,
    customComposita,
    userComposita,
  ];
}

typedef $$ReviewCardsTableCreateCompanionBuilder =
    ReviewCardsCompanion Function({
      required String character,
      required CardType cardType,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      required DateTime dueDate,
      Value<DateTime?> lastReviewedAt,
      Value<int> lapses,
      Value<int> rowid,
    });
typedef $$ReviewCardsTableUpdateCompanionBuilder =
    ReviewCardsCompanion Function({
      Value<String> character,
      Value<CardType> cardType,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<DateTime> dueDate,
      Value<DateTime?> lastReviewedAt,
      Value<int> lapses,
      Value<int> rowid,
    });

class $$ReviewCardsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CardType, CardType, int> get cardType =>
      $composableBuilder(
        column: $table.cardType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CardType, int> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);
}

class $$ReviewCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewCardsTable,
          ReviewCard,
          $$ReviewCardsTableFilterComposer,
          $$ReviewCardsTableOrderingComposer,
          $$ReviewCardsTableAnnotationComposer,
          $$ReviewCardsTableCreateCompanionBuilder,
          $$ReviewCardsTableUpdateCompanionBuilder,
          (
            ReviewCard,
            BaseReferences<_$AppDatabase, $ReviewCardsTable, ReviewCard>,
          ),
          ReviewCard,
          PrefetchHooks Function()
        > {
  $$ReviewCardsTableTableManager(_$AppDatabase db, $ReviewCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> character = const Value.absent(),
                Value<CardType> cardType = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewCardsCompanion(
                character: character,
                cardType: cardType,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                dueDate: dueDate,
                lastReviewedAt: lastReviewedAt,
                lapses: lapses,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String character,
                required CardType cardType,
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                required DateTime dueDate,
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewCardsCompanion.insert(
                character: character,
                cardType: cardType,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                dueDate: dueDate,
                lastReviewedAt: lastReviewedAt,
                lapses: lapses,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewCardsTable,
      ReviewCard,
      $$ReviewCardsTableFilterComposer,
      $$ReviewCardsTableOrderingComposer,
      $$ReviewCardsTableAnnotationComposer,
      $$ReviewCardsTableCreateCompanionBuilder,
      $$ReviewCardsTableUpdateCompanionBuilder,
      (
        ReviewCard,
        BaseReferences<_$AppDatabase, $ReviewCardsTable, ReviewCard>,
      ),
      ReviewCard,
      PrefetchHooks Function()
    >;
typedef $$ReviewLogTableCreateCompanionBuilder =
    ReviewLogCompanion Function({
      Value<int> id,
      required String character,
      required CardType cardType,
      required DateTime reviewedAt,
      required int quality,
      required int resultingIntervalDays,
    });
typedef $$ReviewLogTableUpdateCompanionBuilder =
    ReviewLogCompanion Function({
      Value<int> id,
      Value<String> character,
      Value<CardType> cardType,
      Value<DateTime> reviewedAt,
      Value<int> quality,
      Value<int> resultingIntervalDays,
    });

class $$ReviewLogTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogTable> {
  $$ReviewLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CardType, CardType, int> get cardType =>
      $composableBuilder(
        column: $table.cardType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resultingIntervalDays => $composableBuilder(
    column: $table.resultingIntervalDays,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewLogTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogTable> {
  $$ReviewLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resultingIntervalDays => $composableBuilder(
    column: $table.resultingIntervalDays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogTable> {
  $$ReviewLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CardType, int> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<int> get resultingIntervalDays => $composableBuilder(
    column: $table.resultingIntervalDays,
    builder: (column) => column,
  );
}

class $$ReviewLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogTable,
          ReviewLogData,
          $$ReviewLogTableFilterComposer,
          $$ReviewLogTableOrderingComposer,
          $$ReviewLogTableAnnotationComposer,
          $$ReviewLogTableCreateCompanionBuilder,
          $$ReviewLogTableUpdateCompanionBuilder,
          (
            ReviewLogData,
            BaseReferences<_$AppDatabase, $ReviewLogTable, ReviewLogData>,
          ),
          ReviewLogData,
          PrefetchHooks Function()
        > {
  $$ReviewLogTableTableManager(_$AppDatabase db, $ReviewLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> character = const Value.absent(),
                Value<CardType> cardType = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<int> quality = const Value.absent(),
                Value<int> resultingIntervalDays = const Value.absent(),
              }) => ReviewLogCompanion(
                id: id,
                character: character,
                cardType: cardType,
                reviewedAt: reviewedAt,
                quality: quality,
                resultingIntervalDays: resultingIntervalDays,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String character,
                required CardType cardType,
                required DateTime reviewedAt,
                required int quality,
                required int resultingIntervalDays,
              }) => ReviewLogCompanion.insert(
                id: id,
                character: character,
                cardType: cardType,
                reviewedAt: reviewedAt,
                quality: quality,
                resultingIntervalDays: resultingIntervalDays,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogTable,
      ReviewLogData,
      $$ReviewLogTableFilterComposer,
      $$ReviewLogTableOrderingComposer,
      $$ReviewLogTableAnnotationComposer,
      $$ReviewLogTableCreateCompanionBuilder,
      $$ReviewLogTableUpdateCompanionBuilder,
      (
        ReviewLogData,
        BaseReferences<_$AppDatabase, $ReviewLogTable, ReviewLogData>,
      ),
      ReviewLogData,
      PrefetchHooks Function()
    >;
typedef $$KanjiNotesTableCreateCompanionBuilder =
    KanjiNotesCompanion Function({
      required String character,
      Value<String> storyKeyword,
      Value<String> story,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$KanjiNotesTableUpdateCompanionBuilder =
    KanjiNotesCompanion Function({
      Value<String> character,
      Value<String> storyKeyword,
      Value<String> story,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$KanjiNotesTableFilterComposer
    extends Composer<_$AppDatabase, $KanjiNotesTable> {
  $$KanjiNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storyKeyword => $composableBuilder(
    column: $table.storyKeyword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get story => $composableBuilder(
    column: $table.story,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KanjiNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $KanjiNotesTable> {
  $$KanjiNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storyKeyword => $composableBuilder(
    column: $table.storyKeyword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get story => $composableBuilder(
    column: $table.story,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KanjiNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KanjiNotesTable> {
  $$KanjiNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumn<String> get storyKeyword => $composableBuilder(
    column: $table.storyKeyword,
    builder: (column) => column,
  );

  GeneratedColumn<String> get story =>
      $composableBuilder(column: $table.story, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$KanjiNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KanjiNotesTable,
          KanjiNote,
          $$KanjiNotesTableFilterComposer,
          $$KanjiNotesTableOrderingComposer,
          $$KanjiNotesTableAnnotationComposer,
          $$KanjiNotesTableCreateCompanionBuilder,
          $$KanjiNotesTableUpdateCompanionBuilder,
          (
            KanjiNote,
            BaseReferences<_$AppDatabase, $KanjiNotesTable, KanjiNote>,
          ),
          KanjiNote,
          PrefetchHooks Function()
        > {
  $$KanjiNotesTableTableManager(_$AppDatabase db, $KanjiNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KanjiNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KanjiNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KanjiNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> character = const Value.absent(),
                Value<String> storyKeyword = const Value.absent(),
                Value<String> story = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KanjiNotesCompanion(
                character: character,
                storyKeyword: storyKeyword,
                story: story,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String character,
                Value<String> storyKeyword = const Value.absent(),
                Value<String> story = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KanjiNotesCompanion.insert(
                character: character,
                storyKeyword: storyKeyword,
                story: story,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KanjiNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KanjiNotesTable,
      KanjiNote,
      $$KanjiNotesTableFilterComposer,
      $$KanjiNotesTableOrderingComposer,
      $$KanjiNotesTableAnnotationComposer,
      $$KanjiNotesTableCreateCompanionBuilder,
      $$KanjiNotesTableUpdateCompanionBuilder,
      (KanjiNote, BaseReferences<_$AppDatabase, $KanjiNotesTable, KanjiNote>),
      KanjiNote,
      PrefetchHooks Function()
    >;
typedef $$KanjiStaticTableCreateCompanionBuilder =
    KanjiStaticCompanion Function({
      required String character,
      Value<int?> jlptLevel,
      Value<int?> rtkIndex,
      Value<int?> levelRank,
      Value<int> rowid,
    });
typedef $$KanjiStaticTableUpdateCompanionBuilder =
    KanjiStaticCompanion Function({
      Value<String> character,
      Value<int?> jlptLevel,
      Value<int?> rtkIndex,
      Value<int?> levelRank,
      Value<int> rowid,
    });

class $$KanjiStaticTableFilterComposer
    extends Composer<_$AppDatabase, $KanjiStaticTable> {
  $$KanjiStaticTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jlptLevel => $composableBuilder(
    column: $table.jlptLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rtkIndex => $composableBuilder(
    column: $table.rtkIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get levelRank => $composableBuilder(
    column: $table.levelRank,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KanjiStaticTableOrderingComposer
    extends Composer<_$AppDatabase, $KanjiStaticTable> {
  $$KanjiStaticTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jlptLevel => $composableBuilder(
    column: $table.jlptLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rtkIndex => $composableBuilder(
    column: $table.rtkIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get levelRank => $composableBuilder(
    column: $table.levelRank,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KanjiStaticTableAnnotationComposer
    extends Composer<_$AppDatabase, $KanjiStaticTable> {
  $$KanjiStaticTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumn<int> get jlptLevel =>
      $composableBuilder(column: $table.jlptLevel, builder: (column) => column);

  GeneratedColumn<int> get rtkIndex =>
      $composableBuilder(column: $table.rtkIndex, builder: (column) => column);

  GeneratedColumn<int> get levelRank =>
      $composableBuilder(column: $table.levelRank, builder: (column) => column);
}

class $$KanjiStaticTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KanjiStaticTable,
          KanjiStaticData,
          $$KanjiStaticTableFilterComposer,
          $$KanjiStaticTableOrderingComposer,
          $$KanjiStaticTableAnnotationComposer,
          $$KanjiStaticTableCreateCompanionBuilder,
          $$KanjiStaticTableUpdateCompanionBuilder,
          (
            KanjiStaticData,
            BaseReferences<_$AppDatabase, $KanjiStaticTable, KanjiStaticData>,
          ),
          KanjiStaticData,
          PrefetchHooks Function()
        > {
  $$KanjiStaticTableTableManager(_$AppDatabase db, $KanjiStaticTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KanjiStaticTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KanjiStaticTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KanjiStaticTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> character = const Value.absent(),
                Value<int?> jlptLevel = const Value.absent(),
                Value<int?> rtkIndex = const Value.absent(),
                Value<int?> levelRank = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KanjiStaticCompanion(
                character: character,
                jlptLevel: jlptLevel,
                rtkIndex: rtkIndex,
                levelRank: levelRank,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String character,
                Value<int?> jlptLevel = const Value.absent(),
                Value<int?> rtkIndex = const Value.absent(),
                Value<int?> levelRank = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KanjiStaticCompanion.insert(
                character: character,
                jlptLevel: jlptLevel,
                rtkIndex: rtkIndex,
                levelRank: levelRank,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KanjiStaticTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KanjiStaticTable,
      KanjiStaticData,
      $$KanjiStaticTableFilterComposer,
      $$KanjiStaticTableOrderingComposer,
      $$KanjiStaticTableAnnotationComposer,
      $$KanjiStaticTableCreateCompanionBuilder,
      $$KanjiStaticTableUpdateCompanionBuilder,
      (
        KanjiStaticData,
        BaseReferences<_$AppDatabase, $KanjiStaticTable, KanjiStaticData>,
      ),
      KanjiStaticData,
      PrefetchHooks Function()
    >;
typedef $$CompositaProgressTableCreateCompanionBuilder =
    CompositaProgressCompanion Function({
      required String character,
      required String word,
      required CompositaDirection direction,
      required DateTime firstPassedAt,
      Value<int> rowid,
    });
typedef $$CompositaProgressTableUpdateCompanionBuilder =
    CompositaProgressCompanion Function({
      Value<String> character,
      Value<String> word,
      Value<CompositaDirection> direction,
      Value<DateTime> firstPassedAt,
      Value<int> rowid,
    });

class $$CompositaProgressTableFilterComposer
    extends Composer<_$AppDatabase, $CompositaProgressTable> {
  $$CompositaProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CompositaDirection, CompositaDirection, int>
  get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get firstPassedAt => $composableBuilder(
    column: $table.firstPassedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompositaProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $CompositaProgressTable> {
  $$CompositaProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstPassedAt => $composableBuilder(
    column: $table.firstPassedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompositaProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompositaProgressTable> {
  $$CompositaProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CompositaDirection, int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<DateTime> get firstPassedAt => $composableBuilder(
    column: $table.firstPassedAt,
    builder: (column) => column,
  );
}

class $$CompositaProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompositaProgressTable,
          CompositaProgressData,
          $$CompositaProgressTableFilterComposer,
          $$CompositaProgressTableOrderingComposer,
          $$CompositaProgressTableAnnotationComposer,
          $$CompositaProgressTableCreateCompanionBuilder,
          $$CompositaProgressTableUpdateCompanionBuilder,
          (
            CompositaProgressData,
            BaseReferences<
              _$AppDatabase,
              $CompositaProgressTable,
              CompositaProgressData
            >,
          ),
          CompositaProgressData,
          PrefetchHooks Function()
        > {
  $$CompositaProgressTableTableManager(
    _$AppDatabase db,
    $CompositaProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompositaProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompositaProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompositaProgressTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> character = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<CompositaDirection> direction = const Value.absent(),
                Value<DateTime> firstPassedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompositaProgressCompanion(
                character: character,
                word: word,
                direction: direction,
                firstPassedAt: firstPassedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String character,
                required String word,
                required CompositaDirection direction,
                required DateTime firstPassedAt,
                Value<int> rowid = const Value.absent(),
              }) => CompositaProgressCompanion.insert(
                character: character,
                word: word,
                direction: direction,
                firstPassedAt: firstPassedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompositaProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompositaProgressTable,
      CompositaProgressData,
      $$CompositaProgressTableFilterComposer,
      $$CompositaProgressTableOrderingComposer,
      $$CompositaProgressTableAnnotationComposer,
      $$CompositaProgressTableCreateCompanionBuilder,
      $$CompositaProgressTableUpdateCompanionBuilder,
      (
        CompositaProgressData,
        BaseReferences<
          _$AppDatabase,
          $CompositaProgressTable,
          CompositaProgressData
        >,
      ),
      CompositaProgressData,
      PrefetchHooks Function()
    >;
typedef $$CustomCompositaTableCreateCompanionBuilder =
    CustomCompositaCompanion Function({
      required String character,
      required String word,
      Value<int> rowid,
    });
typedef $$CustomCompositaTableUpdateCompanionBuilder =
    CustomCompositaCompanion Function({
      Value<String> character,
      Value<String> word,
      Value<int> rowid,
    });

class $$CustomCompositaTableFilterComposer
    extends Composer<_$AppDatabase, $CustomCompositaTable> {
  $$CustomCompositaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomCompositaTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomCompositaTable> {
  $$CustomCompositaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomCompositaTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomCompositaTable> {
  $$CustomCompositaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);
}

class $$CustomCompositaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomCompositaTable,
          CustomCompositaData,
          $$CustomCompositaTableFilterComposer,
          $$CustomCompositaTableOrderingComposer,
          $$CustomCompositaTableAnnotationComposer,
          $$CustomCompositaTableCreateCompanionBuilder,
          $$CustomCompositaTableUpdateCompanionBuilder,
          (
            CustomCompositaData,
            BaseReferences<
              _$AppDatabase,
              $CustomCompositaTable,
              CustomCompositaData
            >,
          ),
          CustomCompositaData,
          PrefetchHooks Function()
        > {
  $$CustomCompositaTableTableManager(
    _$AppDatabase db,
    $CustomCompositaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomCompositaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomCompositaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomCompositaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> character = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomCompositaCompanion(
                character: character,
                word: word,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String character,
                required String word,
                Value<int> rowid = const Value.absent(),
              }) => CustomCompositaCompanion.insert(
                character: character,
                word: word,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomCompositaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomCompositaTable,
      CustomCompositaData,
      $$CustomCompositaTableFilterComposer,
      $$CustomCompositaTableOrderingComposer,
      $$CustomCompositaTableAnnotationComposer,
      $$CustomCompositaTableCreateCompanionBuilder,
      $$CustomCompositaTableUpdateCompanionBuilder,
      (
        CustomCompositaData,
        BaseReferences<
          _$AppDatabase,
          $CustomCompositaTable,
          CustomCompositaData
        >,
      ),
      CustomCompositaData,
      PrefetchHooks Function()
    >;
typedef $$UserCompositaTableCreateCompanionBuilder =
    UserCompositaCompanion Function({
      required String character,
      required String word,
      required String reading,
      required String meaning,
      Value<int> rowid,
    });
typedef $$UserCompositaTableUpdateCompanionBuilder =
    UserCompositaCompanion Function({
      Value<String> character,
      Value<String> word,
      Value<String> reading,
      Value<String> meaning,
      Value<int> rowid,
    });

class $$UserCompositaTableFilterComposer
    extends Composer<_$AppDatabase, $UserCompositaTable> {
  $$UserCompositaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserCompositaTableOrderingComposer
    extends Composer<_$AppDatabase, $UserCompositaTable> {
  $$UserCompositaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserCompositaTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserCompositaTable> {
  $$UserCompositaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);
}

class $$UserCompositaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserCompositaTable,
          UserCompositaData,
          $$UserCompositaTableFilterComposer,
          $$UserCompositaTableOrderingComposer,
          $$UserCompositaTableAnnotationComposer,
          $$UserCompositaTableCreateCompanionBuilder,
          $$UserCompositaTableUpdateCompanionBuilder,
          (
            UserCompositaData,
            BaseReferences<
              _$AppDatabase,
              $UserCompositaTable,
              UserCompositaData
            >,
          ),
          UserCompositaData,
          PrefetchHooks Function()
        > {
  $$UserCompositaTableTableManager(_$AppDatabase db, $UserCompositaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserCompositaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserCompositaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserCompositaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> character = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserCompositaCompanion(
                character: character,
                word: word,
                reading: reading,
                meaning: meaning,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String character,
                required String word,
                required String reading,
                required String meaning,
                Value<int> rowid = const Value.absent(),
              }) => UserCompositaCompanion.insert(
                character: character,
                word: word,
                reading: reading,
                meaning: meaning,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserCompositaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserCompositaTable,
      UserCompositaData,
      $$UserCompositaTableFilterComposer,
      $$UserCompositaTableOrderingComposer,
      $$UserCompositaTableAnnotationComposer,
      $$UserCompositaTableCreateCompanionBuilder,
      $$UserCompositaTableUpdateCompanionBuilder,
      (
        UserCompositaData,
        BaseReferences<_$AppDatabase, $UserCompositaTable, UserCompositaData>,
      ),
      UserCompositaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReviewCardsTableTableManager get reviewCards =>
      $$ReviewCardsTableTableManager(_db, _db.reviewCards);
  $$ReviewLogTableTableManager get reviewLog =>
      $$ReviewLogTableTableManager(_db, _db.reviewLog);
  $$KanjiNotesTableTableManager get kanjiNotes =>
      $$KanjiNotesTableTableManager(_db, _db.kanjiNotes);
  $$KanjiStaticTableTableManager get kanjiStatic =>
      $$KanjiStaticTableTableManager(_db, _db.kanjiStatic);
  $$CompositaProgressTableTableManager get compositaProgress =>
      $$CompositaProgressTableTableManager(_db, _db.compositaProgress);
  $$CustomCompositaTableTableManager get customComposita =>
      $$CustomCompositaTableTableManager(_db, _db.customComposita);
  $$UserCompositaTableTableManager get userComposita =>
      $$UserCompositaTableTableManager(_db, _db.userComposita);
}
