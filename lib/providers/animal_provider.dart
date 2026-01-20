import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../services/firebase_service.dart';

/// Animal Provider - Manages animal data and operations
class AnimalProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<Animal> _animals = [];
  Animal? _selectedAnimal;
  bool _isLoading = false;
  String? _errorMessage;

  List<Animal> get animals => _animals;
  Animal? get selectedAnimal => _selectedAnimal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Clear all animal data (call on logout)
  void clearData() {
    _animals = [];
    _selectedAnimal = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    debugPrint('🧹 AnimalProvider: Data cleared');
  }

  /// Load all animals
  Future<void> loadAnimals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _firebaseService.getAnimals();
      _animals = data.map((json) => Animal.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add new animal
  Future<bool> addAnimal(Animal animal) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _firebaseService.createAnimal(animal.toJson());
      final newAnimal = Animal.fromJson(data);
      _animals.insert(0, newAnimal);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update animal
  Future<bool> updateAnimal(Animal animal) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _firebaseService.updateAnimal(
        animal.id,
        animal.toJson(),
      );
      final updatedAnimal = Animal.fromJson(data);
      
      final index = _animals.indexWhere((a) => a.id == animal.id);
      if (index != -1) {
        _animals[index] = updatedAnimal;
      }
      
      if (_selectedAnimal?.id == animal.id) {
        _selectedAnimal = updatedAnimal;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete animal
  Future<bool> deleteAnimal(String animalId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.deleteAnimal(animalId);
      _animals.removeWhere((a) => a.id == animalId);
      
      if (_selectedAnimal?.id == animalId) {
        _selectedAnimal = null;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Select animal
  void selectAnimal(Animal? animal) {
    _selectedAnimal = animal;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get animal by ID
  Animal? getAnimalById(String id) {
    try {
      return _animals.firstWhere((animal) => animal.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Filter animals by species
  List<Animal> getAnimalsBySpecies(String species) {
    return _animals.where((animal) => animal.species == species).toList();
  }

  /// Filter animals by health status
  List<Animal> getAnimalsByHealthStatus(String status) {
    return _animals.where((animal) => animal.healthStatus == status).toList();
  }
}
