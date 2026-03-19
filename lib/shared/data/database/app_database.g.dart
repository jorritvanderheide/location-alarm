// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AlarmsTable extends Alarms with TableInfo<$AlarmsTable, Alarm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AlarmMode, int> mode =
      GeneratedColumn<int>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<AlarmMode>($AlarmsTable.$convertermode);
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _radiusMeta = const VerificationMeta('radius');
  @override
  late final GeneratedColumn<double> radius = GeneratedColumn<double>(
    'radius',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TravelMode?, int> travelMode =
      GeneratedColumn<int>(
        'travel_mode',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<TravelMode?>($AlarmsTable.$convertertravelModen);
  static const VerificationMeta _bufferMinutesMeta = const VerificationMeta(
    'bufferMinutes',
  );
  @override
  late final GeneratedColumn<int> bufferMinutes = GeneratedColumn<int>(
    'buffer_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    mode,
    latitude,
    longitude,
    active,
    radius,
    travelMode,
    bufferMinutes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Alarm> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('radius')) {
      context.handle(
        _radiusMeta,
        radius.isAcceptableOrUnknown(data['radius']!, _radiusMeta),
      );
    }
    if (data.containsKey('buffer_minutes')) {
      context.handle(
        _bufferMinutesMeta,
        bufferMinutes.isAcceptableOrUnknown(
          data['buffer_minutes']!,
          _bufferMinutesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alarm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alarm(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mode: $AlarmsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}mode'],
        )!,
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      radius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius'],
      ),
      travelMode: $AlarmsTable.$convertertravelModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}travel_mode'],
        ),
      ),
      bufferMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}buffer_minutes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AlarmsTable createAlias(String alias) {
    return $AlarmsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AlarmMode, int, int> $convertermode =
      const EnumIndexConverter<AlarmMode>(AlarmMode.values);
  static JsonTypeConverter2<TravelMode, int, int> $convertertravelMode =
      const EnumIndexConverter<TravelMode>(TravelMode.values);
  static JsonTypeConverter2<TravelMode?, int?, int?> $convertertravelModen =
      JsonTypeConverter2.asNullable($convertertravelMode);
}

class Alarm extends DataClass implements Insertable<Alarm> {
  final int id;
  final String name;
  final AlarmMode mode;
  final double latitude;
  final double longitude;
  final bool active;
  final double? radius;
  final TravelMode? travelMode;
  final int? bufferMinutes;
  final DateTime createdAt;
  const Alarm({
    required this.id,
    required this.name,
    required this.mode,
    required this.latitude,
    required this.longitude,
    required this.active,
    this.radius,
    this.travelMode,
    this.bufferMinutes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['mode'] = Variable<int>($AlarmsTable.$convertermode.toSql(mode));
    }
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || radius != null) {
      map['radius'] = Variable<double>(radius);
    }
    if (!nullToAbsent || travelMode != null) {
      map['travel_mode'] = Variable<int>(
        $AlarmsTable.$convertertravelModen.toSql(travelMode),
      );
    }
    if (!nullToAbsent || bufferMinutes != null) {
      map['buffer_minutes'] = Variable<int>(bufferMinutes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AlarmsCompanion toCompanion(bool nullToAbsent) {
    return AlarmsCompanion(
      id: Value(id),
      name: Value(name),
      mode: Value(mode),
      latitude: Value(latitude),
      longitude: Value(longitude),
      active: Value(active),
      radius: radius == null && nullToAbsent
          ? const Value.absent()
          : Value(radius),
      travelMode: travelMode == null && nullToAbsent
          ? const Value.absent()
          : Value(travelMode),
      bufferMinutes: bufferMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(bufferMinutes),
      createdAt: Value(createdAt),
    );
  }

  factory Alarm.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alarm(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      mode: $AlarmsTable.$convertermode.fromJson(
        serializer.fromJson<int>(json['mode']),
      ),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      active: serializer.fromJson<bool>(json['active']),
      radius: serializer.fromJson<double?>(json['radius']),
      travelMode: $AlarmsTable.$convertertravelModen.fromJson(
        serializer.fromJson<int?>(json['travelMode']),
      ),
      bufferMinutes: serializer.fromJson<int?>(json['bufferMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'mode': serializer.toJson<int>($AlarmsTable.$convertermode.toJson(mode)),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'active': serializer.toJson<bool>(active),
      'radius': serializer.toJson<double?>(radius),
      'travelMode': serializer.toJson<int?>(
        $AlarmsTable.$convertertravelModen.toJson(travelMode),
      ),
      'bufferMinutes': serializer.toJson<int?>(bufferMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Alarm copyWith({
    int? id,
    String? name,
    AlarmMode? mode,
    double? latitude,
    double? longitude,
    bool? active,
    Value<double?> radius = const Value.absent(),
    Value<TravelMode?> travelMode = const Value.absent(),
    Value<int?> bufferMinutes = const Value.absent(),
    DateTime? createdAt,
  }) => Alarm(
    id: id ?? this.id,
    name: name ?? this.name,
    mode: mode ?? this.mode,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    active: active ?? this.active,
    radius: radius.present ? radius.value : this.radius,
    travelMode: travelMode.present ? travelMode.value : this.travelMode,
    bufferMinutes: bufferMinutes.present
        ? bufferMinutes.value
        : this.bufferMinutes,
    createdAt: createdAt ?? this.createdAt,
  );
  Alarm copyWithCompanion(AlarmsCompanion data) {
    return Alarm(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      mode: data.mode.present ? data.mode.value : this.mode,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      active: data.active.present ? data.active.value : this.active,
      radius: data.radius.present ? data.radius.value : this.radius,
      travelMode: data.travelMode.present
          ? data.travelMode.value
          : this.travelMode,
      bufferMinutes: data.bufferMinutes.present
          ? data.bufferMinutes.value
          : this.bufferMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alarm(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mode: $mode, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('active: $active, ')
          ..write('radius: $radius, ')
          ..write('travelMode: $travelMode, ')
          ..write('bufferMinutes: $bufferMinutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    mode,
    latitude,
    longitude,
    active,
    radius,
    travelMode,
    bufferMinutes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alarm &&
          other.id == this.id &&
          other.name == this.name &&
          other.mode == this.mode &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.active == this.active &&
          other.radius == this.radius &&
          other.travelMode == this.travelMode &&
          other.bufferMinutes == this.bufferMinutes &&
          other.createdAt == this.createdAt);
}

class AlarmsCompanion extends UpdateCompanion<Alarm> {
  final Value<int> id;
  final Value<String> name;
  final Value<AlarmMode> mode;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<bool> active;
  final Value<double?> radius;
  final Value<TravelMode?> travelMode;
  final Value<int?> bufferMinutes;
  final Value<DateTime> createdAt;
  const AlarmsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.mode = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.active = const Value.absent(),
    this.radius = const Value.absent(),
    this.travelMode = const Value.absent(),
    this.bufferMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AlarmsCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    required AlarmMode mode,
    required double latitude,
    required double longitude,
    this.active = const Value.absent(),
    this.radius = const Value.absent(),
    this.travelMode = const Value.absent(),
    this.bufferMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : mode = Value(mode),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<Alarm> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? mode,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<bool>? active,
    Expression<double>? radius,
    Expression<int>? travelMode,
    Expression<int>? bufferMinutes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mode != null) 'mode': mode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (active != null) 'active': active,
      if (radius != null) 'radius': radius,
      if (travelMode != null) 'travel_mode': travelMode,
      if (bufferMinutes != null) 'buffer_minutes': bufferMinutes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AlarmsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<AlarmMode>? mode,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<bool>? active,
    Value<double?>? radius,
    Value<TravelMode?>? travelMode,
    Value<int?>? bufferMinutes,
    Value<DateTime>? createdAt,
  }) {
    return AlarmsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      active: active ?? this.active,
      radius: radius ?? this.radius,
      travelMode: travelMode ?? this.travelMode,
      bufferMinutes: bufferMinutes ?? this.bufferMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mode.present) {
      map['mode'] = Variable<int>(
        $AlarmsTable.$convertermode.toSql(mode.value),
      );
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (radius.present) {
      map['radius'] = Variable<double>(radius.value);
    }
    if (travelMode.present) {
      map['travel_mode'] = Variable<int>(
        $AlarmsTable.$convertertravelModen.toSql(travelMode.value),
      );
    }
    if (bufferMinutes.present) {
      map['buffer_minutes'] = Variable<int>(bufferMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mode: $mode, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('active: $active, ')
          ..write('radius: $radius, ')
          ..write('travelMode: $travelMode, ')
          ..write('bufferMinutes: $bufferMinutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AlarmsTable alarms = $AlarmsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [alarms];
}

typedef $$AlarmsTableCreateCompanionBuilder =
    AlarmsCompanion Function({
      Value<int> id,
      Value<String> name,
      required AlarmMode mode,
      required double latitude,
      required double longitude,
      Value<bool> active,
      Value<double?> radius,
      Value<TravelMode?> travelMode,
      Value<int?> bufferMinutes,
      Value<DateTime> createdAt,
    });
typedef $$AlarmsTableUpdateCompanionBuilder =
    AlarmsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<AlarmMode> mode,
      Value<double> latitude,
      Value<double> longitude,
      Value<bool> active,
      Value<double?> radius,
      Value<TravelMode?> travelMode,
      Value<int?> bufferMinutes,
      Value<DateTime> createdAt,
    });

class $$AlarmsTableFilterComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AlarmMode, AlarmMode, int> get mode =>
      $composableBuilder(
        column: $table.mode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radius => $composableBuilder(
    column: $table.radius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TravelMode?, TravelMode, int> get travelMode =>
      $composableBuilder(
        column: $table.travelMode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get bufferMinutes => $composableBuilder(
    column: $table.bufferMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlarmsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radius => $composableBuilder(
    column: $table.radius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get travelMode => $composableBuilder(
    column: $table.travelMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bufferMinutes => $composableBuilder(
    column: $table.bufferMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlarmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AlarmMode, int> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<double> get radius =>
      $composableBuilder(column: $table.radius, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TravelMode?, int> get travelMode =>
      $composableBuilder(
        column: $table.travelMode,
        builder: (column) => column,
      );

  GeneratedColumn<int> get bufferMinutes => $composableBuilder(
    column: $table.bufferMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AlarmsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlarmsTable,
          Alarm,
          $$AlarmsTableFilterComposer,
          $$AlarmsTableOrderingComposer,
          $$AlarmsTableAnnotationComposer,
          $$AlarmsTableCreateCompanionBuilder,
          $$AlarmsTableUpdateCompanionBuilder,
          (Alarm, BaseReferences<_$AppDatabase, $AlarmsTable, Alarm>),
          Alarm,
          PrefetchHooks Function()
        > {
  $$AlarmsTableTableManager(_$AppDatabase db, $AlarmsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AlarmMode> mode = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<double?> radius = const Value.absent(),
                Value<TravelMode?> travelMode = const Value.absent(),
                Value<int?> bufferMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AlarmsCompanion(
                id: id,
                name: name,
                mode: mode,
                latitude: latitude,
                longitude: longitude,
                active: active,
                radius: radius,
                travelMode: travelMode,
                bufferMinutes: bufferMinutes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                required AlarmMode mode,
                required double latitude,
                required double longitude,
                Value<bool> active = const Value.absent(),
                Value<double?> radius = const Value.absent(),
                Value<TravelMode?> travelMode = const Value.absent(),
                Value<int?> bufferMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AlarmsCompanion.insert(
                id: id,
                name: name,
                mode: mode,
                latitude: latitude,
                longitude: longitude,
                active: active,
                radius: radius,
                travelMode: travelMode,
                bufferMinutes: bufferMinutes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlarmsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlarmsTable,
      Alarm,
      $$AlarmsTableFilterComposer,
      $$AlarmsTableOrderingComposer,
      $$AlarmsTableAnnotationComposer,
      $$AlarmsTableCreateCompanionBuilder,
      $$AlarmsTableUpdateCompanionBuilder,
      (Alarm, BaseReferences<_$AppDatabase, $AlarmsTable, Alarm>),
      Alarm,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AlarmsTableTableManager get alarms =>
      $$AlarmsTableTableManager(_db, _db.alarms);
}
