import 'package:flutter/foundation.dart';

import '../domain/medication.dart';

typedef Clock = DateTime Function();

class MedicationStore extends ChangeNotifier {
  MedicationStore({
    Iterable<Medication> medications = const [],
    Clock? clock,
    String? initialError,
  }) : _medications = List.of(medications),
       _clock = clock ?? DateTime.now,
       _errorMessage = initialError,
       _nextId = medications.length + 1;

  factory MedicationStore.seeded({Clock? clock}) {
    final effectiveClock = clock ?? DateTime.now;
    final today = dateOnly(effectiveClock());

    return MedicationStore(
      clock: effectiveClock,
      medications: [
        Medication(
          id: 'med-1',
          name: 'Dipirona',
          expirationDate: today.add(const Duration(days: 90)),
          quantity: 8,
          notes: 'Comprimidos guardados no armário da cozinha.',
        ),
        Medication(
          id: 'med-2',
          name: 'Loratadina',
          expirationDate: today.add(const Duration(days: 12)),
          quantity: 6,
        ),
        Medication(
          id: 'med-3',
          name: 'Soro fisiológico',
          expirationDate: today.subtract(const Duration(days: 5)),
          quantity: 1,
          notes: 'Separado para descarte responsável.',
        ),
      ],
    );
  }

  final List<Medication> _medications;
  final Clock _clock;
  int _nextId;
  String? _errorMessage;

  DateTime get today => dateOnly(_clock());

  String? get errorMessage => _errorMessage;

  List<Medication> get medications {
    final sorted = List<Medication>.of(_medications)
      ..sort((first, second) {
        final byDate = first.expirationDate.compareTo(second.expirationDate);
        return byDate != 0 ? byDate : first.name.compareTo(second.name);
      });
    return List.unmodifiable(sorted);
  }

  int get totalCount => _medications.length;

  int countByStatus(MedicationStatus status) => _medications
      .where((medication) => medication.statusAt(today) == status)
      .length;

  Medication? findById(String id) {
    for (final medication in _medications) {
      if (medication.id == id) {
        return medication;
      }
    }
    return null;
  }

  Medication add(MedicationDraft draft) {
    final medication = Medication(
      id: _newId(),
      name: draft.name.trim(),
      expirationDate: dateOnly(draft.expirationDate),
      quantity: draft.quantity,
      notes: draft.notes.trim(),
    );

    _medications.add(medication);
    _errorMessage = null;
    notifyListeners();
    return medication;
  }

  void update(String id, MedicationDraft draft) {
    final index = _medications.indexWhere((medication) => medication.id == id);
    if (index == -1) {
      return;
    }

    _medications[index] = _medications[index].copyWith(
      name: draft.name.trim(),
      expirationDate: dateOnly(draft.expirationDate),
      quantity: draft.quantity,
      notes: draft.notes.trim(),
    );
    _errorMessage = null;
    notifyListeners();
  }

  void remove(String id) {
    final previousLength = _medications.length;
    _medications.removeWhere((medication) => medication.id == id);
    if (_medications.length != previousLength) {
      notifyListeners();
    }
  }

  void retry() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  String _newId() {
    while (_medications.any((medication) => medication.id == 'med-$_nextId')) {
      _nextId++;
    }
    return 'med-${_nextId++}';
  }
}
