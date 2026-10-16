-- NUR FUER LOKALE TESTS: offensichtlicher Platzhalter-Pepper, niemals ein echter Wert.
-- Der echte Pepper wird per externem Schritt X2-11 im Projekt gesetzt (nie im Repository).
INSERT INTO app.secrets (name, value)
VALUES ('invite_pepper', 'TEST-PEPPER-NUR-LOKAL-KEIN-ECHTER-WERT')
ON CONFLICT (name) DO NOTHING;
