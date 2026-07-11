import 'package:flutter/material.dart';
import 'package:rpg_companion/core/markdown/markdown_wiki_display.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_data.dart';
import 'package:rpg_companion/features/player/spells/widgets/spell_card_layout.dart';

class SpellCardTheme {
  const SpellCardTheme({
    required this.cardBackground,
    required this.headerBackground,
    required this.headerText,
    required this.subheaderBackground,
    required this.subheaderText,
    required this.accent,
    required this.secondaryAccent,
    required this.infoLabelBackground,
    required this.infoValueBackground,
    required this.infoRowDivider,
    required this.infoLabelText,
    required this.infoValueText,
    required this.footerBackground,
    required this.footerText,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.border,
    required this.watermark,
    required this.bodyTextStyle,
    required this.linkColor,
  });

  final Color cardBackground;
  final Color headerBackground;
  final Color headerText;
  final Color subheaderBackground;
  final Color subheaderText;
  final Color accent;
  final Color secondaryAccent;
  final Color infoLabelBackground;
  final Color infoValueBackground;
  final Color infoRowDivider;
  final Color infoLabelText;
  final Color infoValueText;
  final Color footerBackground;
  final Color footerText;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color border;
  final Color watermark;
  final TextStyle bodyTextStyle;
  final Color linkColor;

  factory SpellCardTheme.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SpellCardTheme(
      cardBackground: scheme.surfaceContainerLow,
      headerBackground: scheme.primaryContainer,
      headerText: scheme.onPrimaryContainer,
      subheaderBackground: scheme.secondaryContainer,
      subheaderText: scheme.onSecondaryContainer,
      accent: scheme.primary,
      secondaryAccent: scheme.secondary,
      infoLabelBackground: Color.alphaBlend(
        Colors.black.withValues(alpha: 0.35),
        scheme.primary,
      ),
      infoValueBackground: Color.alphaBlend(
        Colors.black.withValues(alpha: 0.55),
        scheme.primary,
      ),
      infoRowDivider: Colors.black.withValues(alpha: 0.45),
      infoLabelText: scheme.onPrimary,
      infoValueText: scheme.onPrimary,
      footerBackground: scheme.secondaryContainer,
      footerText: scheme.onSecondaryContainer,
      textPrimary: scheme.onSurface,
      textSecondary: scheme.onSurfaceVariant,
      divider: scheme.outlineVariant,
      border: scheme.primary.withValues(alpha: 0.55),
      watermark: scheme.secondary.withValues(alpha: 0.14),
      linkColor: scheme.primary,
      bodyTextStyle: textTheme.bodySmall?.copyWith(
            color: scheme.onSurface,
            height: 1.4,
          ) ??
          TextStyle(color: scheme.onSurface, fontSize: 12, height: 1.4),
    );
  }
}

class SpellCard extends StatelessWidget {
  const SpellCard({
    super.key,
    required this.data,
    required this.bodyMarkdown,
    this.showInfoBlock = true,
  });

  final SpellCardData data;
  final String bodyMarkdown;
  final bool showInfoBlock;

  @override
  Widget build(BuildContext context) {
    final cardTheme = SpellCardTheme.of(context);

    return Center(
      child: SizedBox(
        width: SpellCardLayout.width,
        height: SpellCardLayout.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cardTheme.cardBackground,
            borderRadius: BorderRadius.circular(SpellCardLayout.borderRadius),
            border: Border.all(color: cardTheme.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: cardTheme.accent.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SpellCardLayout.borderRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(title: data.title, theme: cardTheme),
                _Subheader(line: data.levelSchoolLine, theme: cardTheme),
                if (showInfoBlock) _InfoBlock(data: data, theme: cardTheme),
                Expanded(
                  child: _Body(
                    source: bodyMarkdown,
                    theme: cardTheme,
                  ),
                ),
                _Footer(classesLine: data.classesLine, theme: cardTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.theme});

  final String title;
  final SpellCardTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SpellCardLayout.headerHeight,
      decoration: BoxDecoration(
        color: theme.headerBackground,
        border: Border(
          bottom: BorderSide(
            color: theme.accent.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: theme.headerText,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}

class _Subheader extends StatelessWidget {
  const _Subheader({required this.line, required this.theme});

  final String line;
  final SpellCardTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SpellCardLayout.subheaderHeight,
      color: theme.subheaderBackground,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 14,
            color: theme.accent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: theme.subheaderText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.data, required this.theme});

  static const _cornerRadius = 6.0;

  final SpellCardData data;
  final SpellCardTheme theme;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Casting', data.castingLine),
      ('Duration', data.durationLine),
      ('Components', data.componentsLine),
    ];

    return ColoredBox(
      color: theme.cardBackground,
      child: SizedBox(
        height: SpellCardLayout.infoBlockHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SpellCardLayout.infoBlockHorizontalPadding,
            4,
            SpellCardLayout.infoBlockHorizontalPadding,
            4,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_cornerRadius),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.infoRowDivider,
                    ),
                  Expanded(
                    child: _InfoRow(
                      label: rows[i].$1,
                      value: rows[i].$2,
                      theme: theme,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final SpellCardTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 1,
          child: ColoredBox(
            color: theme.infoLabelBackground,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: theme.infoLabelText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ColoredBox(
            color: theme.infoValueBackground,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: theme.infoValueText,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.source, required this.theme});

  final String source;
  final SpellCardTheme theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.cardBackground,
            Color.alphaBlend(
              theme.accent.withValues(alpha: 0.06),
              theme.cardBackground,
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SpellCardLayout.bodyPadding,
          2,
          SpellCardLayout.bodyPadding,
          4,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.nightlight_round,
                  size: 96,
                  color: theme.watermark,
                ),
              ),
            ),
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: theme.linkColor,
                    ),
                textTheme: Theme.of(context).textTheme.apply(
                      bodyColor: theme.textPrimary,
                      displayColor: theme.textPrimary,
                    ),
              ),
              child: DefaultTextStyle(
                style: theme.bodyTextStyle,
                child: ClipRect(
                  child: source.trim().isEmpty
                      ? const SizedBox.expand()
                      : MarkdownWikiDisplay(source: source),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.classesLine, required this.theme});

  final String classesLine;
  final SpellCardTheme theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SpellCardLayout.footerHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: theme.secondaryAccent.withValues(alpha: 0.45),
          ),
          Expanded(
            child: ColoredBox(
              color: theme.footerBackground,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: theme.accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        classesLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: theme.footerText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
