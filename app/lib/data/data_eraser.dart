/// KS-9: Alles, was Nutzerdaten hält, kann sie löschen. Der `AppController`
/// ruft die Löscher der Reihe nach; der erste Fehler bricht ab (Plan 6.3).
abstract class DataEraser {
  Future<void> eraseAll();
}
