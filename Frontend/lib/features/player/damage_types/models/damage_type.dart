import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/material.dart';
import 'package:rpg_companion/core/records/record_json_utils.dart';
import 'package:rpg_companion/core/records/rpg_record.dart';

abstract final class DamageTypeFormKeys {
  static const name = 'name';
  static const description = 'description';
  static const icon = 'icon';
  static const color = 'color';
}

class DamageType extends RpgRecord {
  @override
  final RecordId id;
  @override
  RecordType get recordType => 'damage_types';
  @override
  final String name;
  final String? description;
  final String? icon;
  final int? color;

  DamageType({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
  });

  factory DamageType.fromJson(Map<String, dynamic> json) {
    final data = RpgRecord.unwrapJson(json);
    final rawDescription = data['description'];
    final rawIcon = data['icon'];
    final rawColor = data['color'];
    return DamageType(
      id: RpgRecord.idFromJson(data),
      name: RpgRecord.nameFromJson(data),
      description: rawDescription is String ? rawDescription : null,
      icon: rawIcon is String && rawIcon.trim().isNotEmpty ? rawIcon.trim() : null,
      color: rawColor is int ? rawColor : int.tryParse('$rawColor'),
    );
  }

  factory DamageType.fromFormValues(
    Map<String, dynamic> values, {
    String? id,
  }) {
    final rawDescription = values[DamageTypeFormKeys.description] as String?;
    final trimmedDescription = rawDescription?.trim();
    final rawIcon = values[DamageTypeFormKeys.icon] as String?;
    final trimmedIcon = rawIcon?.trim();
    final rawColor = values[DamageTypeFormKeys.color];
    return DamageType(
      id: id ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
      name: (values[DamageTypeFormKeys.name] as String? ?? '').trim(),
      description:
          trimmedDescription == null || trimmedDescription.isEmpty
              ? null
              : trimmedDescription,
      icon: trimmedIcon == null || trimmedIcon.isEmpty ? null : trimmedIcon,
      color: rawColor is int ? rawColor : int.tryParse('$rawColor'),
    );
  }

  Map<String, dynamic> toFormValues() => {
        DamageTypeFormKeys.name: name,
        DamageTypeFormKeys.description: description ?? '',
        DamageTypeFormKeys.icon: icon ?? '',
        DamageTypeFormKeys.color: color,
      };

  IconData displayIconData({String fallback = 'Fire Flame'}) {
    final iconName = icon?.trim();
    if (iconName != null && iconName.isNotEmpty) {
      return IconRegistry.instance.getIconData(iconName) ??
          IconRegistry.instance.getIconData(fallback) ??
          Icons.local_fire_department_outlined;
    }
    return IconRegistry.instance.getIconData(fallback) ??
        Icons.local_fire_department_outlined;
  }

  Color? get displayColor {
    if (color == null) return null;
    return Color(color!);
  }

  bool get _isTempId => RecordJsonUtils.isTempId(id);

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
    };
    if (!_isTempId) {
      map['id'] = int.tryParse(id) ?? id;
    }
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    } else if (!_isTempId) {
      map['description'] = null;
    }
    if (icon != null && icon!.isNotEmpty) {
      map['icon'] = icon;
    } else if (!_isTempId) {
      map['icon'] = null;
    }
    if (color != null) {
      map['color'] = color;
    } else if (!_isTempId) {
      map['color'] = null;
    }
    return map;
  }
}
