import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/widgets.dart';

enum DrinkStrength {
  low,
  medium,
  high,
  nonAlcoholic,
}

enum DrinkType {
  beer,
  wine,
  whiskey,
  vodka,
  gin,
  rum,
  tequila,
  cocktail,
  cider,
  zeroBeer, // 0.0% Beer
  water, // Water
  other,
}

extension DrinkTypeExtension on DrinkType {
  // Get the name for the drink type
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
      case DrinkType.water:
        return 'Water';
      case DrinkType.other:
        return 'Other';
      default:
        return '';
    }
  }

  // Get the strength for the drink type
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
      case DrinkType.water:
        return DrinkStrength.nonAlcoholic;
      case DrinkType.other:
        return DrinkStrength.medium; // Default for unknown drinks
    }
  }

  // Get the average ABV (Alcohol by Volume) for each drink type
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
      case DrinkType.water:
        return 0.0;
      case DrinkType.other:
        return 10.0; // Example ABV for unknown types
      default:
        return 0.0;
    }
  }

  // Get the associated icon for each drink type
  IconData get icon {
    switch (this) {
      case DrinkType.beer:
        return FontAwesomeIcons.beerMugEmpty;
      case DrinkType.wine:
        return FontAwesomeIcons.wineGlass;
      case DrinkType.whiskey:
        return FontAwesomeIcons.whiskeyGlass;
      case DrinkType.vodka:
        return FontAwesomeIcons.wineBottle;
      case DrinkType.gin:
        return FontAwesomeIcons.martiniGlassEmpty;
      case DrinkType.rum:
        return FontAwesomeIcons.whiskeyGlass;
      case DrinkType.tequila:
        return FontAwesomeIcons.martiniGlassCitrus;
      case DrinkType.cocktail:
        return FontAwesomeIcons.martiniGlassCitrus;
      case DrinkType.cider:
        return FontAwesomeIcons.beerMugEmpty;
      case DrinkType.zeroBeer:
        return FontAwesomeIcons.beerMugEmpty;
      case DrinkType.water:
        return FontAwesomeIcons.droplet;
      case DrinkType.other:
      default:
        return FontAwesomeIcons.champagneGlasses;
    }
  }
}
