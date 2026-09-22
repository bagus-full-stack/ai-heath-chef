// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalMealsTable extends LocalMeals
    with TableInfo<$LocalMealsTable, LocalMeal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalKcalMeta = const VerificationMeta(
    'totalKcal',
  );
  @override
  late final GeneratedColumn<int> totalKcal = GeneratedColumn<int>(
    'total_kcal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalProtMeta = const VerificationMeta(
    'totalProt',
  );
  @override
  late final GeneratedColumn<double> totalProt = GeneratedColumn<double>(
    'total_prot',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalGlucMeta = const VerificationMeta(
    'totalGluc',
  );
  @override
  late final GeneratedColumn<double> totalGluc = GeneratedColumn<double>(
    'total_gluc',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalLipMeta = const VerificationMeta(
    'totalLip',
  );
  @override
  late final GeneratedColumn<double> totalLip = GeneratedColumn<double>(
    'total_lip',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ingredientsJsonMeta = const VerificationMeta(
    'ingredientsJson',
  );
  @override
  late final GeneratedColumn<String> ingredientsJson = GeneratedColumn<String>(
    'ingredients_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localImagePathMeta = const VerificationMeta(
    'localImagePath',
  );
  @override
  late final GeneratedColumn<String> localImagePath = GeneratedColumn<String>(
    'local_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    totalKcal,
    totalProt,
    totalGluc,
    totalLip,
    ingredientsJson,
    imageUrl,
    localImagePath,
    createdAt,
    isSynced,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMeal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('total_kcal')) {
      context.handle(
        _totalKcalMeta,
        totalKcal.isAcceptableOrUnknown(data['total_kcal']!, _totalKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalKcalMeta);
    }
    if (data.containsKey('total_prot')) {
      context.handle(
        _totalProtMeta,
        totalProt.isAcceptableOrUnknown(data['total_prot']!, _totalProtMeta),
      );
    }
    if (data.containsKey('total_gluc')) {
      context.handle(
        _totalGlucMeta,
        totalGluc.isAcceptableOrUnknown(data['total_gluc']!, _totalGlucMeta),
      );
    }
    if (data.containsKey('total_lip')) {
      context.handle(
        _totalLipMeta,
        totalLip.isAcceptableOrUnknown(data['total_lip']!, _totalLipMeta),
      );
    }
    if (data.containsKey('ingredients_json')) {
      context.handle(
        _ingredientsJsonMeta,
        ingredientsJson.isAcceptableOrUnknown(
          data['ingredients_json']!,
          _ingredientsJsonMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('local_image_path')) {
      context.handle(
        _localImagePathMeta,
        localImagePath.isAcceptableOrUnknown(
          data['local_image_path']!,
          _localImagePathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMeal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMeal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      totalKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_kcal'],
      )!,
      totalProt: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_prot'],
      )!,
      totalGluc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_gluc'],
      )!,
      totalLip: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_lip'],
      )!,
      ingredientsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredients_json'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      localImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_image_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $LocalMealsTable createAlias(String alias) {
    return $LocalMealsTable(attachedDatabase, alias);
  }
}

class LocalMeal extends DataClass implements Insertable<LocalMeal> {
  final String id;
  final String userId;
  final String name;
  final int totalKcal;
  final double totalProt;
  final double totalGluc;
  final double totalLip;

  /// Snapshot des ingrédients, encodé en JSON (même contenu que la colonne
  /// jsonb `ingredients` côté Supabase).
  final String ingredientsJson;

  /// URL publique une fois la photo uploadée vers Supabase Storage. Null
  /// tant que l'upload n'a pas eu lieu (ou si le repas n'a pas de photo).
  final String? imageUrl;

  /// Chemin du fichier photo compressé sur le disque local, en attente
  /// d'upload. Distinct de [imageUrl] : permet d'afficher la photo
  /// immédiatement même hors ligne, avant toute synchronisation.
  final String? localImagePath;
  final DateTime createdAt;

  /// Faux tant que ce repas (création, ou suppression via [isDeleted]) n'a
  /// pas été répercuté sur Supabase — c'est ce flag qui pilotera la file de
  /// synchronisation à l'étape suivante.
  final bool isSynced;

  /// Suppression différée : on marque plutôt que d'effacer la ligne
  /// immédiatement, pour pouvoir répercuter la suppression sur Supabase une
  /// fois la connexion revenue.
  final bool isDeleted;
  const LocalMeal({
    required this.id,
    required this.userId,
    required this.name,
    required this.totalKcal,
    required this.totalProt,
    required this.totalGluc,
    required this.totalLip,
    required this.ingredientsJson,
    this.imageUrl,
    this.localImagePath,
    required this.createdAt,
    required this.isSynced,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['total_kcal'] = Variable<int>(totalKcal);
    map['total_prot'] = Variable<double>(totalProt);
    map['total_gluc'] = Variable<double>(totalGluc);
    map['total_lip'] = Variable<double>(totalLip);
    map['ingredients_json'] = Variable<String>(ingredientsJson);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || localImagePath != null) {
      map['local_image_path'] = Variable<String>(localImagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  LocalMealsCompanion toCompanion(bool nullToAbsent) {
    return LocalMealsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      totalKcal: Value(totalKcal),
      totalProt: Value(totalProt),
      totalGluc: Value(totalGluc),
      totalLip: Value(totalLip),
      ingredientsJson: Value(ingredientsJson),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      localImagePath: localImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localImagePath),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
    );
  }

  factory LocalMeal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMeal(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      totalKcal: serializer.fromJson<int>(json['totalKcal']),
      totalProt: serializer.fromJson<double>(json['totalProt']),
      totalGluc: serializer.fromJson<double>(json['totalGluc']),
      totalLip: serializer.fromJson<double>(json['totalLip']),
      ingredientsJson: serializer.fromJson<String>(json['ingredientsJson']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      localImagePath: serializer.fromJson<String?>(json['localImagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'totalKcal': serializer.toJson<int>(totalKcal),
      'totalProt': serializer.toJson<double>(totalProt),
      'totalGluc': serializer.toJson<double>(totalGluc),
      'totalLip': serializer.toJson<double>(totalLip),
      'ingredientsJson': serializer.toJson<String>(ingredientsJson),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'localImagePath': serializer.toJson<String?>(localImagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  LocalMeal copyWith({
    String? id,
    String? userId,
    String? name,
    int? totalKcal,
    double? totalProt,
    double? totalGluc,
    double? totalLip,
    String? ingredientsJson,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> localImagePath = const Value.absent(),
    DateTime? createdAt,
    bool? isSynced,
    bool? isDeleted,
  }) => LocalMeal(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    totalKcal: totalKcal ?? this.totalKcal,
    totalProt: totalProt ?? this.totalProt,
    totalGluc: totalGluc ?? this.totalGluc,
    totalLip: totalLip ?? this.totalLip,
    ingredientsJson: ingredientsJson ?? this.ingredientsJson,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    localImagePath: localImagePath.present
        ? localImagePath.value
        : this.localImagePath,
    createdAt: createdAt ?? this.createdAt,
    isSynced: isSynced ?? this.isSynced,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  LocalMeal copyWithCompanion(LocalMealsCompanion data) {
    return LocalMeal(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      totalKcal: data.totalKcal.present ? data.totalKcal.value : this.totalKcal,
      totalProt: data.totalProt.present ? data.totalProt.value : this.totalProt,
      totalGluc: data.totalGluc.present ? data.totalGluc.value : this.totalGluc,
      totalLip: data.totalLip.present ? data.totalLip.value : this.totalLip,
      ingredientsJson: data.ingredientsJson.present
          ? data.ingredientsJson.value
          : this.ingredientsJson,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      localImagePath: data.localImagePath.present
          ? data.localImagePath.value
          : this.localImagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMeal(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('totalKcal: $totalKcal, ')
          ..write('totalProt: $totalProt, ')
          ..write('totalGluc: $totalGluc, ')
          ..write('totalLip: $totalLip, ')
          ..write('ingredientsJson: $ingredientsJson, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    totalKcal,
    totalProt,
    totalGluc,
    totalLip,
    ingredientsJson,
    imageUrl,
    localImagePath,
    createdAt,
    isSynced,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMeal &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.totalKcal == this.totalKcal &&
          other.totalProt == this.totalProt &&
          other.totalGluc == this.totalGluc &&
          other.totalLip == this.totalLip &&
          other.ingredientsJson == this.ingredientsJson &&
          other.imageUrl == this.imageUrl &&
          other.localImagePath == this.localImagePath &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted);
}

class LocalMealsCompanion extends UpdateCompanion<LocalMeal> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<int> totalKcal;
  final Value<double> totalProt;
  final Value<double> totalGluc;
  final Value<double> totalLip;
  final Value<String> ingredientsJson;
  final Value<String?> imageUrl;
  final Value<String?> localImagePath;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const LocalMealsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.totalKcal = const Value.absent(),
    this.totalProt = const Value.absent(),
    this.totalGluc = const Value.absent(),
    this.totalLip = const Value.absent(),
    this.ingredientsJson = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMealsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required int totalKcal,
    this.totalProt = const Value.absent(),
    this.totalGluc = const Value.absent(),
    this.totalLip = const Value.absent(),
    this.ingredientsJson = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.localImagePath = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       totalKcal = Value(totalKcal),
       createdAt = Value(createdAt);
  static Insertable<LocalMeal> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<int>? totalKcal,
    Expression<double>? totalProt,
    Expression<double>? totalGluc,
    Expression<double>? totalLip,
    Expression<String>? ingredientsJson,
    Expression<String>? imageUrl,
    Expression<String>? localImagePath,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (totalKcal != null) 'total_kcal': totalKcal,
      if (totalProt != null) 'total_prot': totalProt,
      if (totalGluc != null) 'total_gluc': totalGluc,
      if (totalLip != null) 'total_lip': totalLip,
      if (ingredientsJson != null) 'ingredients_json': ingredientsJson,
      if (imageUrl != null) 'image_url': imageUrl,
      if (localImagePath != null) 'local_image_path': localImagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMealsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<int>? totalKcal,
    Value<double>? totalProt,
    Value<double>? totalGluc,
    Value<double>? totalLip,
    Value<String>? ingredientsJson,
    Value<String?>? imageUrl,
    Value<String?>? localImagePath,
    Value<DateTime>? createdAt,
    Value<bool>? isSynced,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return LocalMealsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      totalKcal: totalKcal ?? this.totalKcal,
      totalProt: totalProt ?? this.totalProt,
      totalGluc: totalGluc ?? this.totalGluc,
      totalLip: totalLip ?? this.totalLip,
      ingredientsJson: ingredientsJson ?? this.ingredientsJson,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (totalKcal.present) {
      map['total_kcal'] = Variable<int>(totalKcal.value);
    }
    if (totalProt.present) {
      map['total_prot'] = Variable<double>(totalProt.value);
    }
    if (totalGluc.present) {
      map['total_gluc'] = Variable<double>(totalGluc.value);
    }
    if (totalLip.present) {
      map['total_lip'] = Variable<double>(totalLip.value);
    }
    if (ingredientsJson.present) {
      map['ingredients_json'] = Variable<String>(ingredientsJson.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (localImagePath.present) {
      map['local_image_path'] = Variable<String>(localImagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMealsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('totalKcal: $totalKcal, ')
          ..write('totalProt: $totalProt, ')
          ..write('totalGluc: $totalGluc, ')
          ..write('totalLip: $totalLip, ')
          ..write('ingredientsJson: $ingredientsJson, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalMealsTable localMeals = $LocalMealsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [localMeals];
}

typedef $$LocalMealsTableCreateCompanionBuilder =
    LocalMealsCompanion Function({
      required String id,
      required String userId,
      required String name,
      required int totalKcal,
      Value<double> totalProt,
      Value<double> totalGluc,
      Value<double> totalLip,
      Value<String> ingredientsJson,
      Value<String?> imageUrl,
      Value<String?> localImagePath,
      required DateTime createdAt,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$LocalMealsTableUpdateCompanionBuilder =
    LocalMealsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<int> totalKcal,
      Value<double> totalProt,
      Value<double> totalGluc,
      Value<double> totalLip,
      Value<String> ingredientsJson,
      Value<String?> imageUrl,
      Value<String?> localImagePath,
      Value<DateTime> createdAt,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$LocalMealsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMealsTable> {
  $$LocalMealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalKcal => $composableBuilder(
    column: $table.totalKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalProt => $composableBuilder(
    column: $table.totalProt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalGluc => $composableBuilder(
    column: $table.totalGluc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalLip => $composableBuilder(
    column: $table.totalLip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientsJson => $composableBuilder(
    column: $table.ingredientsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMealsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMealsTable> {
  $$LocalMealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalKcal => $composableBuilder(
    column: $table.totalKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalProt => $composableBuilder(
    column: $table.totalProt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalGluc => $composableBuilder(
    column: $table.totalGluc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalLip => $composableBuilder(
    column: $table.totalLip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientsJson => $composableBuilder(
    column: $table.ingredientsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMealsTable> {
  $$LocalMealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get totalKcal =>
      $composableBuilder(column: $table.totalKcal, builder: (column) => column);

  GeneratedColumn<double> get totalProt =>
      $composableBuilder(column: $table.totalProt, builder: (column) => column);

  GeneratedColumn<double> get totalGluc =>
      $composableBuilder(column: $table.totalGluc, builder: (column) => column);

  GeneratedColumn<double> get totalLip =>
      $composableBuilder(column: $table.totalLip, builder: (column) => column);

  GeneratedColumn<String> get ingredientsJson => $composableBuilder(
    column: $table.ingredientsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$LocalMealsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMealsTable,
          LocalMeal,
          $$LocalMealsTableFilterComposer,
          $$LocalMealsTableOrderingComposer,
          $$LocalMealsTableAnnotationComposer,
          $$LocalMealsTableCreateCompanionBuilder,
          $$LocalMealsTableUpdateCompanionBuilder,
          (
            LocalMeal,
            BaseReferences<_$AppDatabase, $LocalMealsTable, LocalMeal>,
          ),
          LocalMeal,
          PrefetchHooks Function()
        > {
  $$LocalMealsTableTableManager(_$AppDatabase db, $LocalMealsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> totalKcal = const Value.absent(),
                Value<double> totalProt = const Value.absent(),
                Value<double> totalGluc = const Value.absent(),
                Value<double> totalLip = const Value.absent(),
                Value<String> ingredientsJson = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> localImagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMealsCompanion(
                id: id,
                userId: userId,
                name: name,
                totalKcal: totalKcal,
                totalProt: totalProt,
                totalGluc: totalGluc,
                totalLip: totalLip,
                ingredientsJson: ingredientsJson,
                imageUrl: imageUrl,
                localImagePath: localImagePath,
                createdAt: createdAt,
                isSynced: isSynced,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                required int totalKcal,
                Value<double> totalProt = const Value.absent(),
                Value<double> totalGluc = const Value.absent(),
                Value<double> totalLip = const Value.absent(),
                Value<String> ingredientsJson = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> localImagePath = const Value.absent(),
                required DateTime createdAt,
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMealsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                totalKcal: totalKcal,
                totalProt: totalProt,
                totalGluc: totalGluc,
                totalLip: totalLip,
                ingredientsJson: ingredientsJson,
                imageUrl: imageUrl,
                localImagePath: localImagePath,
                createdAt: createdAt,
                isSynced: isSynced,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalMealsTable, LocalMeal>(table),
                  BaseReferences<_$AppDatabase, $LocalMealsTable, LocalMeal>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMealsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMealsTable,
      LocalMeal,
      $$LocalMealsTableFilterComposer,
      $$LocalMealsTableOrderingComposer,
      $$LocalMealsTableAnnotationComposer,
      $$LocalMealsTableCreateCompanionBuilder,
      $$LocalMealsTableUpdateCompanionBuilder,
      (LocalMeal, BaseReferences<_$AppDatabase, $LocalMealsTable, LocalMeal>),
      LocalMeal,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalMealsTableTableManager get localMeals =>
      $$LocalMealsTableTableManager(_db, _db.localMeals);
}
