import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/widgets.dart';

/// Enum to represent the strength of a drink.
enum DrinkStrength {
  low, // Low alcohol content
  medium, // Moderate alcohol content
  high, // High alcohol content
  nonAlcoholic, // Non-alcoholic drink
}

/// Enum to represent different types of drinks.
enum DrinkType {
  beer, // Beer with typical alcohol content
  wine, // Wine with moderate alcohol content
  whiskey, // Whiskey with high alcohol content
  vodka, // Vodka with high alcohol content
  gin, // Gin with high alcohol content
  rum, // Rum with high alcohol content
  tequila, // Tequila with high alcohol content
  cocktail, // Mixed drink, typically moderate alcohol content
  cider, // Cider, usually low alcohol content
  zeroBeer, // Non-alcoholic beer
  other, // Any other drink type
}

/// Extension on DrinkType to add helper methods and properties.
extension DrinkTypeExtension on DrinkType {
  /// Returns the name of the drink type as a string.
  String get name {
    switch (this) {
      case DrinkType.beer:
        return 'Beer';
      case DrinkType.wine:
        return 'Wine';
      case DrinkType.whiskey:
        return 'Whiskey';
      case DrinkType.vodka:
        return 'Vodka';
      case DrinkType.gin:
        return 'Gin';
      case DrinkType.rum:
        return 'Rum';
      case DrinkType.tequila:
        return 'Tequila';
      case DrinkType.cocktail:
        return 'Cocktail';
      case DrinkType.cider:
        return 'Cider';
      case DrinkType.zeroBeer:
        return '0.0% Beer';
      case DrinkType.other:
      default:
        return 'Other';
    }
  }

  /// Converts a string to a DrinkType enum value.
  /// Defaults to DrinkType.other if no match is found.
  static DrinkType fromString(String drinkType) {
    switch (drinkType.toLowerCase()) {
      case 'beer':
        return DrinkType.beer;
      case 'wine':
        return DrinkType.wine;
      case 'whiskey':
        return DrinkType.whiskey;
      case 'vodka':
        return DrinkType.vodka;
      case 'gin':
        return DrinkType.gin;
      case 'rum':
        return DrinkType.rum;
      case 'tequila':
        return DrinkType.tequila;
      case 'cocktail':
        return DrinkType.cocktail;
      case 'cider':
        return DrinkType.cider;
      case '0.0% beer':
        return DrinkType.zeroBeer;
      default:
        return DrinkType.other;
    }
  }

  /// Converts the DrinkType enum value to a string for database storage.
  String toDatabaseString() {
    return name;
  }

  /// Returns the strength category for the drink type.
  DrinkStrength get strength {
    switch (this) {
      case DrinkType.beer:
      case DrinkType.cider:
        return DrinkStrength.low;
      case DrinkType.wine:
      case DrinkType.cocktail:
        return DrinkStrength.medium;
      case DrinkType.whiskey:
      case DrinkType.vodka:
      case DrinkType.gin:
      case DrinkType.rum:
      case DrinkType.tequila:
        return DrinkStrength.high;
      case DrinkType.zeroBeer:
        return DrinkStrength.nonAlcoholic;
      case DrinkType.other:
        return DrinkStrength.medium; // Default for unspecified drinks
    }
  }

  /// Provides an estimated ABV (Alcohol By Volume) percentage for each drink type.
  double get abvRange {
    switch (this) {
      case DrinkType.beer:
        return 4.0;
      case DrinkType.wine:
        return 12.0;
      case DrinkType.whiskey:
      case DrinkType.vodka:
      case DrinkType.gin:
      case DrinkType.rum:
      case DrinkType.tequila:
        return 40.0;
      case DrinkType.cocktail:
        return 15.0;
      case DrinkType.cider:
        return 5.0;
      case DrinkType.zeroBeer:
        return 0.0;
      case DrinkType.other:
        return 10.0; // Assumed ABV for unspecified types
      default:
        return 0.0;
    }
  }

  /// Retrieves an icon representation for each drink type.
  IconData get icon {
    switch (this) {
      case DrinkType.beer:
      case DrinkType.cider:
      case DrinkType.zeroBeer:
        return FontAwesomeIcons.beerMugEmpty;
      case DrinkType.wine:
        return FontAwesomeIcons.wineGlass;
      case DrinkType.whiskey:
      case DrinkType.rum:
        return FontAwesomeIcons.whiskeyGlass;
      case DrinkType.vodka:
        return FontAwesomeIcons.wineBottle;
      case DrinkType.gin:
        return FontAwesomeIcons.martiniGlassEmpty;
      case DrinkType.tequila:
      case DrinkType.cocktail:
        return FontAwesomeIcons.martiniGlassCitrus;
      case DrinkType.other:
      default:
        return FontAwesomeIcons.champagneGlasses;
    }
  }
}
