# DB-Tests (lokales Postgres 16, Lieferung L2)

```
supabase/tests/run_local_pg.sh            # alles: Cluster, Migrationen, Idempotenz, Tests, Abbau
supabase/tests/run_local_pg.sh T13        # nur Tests, deren Dateiname "T13" enthält
PG_WORKDIR=/tmp/curaone-pg KEEP=1 ...     # Arbeitsverzeichnis festlegen, Cluster stehen lassen
```

- Läuft nur lokal gegen ein Wegwerf-Postgres (`/usr/lib/postgresql/16`); als root startet der
  Server als Benutzer `postgres`, `PG_WORKDIR` muss für ihn erreichbar sein.
- `shim/supabase_roles.sql` bildet die Supabase-Rollen, Standard-Grants und `auth.*` nach (Plan 12.1);
  `shim/test_pepper.sql` setzt einen offensichtlichen Test-Pepper (nie ein echter Wert).
- `db/_helpers.sql` (Schema `t`, nur in der Test-Vorlage): Prüfungen `t.ok/t.is/t.throws/t.lives`,
  Sitzungswechsel `t.as_*`, Uhr `t.set_clock`, Basis-Fixture `t.seed_base()` (nur Testdaten).
- Jede Testdatei läuft in einer frischen Datenbank aus der Vorlage; `db/race/*.sh` nutzen zwei
  bzw. drei Verbindungen.
- Nicht hier prüfbar (Stack, X2-8): DB-T40 (Seed), DB-T68 und Storage-Teil von DB-T80, echtes
  Supabase-Auth/GoTrue, PostgREST-Exposition der Schemas (DB-T81 prüft nur `config.toml`).

## Rückverfolgung DB-Test → Plan Ausschnitt 2 (v2.2)

| Test | Datei | Plan-Stelle |
|---|---|---|
| MIG-IDEM | `run_local_pg.sh` | Auftrag F2-1 (Migrationen idempotent, Reihenfolge 01–07) |
| DB-T01 | `T01_defaults_revoked.sql` | 6.1 Nr. 2, 6.2, 6.4, 6.14 |
| DB-T02 | `T02_no_force_rls_definer_sees_rows.sql` | 6.1 Nr. 1 (M-1) |
| DB-T03 | `T03_anon_role_sees_nothing.sql` | 6.1 Nr. 2 |
| DB-T04 | `T04_unbound_anonymous_sees_nothing.sql` | 6.14, 7.2 |
| DB-T05 | `T05_unbound_anonymous_rpc_denied.sql` | 6.4 |
| DB-T06 | `T06_physio_practice_isolation.sql` | 6.14, P-1 |
| DB-T07 | `T07_physio_sees_all_practice_patients.sql` | N-4 |
| DB-T08 | `T08_patient_sees_only_self.sql` | 6.14 |
| DB-T09 | `T09_invitation_hash_not_readable.sql` | 6.2 (M-2), 6.5 |
| DB-T10 | `T10_invitation_cross_practice.sql` | 6.4 |
| DB-T11 | `T11_redeem_requires_anonymous.sql` | 6.4 (M-3) |
| DB-T12 | `T12_redeem_already_bound.sql` | 6.4 |
| DB-T13 | `T13_redeem_results.sql` | 6.4, 6.5 |
| DB-T14 | `T14_redeem_throttle.sql` | 6.5 (N-6) |
| DB-T15 | `T15_patient_cannot_modify_physio_entries.sql` | 6.2, A-4 |
| DB-T16 | `T16_created_by_server_side.sql` | 6.3 (m-3) |
| DB-T17 | `T17_own_appointments_only.sql` | 6.2 |
| DB-T18 | `T18_exercise_requires_name_description.sql` | 6.2, 6.11, P-3 |
| DB-T19 | `T19_exercise_cross_practice.sql` | 6.6 Nr. 4, 6.7 |
| DB-T20–T24 | `T20_…` bis `T24_…` | 6.7 (M-5) |
| DB-T29 | `T29_delete_my_data_scope.sql` | 6.13 |
| DB-T30 | `T30_delete_my_data_idempotent.sql` | 6.13 |
| DB-T31 | `race/T31_race_delete_vs_insert.sh` | 6.13 (M-4), 6.3 |
| DB-T32 | `T32_auth_user_delete_set_null.sql` | 6.2 |
| DB-T33–T35 | `T33_…`, `T34_…`, `T35_…` | 6.4, 7.2 (N-1) |
| DB-T36 | `T36_inactive_patient_blocked.sql` | 6.3 |
| DB-T37 | `T37_rpc_execute_grants.sql` | 6.4 |
| DB-T38 | `T38_definer_functions_search_path.sql` | 6.1 Nr. 4 |
| DB-T39 | `T39_set_current_phase_foreign_phase.sql` | 6.4 |
| DB-T42 | `T42_active_patient_writes_and_undoes.sql` | 6.2, B-24 |
| DB-T43 | `T43_delete_my_data_with_data.sql` | 6.13 |
| DB-T44 | `T44_physio_maintains_record_invited_and_deleted.sql` | 6.3 |
| DB-T45 | `T45_seed_writes_without_binding.sql` | 6.1 Nr. 5 (MINOR-C), 6.3 |
| DB-T46 | `T46_save_plan_foreign_ids.sql` | 6.7 |
| DB-T47 | `T47_redeem_attempts_cleanup.sql` | 6.2 |
| DB-T59 | `T59_exercise_results_own.sql` | 6.2 |
| DB-T61 | `T61_injury_id_server_side.sql` | 6.3 (MINOR-4, MINOR-D), 6.14 |
| DB-T63 | `T63_create_patient_from_template.sql` | 6.6, 6.7 Nr. 3/5 (d) |
| DB-T64 | `T64_create_patient_minimal.sql` | 6.6 |
| DB-T64b | `T64b_create_patient_idempotent.sql`, `race/T64b_create_patient_concurrent.sh` | 6.6 (MINOR-1, MINOR-F) |
| DB-T65 | `T65_plan_item_release.sql` | 6.7, E-30 (N-17) |
| DB-T66 | `T66_exercise_builder_fields.sql` | 6.2, 6.11 |
| DB-T68a | `T68a_patient_can_see_exercise.sql` | 6.1 Nr. 5, 6.7 Nr. 2/5 (a, b) |
| DB-T70 | `T70_lock_trigger_all_patient_tables.sql` | 6.3, 6.14 |
| DB-T71 | `T71_delete_scope_new_tables.sql` | 6.13, 6.14 |
| DB-T73 | `T73_session_update_columns_only.sql` | 6.2 |
| DB-T74 | `T74_plan_closed_read_only.sql` | 6.7 |
| DB-T76 | `T76_templates_practice_scope.sql` | 6.2 |
| DB-T78 | `T78_one_active_injury.sql` | 6.8 |
| DB-T80 | `T80_security_not_date_dependent.sql` | 6.7 Nr. 2/3/5 (MAJOR-2) |
| DB-T81 | `T81_app_helpers_caller_checked.sql` | 6.1 Nr. 5 (MAJOR-A, MINOR-C, MINOR-9) |
| DB-T85 | `T85_manny_look_patient_only.sql` | 6.4, 6.13, O-41, NIT-1 (N-17) |
