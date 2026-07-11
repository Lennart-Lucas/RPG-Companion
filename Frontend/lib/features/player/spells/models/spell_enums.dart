import 'package:anvil_foundry/anvil_foundry.dart';

abstract final class SpellFormKeys {
  static const name = 'name';
  static const fileId = 'file_id';
  static const level = 'level';
  static const school = 'school';
  static const castingTime = 'casting_time';
  static const castingType = 'casting_type';
  static const trigger = 'trigger';
  static const duration = 'duration';
  static const concentration = 'concentration';
  static const range = 'range';
  static const componentVerbal = 'component_verbal';
  static const componentSomatic = 'component_somatic';
  static const componentMaterial = 'component_material';
  static const materials = 'materials';
  static const description = 'description';
  static const higherLevels = 'higher_levels';
  static const classIds = 'class_ids';
  static const spellTagIds = 'spell_tag_ids';
}

abstract final class SpellLevels {
  static const values = [
    'cantrip',
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th',
    '7th',
    '8th',
    '9th',
  ];

  static String labelFor(String value) {
    if (value == 'cantrip') return 'Cantrip';
    return '$value level';
  }

  static List<AnvilFieldOption<String>> get options => values
      .map((v) => AnvilFieldOption(value: v, label: labelFor(v)))
      .toList();
}

abstract final class SpellSchools {
  static const values = [
    'abjuration',
    'conjuration',
    'divination',
    'enchantment',
    'evocation',
    'illusion',
    'necromancy',
    'transmutation',
  ];

  static String labelFor(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  static List<AnvilFieldOption<String>> get options => values
      .map((v) => AnvilFieldOption(value: v, label: labelFor(v)))
      .toList();
}

abstract final class CastingTypes {
  static const action = 'action';
  static const bonusAction = 'bonus_action';
  static const reaction = 'reaction';
  static const minutes = 'minutes';
  static const hours = 'hours';

  static const values = [
    action,
    bonusAction,
    reaction,
    minutes,
    hours,
  ];

  static String labelFor(String value) {
    return switch (value) {
      action => 'Action',
      bonusAction => 'Bonus Action',
      reaction => 'Reaction',
      minutes => 'Minute(s)',
      hours => 'Hour(s)',
      _ => value,
    };
  }

  static List<AnvilFieldOption<String>> get options => values
      .map((v) => AnvilFieldOption(value: v, label: labelFor(v)))
      .toList();
}

abstract final class SpellDurations {
  static const values = [
    'instantaneous',
    '1_round',
    '1_minute',
    '10_minutes',
    '1_hour',
    '8_hours',
    '24_hours',
  ];

  static String labelFor(String value) {
    return switch (value) {
      'instantaneous' => 'Instantaneous',
      '1_round' => '1 round',
      '1_minute' => '1 minute',
      '10_minutes' => '10 minutes',
      '1_hour' => '1 hour',
      '8_hours' => '8 hours',
      '24_hours' => '24 hours',
      _ => value,
    };
  }

  static List<AnvilFieldOption<String>> get options => values
      .map((v) => AnvilFieldOption(value: v, label: labelFor(v)))
      .toList();
}

abstract final class SpellRanges {
  static const values = [
    'touch',
    'self',
    '5_feet',
    '10_feet',
    'self_15_feet',
    'self_30_feet',
    '30_feet',
    '40_feet',
    '60_feet',
    '90_feet',
    '120_feet',
  ];

  static String labelFor(String value) {
    return switch (value) {
      'touch' => 'Touch',
      'self' => 'Self',
      '5_feet' => '5 feet',
      '10_feet' => '10 feet',
      'self_15_feet' => 'Self (15 feet)',
      'self_30_feet' => 'Self (30 feet)',
      '30_feet' => '30 feet',
      '40_feet' => '40 feet',
      '60_feet' => '60 feet',
      '90_feet' => '90 feet',
      '120_feet' => '120 feet',
      _ => value,
    };
  }

  static List<AnvilFieldOption<String>> get options => values
      .map((v) => AnvilFieldOption(value: v, label: labelFor(v)))
      .toList();
}
