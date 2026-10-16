-- DB-T22 save_plan_current_phase (Plan 12.2, M-5): aktuelle Phase entfernt ohne Ersatz bzw. fehlend
-- -> current_phase_required; Phase eines anderen Payloads -> current_phase_required; leerer Plan ok.
\set ON_ERROR_STOP 1
\o /dev/null
\ir _plan_base.psql
SELECT t.seed_base();
SELECT t.as_user(t.id('phys_a1'));
SELECT t.is(t.save_plan('pat_a2', :'base'), 2, 'Basisplan gespeichert');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)',
  '{"current_phase_id":"{{ph1}}","phases":[{"id":"{{ph2}}","position":0,"title":"P2","planned_weeks":3}],"items":[]}'),
  'P0001', 'aktuelle Phase entfernt, nicht ersetzt -> current_phase_required', 'current_phase_required');
SELECT t.throws(format('SELECT t.save_plan(''pat_a2'', %L)',
  '{"phases":[{"id":"{{ph2}}","position":0,"title":"P2","planned_weeks":3}],"items":[]}'),
  'P0001', 'Phasen ohne aktuelle Phase -> current_phase_required', 'current_phase_required');
SELECT t.is((SELECT version FROM public.plans WHERE patient_id = t.id('pat_a2')), 2, 'nichts geaendert');
SELECT t.is(t.save_plan('pat_a2', '{"current_phase_id":"{{ph2}}","phases":[{"id":"{{ph2}}","position":0,"title":"P2","planned_weeks":3}],"items":[]}'),
            3, 'aktuelle Phase ersetzt -> ok');
SELECT t.is((SELECT current_phase_id FROM public.plans WHERE patient_id = t.id('pat_a2')), t.id('ph2'), 'neue aktuelle Phase');
SELECT t.is(t.save_plan('pat_a2', '{"current_phase_id":null,"phases":[],"items":[]}'), 4, 'leerer Plan ohne aktuelle Phase -> ok');
SELECT t.is((SELECT current_phase_id FROM public.plans WHERE patient_id = t.id('pat_a2')), NULL::uuid, 'aktuelle Phase NULL');
