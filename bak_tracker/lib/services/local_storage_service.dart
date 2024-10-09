import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:bak_tracker/models/association_model.dart';

class LocalStorageService {
  static const _selectedAssociationKey = 'selected_association';

  Future<void> saveSelectedAssociation(AssociationModel association) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _selectedAssociationKey, jsonEncode(association.toMap()));
  }

  Future<AssociationModel?> loadSelectedAssociation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_selectedAssociationKey);
    if (savedData != null) {
      return AssociationModel.fromMap(jsonDecode(savedData));
    }
    return null;
  }

  Future<void> removeSelectedAssociation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedAssociationKey);
  }
}
