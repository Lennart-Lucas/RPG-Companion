import 'package:flutter/material.dart';

IconData spellSchoolIcon(String school) {
  return switch (school) {
    'abjuration' => Icons.shield_outlined,
    'conjuration' => Icons.water_drop_outlined,
    'divination' => Icons.visibility_outlined,
    'enchantment' => Icons.favorite_border,
    'evocation' => Icons.bolt_outlined,
    'illusion' => Icons.blur_on_outlined,
    'necromancy' => Icons.dark_mode_outlined,
    'transmutation' => Icons.science_outlined,
    _ => Icons.auto_fix_high_outlined,
  };
}
