import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rpg_companion/features/player/spells/widgets/mtg/mtg_card_layout.dart';
import 'package:rpg_companion/features/player/spells/widgets/mtg/mtg_card_markdown_fit.dart';
import 'package:rpg_companion/features/player/spells/widgets/mtg/mtg_card_rules_scale.dart';
import 'package:rpg_companion/features/player/spells/widgets/mtg/spell_school_icons.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_data.dart';

Color _lighterVariant(Color base, {double amount = 0.08}) {
  final hsl = HSLColor.fromColor(base);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

Color _darkerVariant(Color base, {double amount = 0.08}) {
  final hsl = HSLColor.fromColor(base);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

double _bandIconSize(double maxFontSize) =>
    (maxFontSize * 14 / kMtgCardRulesMaxFontSize).clamp(13.0, 19.0);

class SpellCard extends StatelessWidget {
  const SpellCard({
    super.key,
    required this.data,
    required this.bodyMarkdown,
    this.showMechanics = true,
    this.continuationIndex,
    this.continuationTotal,
    this.rulesScaleController,
    this.cardScale = 1.0,
    this.padding = EdgeInsets.zero,
    this.maxFontSize = kMtgCardRulesMaxFontSize,
  });

  final SpellCardData data;
  final String bodyMarkdown;
  final bool showMechanics;
  final int? continuationIndex;
  final int? continuationTotal;
  final MtgCardRulesScaleController? rulesScaleController;
  final double cardScale;
  final EdgeInsetsGeometry padding;
  final double maxFontSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rulesContent = bodyMarkdown.trim();
    final hasRules = rulesContent.isNotEmpty;

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final baseSize = computeMtgCardLogicalSize(context, constraints);
          final size = Size(
            baseSize.width * cardScale,
            baseSize.height * cardScale,
          );

          return Align(
            alignment: Alignment.topCenter,
            widthFactor: 1,
            heightFactor: 1,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kMtgCardBorderRadius),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SpellHeaderBand(
                      data: data,
                      colors: colors,
                      maxFontSize: maxFontSize,
                      continuationIndex: continuationIndex,
                      continuationTotal: continuationTotal,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerLowest,
                                borderRadius: data.hasFooter
                                    ? BorderRadius.zero
                                    : const BorderRadius.only(
                                        bottomLeft: Radius.circular(
                                          kMtgCardBorderRadius,
                                        ),
                                        bottomRight: Radius.circular(
                                          kMtgCardBorderRadius,
                                        ),
                                      ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  IgnorePointer(
                                    child: Center(
                                      child: Icon(
                                        spellSchoolIcon(data.spell.school),
                                        size: size.shortestSide * 0.58,
                                        color: colors.primary.withValues(
                                          alpha: kItemCardWatermarkIconAlpha,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (showMechanics)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            8,
                                            8,
                                            8,
                                            0,
                                          ),
                                          child: _SpellMechanicsSection(
                                            data: data,
                                            colors: colors,
                                            maxFontSize: maxFontSize,
                                          ),
                                        ),
                                      if (hasRules)
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              10,
                                              8,
                                              10,
                                              10,
                                            ),
                                            child: MtgCardMarkdownFit(
                                              source: rulesContent,
                                              onSurface: colors.onSurface,
                                              maxFontSize: maxFontSize,
                                              scaleController:
                                                  rulesScaleController,
                                            ),
                                          ),
                                        )
                                      else
                                        const Spacer(),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (data.hasFooter)
                            _SpellFooterBand(
                              classesText: data.classesLine,
                              colors: colors,
                              maxFontSize: maxFontSize,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpellHeaderBand extends StatelessWidget {
  const _SpellHeaderBand({
    required this.data,
    required this.colors,
    required this.maxFontSize,
    this.continuationIndex,
    this.continuationTotal,
  });

  final SpellCardData data;
  final ColorScheme colors;
  final double maxFontSize;
  final int? continuationIndex;
  final int? continuationTotal;

  @override
  Widget build(BuildContext context) {
    final titleBandColor = _darkerVariant(colors.primaryContainer, amount: 0.12);
    final subheaderBandColor = colors.primaryContainer;
    final titleFontSize = maxFontSize * kMtgCardTitleToRulesMaxFontScale;
    final summaryFontSize = maxFontSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: titleBandColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(kMtgCardBorderRadius),
              topRight: Radius.circular(kMtgCardBorderRadius),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
          child: Text(
            data.title.toUpperCase(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: titleFontSize,
              letterSpacing: 0.75,
              height: 1.05,
            ),
          ),
        ),
        Container(
          color: subheaderBandColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.wandMagicSparkles,
                size: _bandIconSize(maxFontSize),
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  data.summaryLine(
                    continuationIndex: continuationIndex,
                    continuationTotal: continuationTotal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: summaryFontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                  strutStyle: StrutStyle(
                    fontSize: summaryFontSize,
                    height: 1.0,
                    leading: 0,
                    fontWeight: FontWeight.w600,
                    forceStrutHeight: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpellMechanicsSection extends StatelessWidget {
  const _SpellMechanicsSection({
    required this.data,
    required this.colors,
    required this.maxFontSize,
  });

  final SpellCardData data;
  final ColorScheme colors;
  final double maxFontSize;

  @override
  Widget build(BuildContext context) {
    final emphasizedRowsColor = _lighterVariant(colors.surface, amount: 0.06);
    final emphasizedBlockColor =
        _lighterVariant(colors.surfaceContainerHigh, amount: 0.07);
    final emphasizedRowValueColor =
        _lighterVariant(colors.surfaceContainerLowest, amount: 0.1);
    final emphasizedDividerColor =
        _darkerVariant(emphasizedBlockColor, amount: 0.015);

    final rows = <(String, String)>[
      ('Casting', data.castingAndRangeLine),
      ('Duration', data.durationLine),
      ('Components', data.componentsLine),
    ];

    return _SpellMechanicsRowsBlock(
      rows: rows,
      colors: colors,
      maxFontSize: maxFontSize,
      backgroundColor: emphasizedRowsColor,
      labelBackgroundColor: emphasizedBlockColor,
      valueBackgroundColor: emphasizedRowValueColor,
      dividerColor: emphasizedDividerColor,
    );
  }
}

class _SpellMechanicsRowsBlock extends StatelessWidget {
  const _SpellMechanicsRowsBlock({
    required this.rows,
    required this.colors,
    required this.maxFontSize,
    this.backgroundColor,
    this.labelBackgroundColor,
    this.valueBackgroundColor,
    this.dividerColor,
  });

  final List<(String, String)> rows;
  final ColorScheme colors;
  final double maxFontSize;
  final Color? backgroundColor;
  final Color? labelBackgroundColor;
  final Color? valueBackgroundColor;
  final Color? dividerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor ?? colors.surface,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _SpellLabeledValueRow(
              label: rows[i].$1,
              value: rows[i].$2,
              colors: colors,
              maxFontSize: maxFontSize,
              labelBackgroundColor: labelBackgroundColor,
              valueBackgroundColor: valueBackgroundColor,
            ),
            if (i != rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: dividerColor ?? colors.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _SpellLabeledValueRow extends StatelessWidget {
  const _SpellLabeledValueRow({
    required this.label,
    required this.value,
    required this.colors,
    required this.maxFontSize,
    this.labelBackgroundColor,
    this.valueBackgroundColor,
  });

  final String label;
  final String value;
  final ColorScheme colors;
  final double maxFontSize;
  final Color? labelBackgroundColor;
  final Color? valueBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final lb = labelBackgroundColor ?? colors.surfaceContainerHighest;
    final vb = valueBackgroundColor ?? colors.surface;
    final labelFontSize = (maxFontSize * 0.92).clamp(10.5, 14.0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 38,
            child: Container(
              color: lb,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              alignment: Alignment.centerRight,
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 62,
            child: Container(
              color: vb,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: maxFontSize,
                  color: colors.onSurface,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpellFooterBand extends StatelessWidget {
  const _SpellFooterBand({
    required this.classesText,
    required this.colors,
    required this.maxFontSize,
  });

  final String classesText;
  final ColorScheme colors;
  final double maxFontSize;

  @override
  Widget build(BuildContext context) {
    final footerColor = _darkerVariant(colors.primaryContainer, amount: 0.12);

    return Material(
      color: footerColor,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(kMtgCardBorderRadius),
        bottomRight: Radius.circular(kMtgCardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.graduationCap,
              size: _bandIconSize(maxFontSize),
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                classesText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: maxFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                strutStyle: StrutStyle(
                  fontSize: maxFontSize,
                  height: 1.2,
                  leading: 0,
                  fontWeight: FontWeight.w600,
                  forceStrutHeight: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
