import 'package:flutter/material.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'runtime_draft.dart';

/// Menu type selector (bottom nav / hamburger).
///
/// Lives in the Basics panel of the owner "create app" request screen.
class MenuTypePills extends StatelessWidget {
  final MenuType value;
  final ValueChanged<MenuType> onChanged;
  final bool enabled;

  const MenuTypePills({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    Widget pill({
      required bool selected,
      required String text,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: enabled ? onTap : null,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: selected ? cs.primary.withOpacity(.14) : cs.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    selected ? cs.primary.withOpacity(.45) : cs.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(
          selected: value == MenuType.bottom,
          text: l10n.runtime_menu_bottom,
          icon: Icons.view_agenda_rounded,
          onTap: () => onChanged(MenuType.bottom),
        ),
        const SizedBox(width: 10),
        pill(
          selected: value == MenuType.hamburger,
          text: l10n.runtime_menu_hamburger,
          icon: Icons.menu_rounded,
          onTap: () => onChanged(MenuType.hamburger),
        ),
      ],
    );
  }
}
