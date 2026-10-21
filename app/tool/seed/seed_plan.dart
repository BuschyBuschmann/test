// Seed-Plan: liest testdaten.json, prueft sie und erzeugt daraus die geordnete Schrittfolge,
// die ein Backend ausfuehrt (Plan Ausschnitt 2, Abschnitt 10, Paket F2-2).
//
// Eine Quelle, zwei Ausfuehrungswege: derselbe Plan laeuft ueber die Supabase-API
// (supabase_backend.dart) oder wird als SQL fuer das lokale Postgres mit Nachbildung
// ausgegeben (sql_backend.dart). Keine Schemaaenderung: es werden nur vorhandene Tabellen
// und Funktionen genutzt (Migrationen 01-07). Kein Zugriff auf Netzwerk, Umgebung oder Dateien.

import 'stable_ids.dart';

/// Feste Domain der Test-Konten. Der Reset loescht Konten nur mit genau dieser Endung
/// ("@test.curaone.invalid", Vergleich in Kleinbuchstaben). Nie aus Daten uebernehmen.
const String kTestEmailDomain = 'test.curaone.invalid';

/// Fehler in den Testdaten (Struktur, Verweise, Werte).
class SeedDataException implements Exception {
  SeedDataException(this.message);
  final String message;
  @override
  String toString() => 'Testdaten ungueltig: $message';
}

/// Verweis auf ein Physio-Konto. Die echte ID kennt erst das Backend (GoTrue vergibt sie).
class PhysioRef {
  const PhysioRef(this.key);
  final String key;
  @override
  String toString() => 'PhysioRef($key)';
}

typedef Row = Map<String, Object?>;

sealed class SeedStep {
  const SeedStep();
  String get label;
}

/// Zeilen per Upsert (service_role). Alle Zeilen eines Schritts haben dieselben Schluessel.
class UpsertRows extends SeedStep {
  UpsertRows(this.table, this.rows) {
    if (rows.isEmpty) throw SeedDataException('Upsert ohne Zeilen: $table');
    final keys = rows.first.keys.toSet();
    for (final r in rows) {
      if (r.keys.toSet().difference(keys).isNotEmpty ||
          keys.difference(r.keys.toSet()).isNotEmpty) {
        throw SeedDataException(
          'Zeilen von $table haben unterschiedliche Spalten',
        );
      }
    }
  }
  final String table;
  final List<Row> rows;
  String get conflict => 'id';
  @override
  String get label => '$table (${rows.length})';
}

/// Spalten einer oder mehrerer Zeilen setzen (service_role).
class UpdateRows extends SeedStep {
  const UpdateRows(this.table, this.values, this.where);
  final String table;
  final Row values;
  final Row where;
  @override
  String get label => 'update $table';
}

/// Test-Physio: Auth-Konto (E-Mail + Passwort) und Zeile in public.physios.
class CreatePhysioAccount extends SeedStep {
  const CreatePhysioAccount({
    required this.key,
    required this.email,
    required this.displayName,
    required this.practiceId,
  });
  final String key;
  final String email;
  final String displayName;
  final String practiceId;
  @override
  String get label => 'physio $email';
}

/// Funktionsaufruf mit der Sitzung eines Test-Physios (hier: regenerate_invitation).
class PhysioRpc extends SeedStep {
  const PhysioRpc({
    required this.physioKey,
    required this.fn,
    required this.params,
    required this.subject,
  });
  final String physioKey;
  final String fn;
  final Row params;
  final String subject;
  @override
  String get label => '$fn($subject)';
}

/// Erzeugte Einladung (nur Konsole).
class InvitationInfo {
  const InvitationInfo(this.subject, this.code, this.expiresAt);
  final String subject;
  final String code;
  final String expiresAt;
}

class SeedPlan {
  SeedPlan({
    required this.steps,
    required this.emailDomain,
    required this.today,
    required this.notes,
  });
  final List<SeedStep> steps;
  final String emailDomain;
  final DateTime today;
  final List<String> notes;

  /// Zeilenzahl je Tabelle (nur Upserts).
  Map<String, int> get rowCounts {
    final m = <String, int>{};
    for (final s in steps) {
      if (s is UpsertRows) m[s.table] = (m[s.table] ?? 0) + s.rows.length;
    }
    return m;
  }

  List<CreatePhysioAccount> get physios =>
      steps.whereType<CreatePhysioAccount>().toList();
}

String dayString(DateTime today, int offset) {
  final d = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).add(Duration(days: offset));
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

String _timestamp(DateTime today, int offset, String hhmm) {
  final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(hhmm);
  if (m == null) {
    throw SeedDataException('Uhrzeit "$hhmm" nicht im Format HH:MM');
  }
  final d = DateTime.utc(
    today.year,
    today.month,
    today.day,
    int.parse(m[1]!),
    int.parse(m[2]!),
  ).add(Duration(days: offset));
  return d.toIso8601String();
}

// ---------------------------------------------------------------------------
// Zugriffshilfen mit klaren Fehlermeldungen
// ---------------------------------------------------------------------------

Map<String, dynamic> _obj(Object? v, String where) {
  if (v is Map<String, dynamic>) return v;
  throw SeedDataException('$where: Objekt erwartet');
}

List<dynamic> _list(Object? v, String where) {
  if (v is List<dynamic>) return v;
  throw SeedDataException('$where: Liste erwartet');
}

String _str(Map<String, dynamic> m, String k, String where) {
  final v = m[k];
  if (v is String && v.trim().isNotEmpty) return v;
  throw SeedDataException('$where: "$k" fehlt oder ist leer');
}

String? _strOpt(Map<String, dynamic> m, String k) {
  final v = m[k];
  return v is String && v.trim().isNotEmpty ? v : null;
}

int _int(Map<String, dynamic> m, String k, String where) {
  final v = m[k];
  if (v is int) return v;
  throw SeedDataException('$where: "$k" fehlt oder ist keine ganze Zahl');
}

int? _intOpt(Map<String, dynamic> m, String k, String where) {
  final v = m[k];
  if (v == null) return null;
  if (v is int) return v;
  throw SeedDataException('$where: "$k" ist keine ganze Zahl');
}

num? _numOpt(Map<String, dynamic> m, String k, String where) {
  final v = m[k];
  if (v == null) return null;
  if (v is num) return v;
  throw SeedDataException('$where: "$k" ist keine Zahl');
}

final RegExp _keyPattern = RegExp(r'^[a-z][a-z0-9_]*$');

void _checkKey(String key, String where) {
  if (!_keyPattern.hasMatch(key)) {
    throw SeedDataException(
      '$where: Schluessel "$key" ungueltig (a-z, 0-9, _)',
    );
  }
}

void _unique(Set<String> seen, String key, String where) {
  if (!seen.add(key)) {
    throw SeedDataException('$where: Schluessel "$key" doppelt');
  }
}

// ---------------------------------------------------------------------------
// Aufbau
// ---------------------------------------------------------------------------

/// Baut den Seed-Plan. [today] ist der UTC-Kalendertag, auf den sich alle Tagesoffsets beziehen.
SeedPlan buildSeedPlan(Map<String, dynamic> data, {required DateTime today}) {
  final todayUtc = DateTime.utc(today.year, today.month, today.day);
  final meta = _obj(data['meta'], 'meta');
  final domain = _str(meta, 'email_domain', 'meta');
  if (domain != kTestEmailDomain) {
    throw SeedDataException(
      'meta.email_domain muss "$kTestEmailDomain" sein (feste Konstante, '
      'sie begrenzt den Reset), nicht "$domain"',
    );
  }
  final notes = [
    for (final n in _list(
      meta['noch_nicht_umsetzbar'] ?? <dynamic>[],
      'meta.noch_nicht_umsetzbar',
    ))
      '$n',
  ];

  final practices = <Row>[];
  final physioSteps = <CreatePhysioAccount>[];
  final exercises = <Row>[];
  final templates = <Row>[];
  final patients = <Row>[];
  final injuries = <Row>[];
  final plans = <Row>[];
  final phases = <Row>[];
  final items = <Row>[];
  final variantUpdates = <UpdateRows>[];
  final currentPhaseUpdates = <UpdateRows>[];
  final treaters = <Row>[];
  final history = <Row>[];
  final appointments = <Row>[];
  final sessions = <Row>[];
  final results = <Row>[];
  final invitations = <PhysioRpc>[];

  // --- Katalog -------------------------------------------------------------
  final catalogKeys = <String>{};
  final exerciseOwner =
      <String, String?>{}; // key -> Praxis-Schluessel (null = Katalog)
  final exerciseNames = <String, String>{};
  final exerciseDefaults = <String, Row>{};

  Row exerciseRow(
    Map<String, dynamic> e,
    String where, {
    required String? practiceKey,
  }) {
    final key = _str(e, 'key', where);
    _checkKey(key, where);
    final name = _str(e, 'name', where);
    final kurz = _str(e, 'kurz', where);
    final loc = [for (final l in _list(e['orte'], '$where.orte')) '$l'];
    const allowedLoc = {'home', 'practice', 'gym'};
    if (loc.any((l) => !allowedLoc.contains(l))) {
      throw SeedDataException('$where: Ort ausserhalb home/practice/gym');
    }
    final material = [
      for (final m in _list(e['material'], '$where.material')) '$m',
    ];
    exerciseNames[key] = name;
    final row = <String, Object?>{
      'id': stableId('exercise:$key'),
      'practice_id': practiceKey == null
          ? null
          : stableId('practice:$practiceKey'),
      'name': name,
      'description': practiceKey == null
          ? 'Beispielübung (Testdaten). $kurz'
          : 'Praxiseigene Übung (Testdaten). $kurz',
      'is_example': practiceKey == null,
      'created_by_role': 'seed',
      'default_sets': _intOpt(e, 'sets', where),
      'default_reps': _intOpt(e, 'reps', where),
      'default_duration_sec': _intOpt(e, 'duration', where),
      'default_weight_kg': _numOpt(e, 'weight', where),
      'pause_sec': _intOpt(e, 'pause', where),
      'materials': material,
      'locations': loc,
      'short_instruction': kurz,
    };
    exerciseDefaults[key] = row;
    return row;
  }

  for (final e in _list(data['katalog'], 'katalog')) {
    final m = _obj(e, 'katalog[]');
    final row = exerciseRow(m, 'katalog[${m['key']}]', practiceKey: null);
    final key = m['key'] as String;
    _unique(catalogKeys, key, 'katalog');
    exerciseOwner[key] = null;
    exercises.add(row);
  }

  // --- Vorlagen ------------------------------------------------------------
  final templateKeys = <String>{};
  for (final t in _list(data['vorlagen'], 'vorlagen')) {
    final m = _obj(t, 'vorlagen[]');
    final key = _str(m, 'key', 'vorlagen[]');
    final where = 'vorlage[$key]';
    _checkKey(key, where);
    _unique(templateKeys, key, 'vorlagen');
    final phasesJson = _list(m['phasen'], '$where.phasen');
    final payloadPhases = <Map<String, Object?>>[];
    for (var pi = 0; pi < phasesJson.length; pi++) {
      final p = _obj(phasesJson[pi], '$where.phasen[$pi]');
      final pos = _list(p['positionen'], '$where.phasen[$pi].positionen');
      final payloadItems = <Map<String, Object?>>[];
      for (var ii = 0; ii < pos.length; ii++) {
        final it = _obj(pos[ii], '$where.phasen[$pi].positionen[$ii]');
        final ex = _str(it, 'uebung', where);
        if (!catalogKeys.contains(ex)) {
          throw SeedDataException('$where: Uebung "$ex" nicht im Katalog');
        }
        final rwp = _intOpt(it, 'freigabe_mit_phase', where);
        if (rwp != null && (rwp < 0 || rwp >= phasesJson.length)) {
          throw SeedDataException(
            '$where: freigabe_mit_phase $rwp ausserhalb der Phasen',
          );
        }
        final easier = _intOpt(it, 'leichter_als_index', where);
        if (easier != null) {
          if (easier < 0 || easier >= pos.length || easier == ii) {
            throw SeedDataException(
              '$where: leichter_als_index $easier ungueltig',
            );
          }
          if (_obj(pos[easier], where)['leichter_als_index'] != null) {
            throw SeedDataException(
              '$where: Variante verweist auf eine Variante',
            );
          }
        }
        payloadItems.add({
          'exercise_id': stableId('exercise:$ex'),
          if (it['saetze'] != null) 'sets': _int(it, 'saetze', where),
          if (it['wdh'] != null) 'reps': _int(it, 'wdh', where),
          if (it['dauer'] != null) 'duration_sec': _int(it, 'dauer', where),
          if (rwp != null) 'release': 'prepared',
          'release_with_phase': ?rwp,
          'easier_variant_of': ?easier,
        });
      }
      payloadPhases.add({
        'title': _str(p, 'titel', where),
        'planned_weeks': _int(p, 'wochen', where),
        'items': payloadItems,
      });
    }
    templates.add({
      'id': stableId('template:$key'),
      'practice_id': null,
      'name': _str(m, 'name', where),
      'injury_label': _str(m, 'verletzung', where),
      'is_example': true,
      'payload': {'phases': payloadPhases},
      'created_by_role': 'seed',
    });
  }

  // --- Praxen, Physios, Patienten ------------------------------------------
  final practiceKeys = <String>{};
  final physioKeys = <String>{};
  final emails = <String>{};
  final patientKeys = <String>{};
  final physioPractice = <String, String>{};
  final allKeysForIds =
      <String, String>{}; // id -> Herkunft, fuer Eindeutigkeit

  void registerId(String id, String origin) {
    final prev = allKeysForIds[id];
    if (prev != null) {
      throw SeedDataException('ID-Kollision zwischen "$prev" und "$origin"');
    }
    allKeysForIds[id] = origin;
  }

  for (final e in exercises) {
    registerId(e['id']! as String, 'exercise ${e['name']}');
  }
  for (final t in templates) {
    registerId(t['id']! as String, 'template ${t['name']}');
  }

  for (final p in _list(data['praxen'], 'praxen')) {
    final pm = _obj(p, 'praxen[]');
    final pKey = _str(pm, 'key', 'praxen[]');
    final pWhere = 'praxis[$pKey]';
    _checkKey(pKey, pWhere);
    _unique(practiceKeys, pKey, 'praxen');
    final pName = _str(pm, 'name', pWhere);
    if (!pName.contains('Testdaten')) {
      throw SeedDataException(
        '$pWhere: Name muss "Testdaten" enthalten (Kennzeichnung)',
      );
    }
    final practiceId = stableId('practice:$pKey');
    registerId(practiceId, pWhere);
    practices.add({'id': practiceId, 'name': pName, 'is_test': true});

    for (final ph in _list(pm['physios'], '$pWhere.physios')) {
      final m = _obj(ph, '$pWhere.physios[]');
      final key = _str(m, 'key', pWhere);
      _checkKey(key, pWhere);
      _unique(physioKeys, key, 'physios');
      final local = _str(m, 'email', pWhere);
      if (!RegExp(r'^[a-z0-9]+$').hasMatch(local)) {
        throw SeedDataException('$pWhere: E-Mail-Teil "$local" ungueltig');
      }
      final email = '$local@$domain';
      _unique(emails, email, 'E-Mail');
      physioPractice[key] = pKey;
      physioSteps.add(
        CreatePhysioAccount(
          key: key,
          email: email,
          displayName: _str(m, 'name', pWhere),
          practiceId: practiceId,
        ),
      );
    }
    if (physioPractice.values.where((v) => v == pKey).isEmpty) {
      throw SeedDataException('$pWhere: mindestens ein Physio noetig');
    }

    for (final e in _list(pm['uebungen'] ?? <dynamic>[], '$pWhere.uebungen')) {
      final m = _obj(e, '$pWhere.uebungen[]');
      final key = _str(m, 'key', pWhere);
      if (exerciseOwner.containsKey(key)) {
        throw SeedDataException('$pWhere: Uebung "$key" doppelt');
      }
      final row = exerciseRow(m, '$pWhere.uebung[$key]', practiceKey: pKey);
      exerciseOwner[key] = pKey;
      registerId(row['id']! as String, 'exercise $key');
      exercises.add(row);
    }

    for (final pat in _list(pm['patienten'], '$pWhere.patienten')) {
      final m = _obj(pat, '$pWhere.patienten[]');
      final key = _str(m, 'key', pWhere);
      final where = 'patient[$key]';
      _checkKey(key, where);
      _unique(patientKeys, key, 'patienten');
      final main = _str(m, 'hauptphysio', where);
      if (physioPractice[main] != pKey) {
        throw SeedDataException(
          '$where: Hauptphysio "$main" gehoert nicht zur Praxis "$pKey"',
        );
      }
      final patientId = stableId('patient:$key');
      registerId(patientId, where);
      final vorname = _str(m, 'vorname', where);
      patients.add({
        'id': patientId,
        'practice_id': practiceId,
        'first_name': vorname,
        'last_name': _str(m, 'nachname', where),
        'main_physio_id': PhysioRef(main),
        'status': 'invited',
      });

      bool exerciseUsable(String ex) =>
          exerciseOwner.containsKey(ex) &&
          (exerciseOwner[ex] == null || exerciseOwner[ex] == pKey);

      // Verletzung(en) und Plaene -------------------------------------------
      final verletzung = _obj(m['verletzung'], '$where.verletzung');
      final activeStart = _int(verletzung, 'beginn_tag', where);
      final injuryActiveId = stableId('injury:$key:aktiv');
      registerId(injuryActiveId, '$where injury aktiv');
      if (activeStart > 0) {
        throw SeedDataException('$where: beginn_tag liegt in der Zukunft');
      }
      injuries.add({
        'id': injuryActiveId,
        'patient_id': patientId,
        'label': _str(verletzung, 'bezeichnung', where),
        'reference_date': dayString(
          todayUtc,
          _int(verletzung, 'referenz_tag', where),
        ),
        'started_on': dayString(todayUtc, activeStart),
        'closed_on': null,
      });

      /// Plan mit Phasen/Positionen anlegen; liefert die Positionen der aktuellen Phase fuer Einheiten.
      _PlanBuild buildPlan({
        required String planKey,
        required String injuryId,
        required Map<String, dynamic> planJson,
        required bool closed,
        required String? currentPhaseKey,
      }) {
        final planId = stableId('plan:$key:$planKey');
        registerId(planId, '$where plan $planKey');
        plans.add({
          'id': planId,
          'patient_id': patientId,
          'injury_id': injuryId,
          'version': 1,
          'updated_by': PhysioRef(main),
          'closed': closed,
        });
        final phaseIds = <String, String>{};
        final positionIds = <String, String>{};
        final phaseOfPosition = <String, String>{};
        final posRows = <String, Row>{};
        final phaseJson = _list(planJson['phasen'], '$where.plan.phasen');
        if (phaseJson.isEmpty) {
          throw SeedDataException('$where: Plan ohne Phasen');
        }
        for (var pi = 0; pi < phaseJson.length; pi++) {
          final ph = _obj(phaseJson[pi], '$where.phasen[$pi]');
          final phKey = _str(ph, 'key', where);
          _checkKey(phKey, where);
          if (phaseIds.containsKey(phKey)) {
            throw SeedDataException('$where: Phase "$phKey" doppelt');
          }
          final id = stableId('phase:$key:$planKey:$phKey');
          registerId(id, '$where phase $phKey');
          phaseIds[phKey] = id;
        }
        for (var pi = 0; pi < phaseJson.length; pi++) {
          final ph = _obj(phaseJson[pi], '$where.phasen[$pi]');
          final phKey = ph['key'] as String;
          final weeks = _int(ph, 'wochen', where);
          if (weeks < 1 || weeks > 52) {
            throw SeedDataException('$where: wochen $weeks ausserhalb 1..52');
          }
          phases.add({
            'id': phaseIds[phKey],
            'plan_id': planId,
            'position': pi,
            'title': _str(ph, 'titel', where),
            'planned_weeks': weeks,
          });
          final pos = _list(
            ph['positionen'],
            '$where.phase[$phKey].positionen',
          );
          for (var ii = 0; ii < pos.length; ii++) {
            final it = _obj(pos[ii], '$where.phase[$phKey].positionen[$ii]');
            final iKey = _str(it, 'key', where);
            _checkKey(iKey, where);
            if (positionIds.containsKey(iKey)) {
              throw SeedDataException('$where: Position "$iKey" doppelt');
            }
            final ex = _str(it, 'uebung', where);
            if (!exerciseUsable(ex)) {
              throw SeedDataException(
                '$where: Uebung "$ex" nicht im Katalog oder in der Praxis',
              );
            }
            final id = stableId('item:$key:$planKey:$iKey');
            registerId(id, '$where position $iKey');
            positionIds[iKey] = id;
            phaseOfPosition[iKey] = phKey;
            final rwpKey = _strOpt(it, 'freigabe_mit_phase');
            final onDay = _intOpt(it, 'freigabe_am_tag', where);
            if (rwpKey != null && onDay != null) {
              throw SeedDataException(
                '$where: Position "$iKey" hat zwei Freigaben',
              );
            }
            if (rwpKey != null && !phaseIds.containsKey(rwpKey)) {
              throw SeedDataException(
                '$where: freigabe_mit_phase "$rwpKey" unbekannt',
              );
            }
            final prepared = rwpKey != null || onDay != null;
            final defaults = exerciseDefaults[ex]!;
            final row = <String, Object?>{
              'id': id,
              'plan_id': planId,
              'phase_id': phaseIds[phKey],
              'exercise_id': stableId('exercise:$ex'),
              'position': ii,
              'sets': _intOpt(it, 'saetze', where) ?? defaults['default_sets'],
              'reps': _intOpt(it, 'wdh', where),
              'duration_sec': _intOpt(it, 'dauer', where),
              'weight_kg': _numOpt(it, 'gewicht', where),
              'pause_sec': defaults['pause_sec'],
              'load_note': _strOpt(it, 'notiz'),
              'release': prepared ? 'prepared' : 'active',
              'release_on': onDay == null ? null : dayString(todayUtc, onDay),
              'release_with_phase_id': rwpKey == null ? null : phaseIds[rwpKey],
            };
            if (row['reps'] == null && row['duration_sec'] == null) {
              throw SeedDataException(
                '$where: Position "$iKey" braucht wdh oder dauer',
              );
            }
            posRows[iKey] = row;
            items.add(row);
          }
        }
        // leichtere Varianten (zweiter Durchgang, weil das Ziel schon existieren muss)
        final variantTargets = <String, String>{};
        for (final ph in phaseJson) {
          for (final it in _list(
            (ph as Map<String, dynamic>)['positionen'],
            where,
          )) {
            final im = it as Map<String, dynamic>;
            final target = _strOpt(im, 'leichter');
            if (target == null) continue;
            final iKey = im['key'] as String;
            if (target == iKey ||
                phaseOfPosition[target] != phaseOfPosition[iKey]) {
              throw SeedDataException(
                '$where: Variante "$iKey" -> "$target" muss in derselben Phase liegen',
              );
            }
            variantTargets[iKey] = target;
          }
        }
        for (final e in variantTargets.entries) {
          if (variantTargets.containsKey(e.value)) {
            throw SeedDataException(
              '$where: Variante "${e.key}" verweist auf die Variante "${e.value}"',
            );
          }
          variantUpdates.add(
            UpdateRows(
              'plan_items',
              {'easier_variant_of': positionIds[e.value]},
              {'id': positionIds[e.key]},
            ),
          );
        }
        final String currentKey =
            currentPhaseKey ??
            (phaseJson.first as Map<String, dynamic>)['key'] as String;
        if (!phaseIds.containsKey(currentKey)) {
          throw SeedDataException(
            '$where: aktuelle Phase "$currentKey" unbekannt',
          );
        }
        currentPhaseUpdates.add(
          UpdateRows(
            'plans',
            {'current_phase_id': phaseIds[currentKey]},
            {'id': planId},
          ),
        );
        // Positionen, die in Einheiten vorkommen: aktive Positionen der aktuellen Phase ohne Varianten
        final sessionPositions = <String>[
          for (final e in posRows.entries)
            if (phaseOfPosition[e.key] == currentKey &&
                e.value['release'] == 'active' &&
                !variantTargets.containsKey(e.key))
              e.key,
        ];
        return _PlanBuild(
          planId: planId,
          phaseId: phaseIds[currentKey]!,
          positions: {for (final k in sessionPositions) k: posRows[k]!},
          exerciseKeyOf: {
            for (final k in sessionPositions)
              k: _exerciseKeyOfPosition(planJson, k),
          },
        );
      }

      final activeBuild = buildPlan(
        planKey: 'aktiv',
        injuryId: injuryActiveId,
        planJson: _obj(m['plan'], '$where.plan'),
        closed: false,
        currentPhaseKey: _strOpt(_obj(m['plan'], where), 'aktuelle_phase'),
      );

      final trainingJson = _list(
        m['training'] ?? <dynamic>[],
        '$where.training',
      );
      final trainingBlocks = <_TrainingBlock>[];
      for (final t in trainingJson) {
        trainingBlocks.add(
          _TrainingBlock.parse(
            _obj(t, '$where.training[]'),
            where,
            activeBuild,
            'aktiv',
          ),
        );
      }

      for (final f in _list(
        m['fruehere_verletzungen'] ?? <dynamic>[],
        '$where.fruehere_verletzungen',
      )) {
        final fm = _obj(f, '$where.fruehere_verletzungen[]');
        final fKey = _str(fm, 'key', where);
        _checkKey(fKey, where);
        final fStart = _int(fm, 'beginn_tag', where);
        final fEnd = _int(fm, 'ende_tag', where);
        if (fEnd < fStart) {
          throw SeedDataException(
            '$where: fruehere Verletzung "$fKey" endet vor dem Beginn',
          );
        }
        if (fEnd >= activeStart) {
          throw SeedDataException(
            '$where: fruehere Verletzung "$fKey" endet nicht vor der aktiven',
          );
        }
        final fid = stableId('injury:$key:$fKey');
        registerId(fid, '$where injury $fKey');
        injuries.add({
          'id': fid,
          'patient_id': patientId,
          'label': _str(fm, 'bezeichnung', where),
          'reference_date': dayString(todayUtc, fStart),
          'started_on': dayString(todayUtc, fStart),
          'closed_on': dayString(todayUtc, fEnd),
        });
        final fb = buildPlan(
          planKey: fKey,
          injuryId: fid,
          planJson: _obj(fm['plan'], '$where.fruehere_verletzung.plan'),
          closed: true,
          currentPhaseKey: null,
        );
        for (final t in _list(
          fm['training'] ?? <dynamic>[],
          '$where.$fKey.training',
        )) {
          final block = _TrainingBlock.parse(
            _obj(t, '$where.$fKey.training[]'),
            where,
            fb,
            fKey,
          );
          if (block.from < fStart || block.to > fEnd) {
            throw SeedDataException(
              '$where: Training von "$fKey" liegt ausserhalb der Verletzung',
            );
          }
          trainingBlocks.add(block);
        }
      }

      // Einheiten und Ergebnisse -------------------------------------------
      for (final planKey in {for (final b in trainingBlocks) b.planKey}) {
        final blocks = trainingBlocks
            .where((b) => b.planKey == planKey)
            .toList();
        final days = <int>{};
        for (final b in blocks) {
          for (var d = b.from; d <= b.to; d++) {
            if (!b.skipDays.contains(d)) days.add(d);
          }
        }
        final ordered = days.toList()..sort();
        var streak = 0;
        int? prev;
        for (final d in ordered) {
          streak = (prev != null && d == prev + 1) ? streak + 1 : 1;
          prev = d;
          final block = blocks.firstWhere((b) => d >= b.from && d <= b.to);
          final sessionId = stableId('session:$key:$planKey:$d');
          registerId(sessionId, '$where session $planKey $d');
          final skipped = block.skipped[d] ?? const <String>{};
          final guided = d.isEven;
          final snapshot = <Map<String, Object?>>[];
          var itemNo = 0;
          for (final e in block.build.positions.entries) {
            final row = e.value;
            final exKey = block.build.exerciseKeyOf[e.key]!;
            snapshot.add({
              'plan_item_id': row['id'],
              'exercise_id': row['exercise_id'],
              'exercise_name': exerciseNames[exKey],
              'sets': row['sets'],
              'reps': row['reps'],
              'duration_sec': row['duration_sec'],
              'weight_kg': row['weight_kg'],
            });
            final isSkipped = skipped.contains(e.key);
            final resultId = stableId('result:$key:$planKey:$d:${e.key}');
            registerId(resultId, '$where result $planKey $d ${e.key}');
            results.add({
              'id': resultId,
              'patient_id': patientId,
              'training_session_id': sessionId,
              'local_day': dayString(todayUtc, d),
              'plan_item_id': row['id'],
              'exercise_id': row['exercise_id'],
              'exercise_name': exerciseNames[exKey],
              'status': isSkipped ? 'skipped' : 'done',
              'sets_done': isSkipped ? 0 : row['sets'],
              'reps_done': isSkipped ? 0 : (row['reps'] ?? 0),
              'logged_at': _timestamp(
                todayUtc,
                d,
                '17:${(10 + itemNo * 7).toString().padLeft(2, '0')}',
              ),
            });
            itemNo++;
          }
          final active = 480 + snapshot.length * 210;
          final startHour = 16 + (d.abs() % 4);
          sessions.add({
            'id': sessionId,
            'patient_id': patientId,
            'plan_id': block.build.planId,
            'local_day': dayString(todayUtc, d),
            'logged_at': _timestamp(todayUtc, d, '${startHour + 1}:30'),
            'phase_id': block.build.phaseId,
            'plan_version': 1,
            'items': snapshot,
            'mode': guided ? 'guided' : 'checklist',
            'started_at': guided
                ? _timestamp(todayUtc, d, '$startHour:00')
                : null,
            'ended_at': guided
                ? DateTime.parse(_timestamp(todayUtc, d, '$startHour:00'))
                      .add(Duration(seconds: active + 60))
                      .toIso8601String()
                : null,
            'active_seconds': guided ? active : null,
            'ended_early': guided ? skipped.isNotEmpty : null,
            'streak_after': streak,
          });
        }
      }
      final firstTraining = trainingBlocks
          .where((b) => b.planKey == 'aktiv')
          .map((b) => b.from);
      if (firstTraining.isNotEmpty &&
          firstTraining.reduce((a, b) => a < b ? a : b) < activeStart) {
        throw SeedDataException('$where: Training beginnt vor der Verletzung');
      }

      // Akte ------------------------------------------------------------------
      final treaterIds = <String, String>{};
      for (final t in _list(
        m['behandler'] ?? <dynamic>[],
        '$where.behandler',
      )) {
        final tm = _obj(t, '$where.behandler[]');
        final tKey = _str(tm, 'key', where);
        if (treaterIds.containsKey(tKey)) {
          throw SeedDataException('$where: Behandler "$tKey" doppelt');
        }
        final id = stableId('treater:$key:$tKey');
        registerId(id, '$where treater $tKey');
        treaterIds[tKey] = id;
        treaters.add({
          'id': id,
          'patient_id': patientId,
          'role': _str(tm, 'rolle', where),
          'name': _str(tm, 'name', where),
          'phone': _strOpt(tm, 'telefon'),
        });
      }
      var hi = 0;
      for (final h in _list(m['verlauf'] ?? <dynamic>[], '$where.verlauf')) {
        final hm = _obj(h, '$where.verlauf[]');
        final id = stableId('history:$key:$hi');
        registerId(id, '$where history $hi');
        hi++;
        history.add({
          'id': id,
          'patient_id': patientId,
          'kind': _str(hm, 'art', where),
          'title': _str(hm, 'titel', where),
          'occurred_on': hm['tag'] == null
              ? null
              : dayString(todayUtc, _int(hm, 'tag', where)),
          'note': _strOpt(hm, 'notiz'),
        });
      }
      var ai = 0;
      for (final a in _list(m['termine'] ?? <dynamic>[], '$where.termine')) {
        final am = _obj(a, '$where.termine[]');
        final tRef = _strOpt(am, 'behandler');
        if (tRef != null && !treaterIds.containsKey(tRef)) {
          throw SeedDataException(
            '$where: Termin verweist auf unbekannten Behandler "$tRef"',
          );
        }
        final id = stableId('appointment:$key:$ai');
        registerId(id, '$where appointment $ai');
        ai++;
        appointments.add({
          'id': id,
          'patient_id': patientId,
          'treater_id': tRef == null ? null : treaterIds[tRef],
          'starts_at': _timestamp(
            todayUtc,
            _int(am, 'tag', where),
            _str(am, 'zeit', where),
          ),
          'title': _str(am, 'titel', where),
          'location': _strOpt(am, 'ort'),
          'created_by_role': 'physio',
          'created_by': PhysioRef(main),
        });
      }

      invitations.add(
        PhysioRpc(
          physioKey: main,
          fn: 'regenerate_invitation',
          params: {'p_patient_id': patientId},
          subject: '$vorname (${_str(m, 'nachname', where)})',
        ),
      );
    }
  }

  if (practices.length != 2) {
    // Plan 10: 2 Praxen, je 2 Physios, 5 Patienten. Abweichungen sind erlaubt, aber melden.
    notes.add(
      'Hinweis: ${practices.length} Praxen statt der im Plan genannten 2',
    );
  }

  final steps = <SeedStep>[
    UpsertRows('practices', practices),
    ...physioSteps,
    UpsertRows('exercises', exercises),
    UpsertRows('plan_templates', templates),
    UpsertRows('patients', patients),
    UpsertRows('injuries', injuries),
    UpsertRows('plans', plans),
    UpsertRows('phases', phases),
    UpsertRows('plan_items', items),
    ...variantUpdates,
    ...currentPhaseUpdates,
    if (treaters.isNotEmpty) UpsertRows('treaters', treaters),
    if (history.isNotEmpty) UpsertRows('history_entries', history),
    if (appointments.isNotEmpty) UpsertRows('appointments', appointments),
    if (sessions.isNotEmpty) UpsertRows('training_sessions', sessions),
    if (results.isNotEmpty) UpsertRows('exercise_results', results),
    ...invitations,
  ];
  return SeedPlan(
    steps: steps,
    emailDomain: domain,
    today: todayUtc,
    notes: notes,
  );
}

String _exerciseKeyOfPosition(Map<String, dynamic> planJson, String posKey) {
  for (final ph in planJson['phasen'] as List<dynamic>) {
    for (final it
        in (ph as Map<String, dynamic>)['positionen'] as List<dynamic>) {
      final im = it as Map<String, dynamic>;
      if (im['key'] == posKey) return im['uebung'] as String;
    }
  }
  throw SeedDataException('Position "$posKey" nicht gefunden');
}

class _PlanBuild {
  _PlanBuild({
    required this.planId,
    required this.phaseId,
    required this.positions,
    required this.exerciseKeyOf,
  });
  final String planId;
  final String phaseId;
  final Map<String, Row>
  positions; // Schluessel -> plan_items-Zeile (Positionen der Einheiten)
  final Map<String, String> exerciseKeyOf;
}

class _TrainingBlock {
  _TrainingBlock({
    required this.planKey,
    required this.build,
    required this.from,
    required this.to,
    required this.skipDays,
    required this.skipped,
  });
  final String planKey;
  final _PlanBuild build;
  final int from;
  final int to;
  final Set<int> skipDays;
  final Map<int, Set<String>> skipped;

  static _TrainingBlock parse(
    Map<String, dynamic> t,
    String where,
    _PlanBuild build,
    String planKey,
  ) {
    final from = _int(t, 'von', where);
    final to = _int(t, 'bis', where);
    if (from > to) {
      throw SeedDataException('$where: Training von $from liegt nach bis $to');
    }
    if (to > -1 && planKey == 'aktiv') {
      throw SeedDataException(
        '$where: Training nur bis gestern (bis <= -1); heute gehoert dem Patienten',
      );
    }
    final skipDays = <int>{
      for (final d in _list(t['ohne'] ?? <dynamic>[], '$where.ohne')) d as int,
    };
    for (final d in skipDays) {
      if (d < from || d > to) {
        throw SeedDataException('$where: "ohne" Tag $d ausserhalb $from..$to');
      }
    }
    final skipped = <int, Set<String>>{};
    for (final s in _list(
      t['uebersprungen'] ?? <dynamic>[],
      '$where.uebersprungen',
    )) {
      final sm = _obj(s, '$where.uebersprungen[]');
      final day = _int(sm, 'tag', where);
      if (day < from || day > to || skipDays.contains(day)) {
        throw SeedDataException(
          '$where: uebersprungen am Tag $day ohne Einheit',
        );
      }
      final set = <String>{
        for (final p in _list(sm['positionen'], where)) '$p',
      };
      for (final p in set) {
        if (!build.positions.containsKey(p)) {
          throw SeedDataException(
            '$where: uebersprungene Position "$p" gehoert nicht zur Einheit',
          );
        }
      }
      skipped[day] = set;
    }
    return _TrainingBlock(
      planKey: planKey,
      build: build,
      from: from,
      to: to,
      skipDays: skipDays,
      skipped: skipped,
    );
  }
}
