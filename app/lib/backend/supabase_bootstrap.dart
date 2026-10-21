// Start des Backends: ohne Konfiguration passiert nichts (die App bleibt im
// Demo-Modus ohne Backend, Plan 8.12). Der Wert `SUPABASE_ANON_KEY` ist der
// öffentliche Client-Schlüssel (auch als „publishable key“ bezeichnet).
import 'package:supabase_flutter/supabase_flutter.dart';

import 'patient_backend.dart';
import 'supabase_config.dart';
import 'supabase_patient_backend.dart';

/// Initialisiert Supabase und liefert das Backend; `null`, wenn
/// [config] fehlt. Aufruf aus `main()` vor `runApp` (Verdrahtung: F2-4a).
Future<PatientBackend?> createPatientBackend(SupabaseConfig? config) async {
  if (config == null) return null;
  await Supabase.initialize(url: config.url, publishableKey: config.anonKey);
  return SupabasePatientBackend(Supabase.instance.client);
}
