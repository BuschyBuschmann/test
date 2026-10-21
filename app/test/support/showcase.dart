// Alle Komponenten des Briefs v2 (Abschnitt 4) auf einer Tafel: Grundlage der
// Regeltests über alle Darstellungen (V2-10, V2-11, V2-12, V2-23, V2-32) und der
// Komponenten-Goldens (Welten × Thema × Hoher Kontrast).
import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/ui/components/category_card.dart';
import 'package:curaone/ui/components/choice_card.dart';
import 'package:curaone/ui/components/cura_chip.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:curaone/ui/components/date_card.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/glass_pill.dart';
import 'package:curaone/ui/components/header_card.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/manny_look_picker.dart';
import 'package:curaone/ui/components/orb_node.dart';
import 'package:curaone/ui/components/primary_pill.dart';
import 'package:curaone/ui/components/status_chip.dart';
import 'package:curaone/ui/components/world_label_chip.dart';
import 'package:flutter/material.dart';

const List<NavItem> kShowcaseNav = <NavItem>[
  NavItem(icon: Icons.route_rounded, label: 'Pfad'),
  NavItem(icon: Icons.event_available_rounded, label: 'Heute'),
  NavItem(
    icon: Icons.chat_bubble_outline_rounded,
    label: 'Chats',
    badgeCount: 2,
  ),
  NavItem(
    icon: Icons.person_outline_rounded,
    label: 'Profil',
    avatarInitials: 'JB',
  ),
];

Widget _gap() => const SizedBox(height: 12);

/// Die Tafel: Kopf-Karte, Label-Chip, Kugeln, Manny, Blase, Karten, Chips,
/// Buttons, Snackbar, Dialog, Look-Auswahl, Leiste und Manny-Knopf.
Widget v2Showcase({MannyLook look = MannyLook.brille, bool withDialog = true}) {
  return Stack(
    children: <Widget>[
      Positioned.fill(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const HeaderCard(
                title: 'Woche 5',
                subtitle: 'Phase 2 · Kreuzband',
                chips: <Widget>[
                  HeaderChip(
                    icon: Icons.local_fire_department_rounded,
                    label: '12',
                  ),
                  HeaderChip(icon: Icons.ac_unit_rounded, label: '1'),
                ],
                progress: HeaderProgress(value: 4 / 7, label: '4 von 7 Tagen'),
              ),
              _gap(),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  WorldLabelChip('Tag 12'),
                  WorldLabelChip('Ziel: Return to Sport'),
                ],
              ),
              _gap(),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: <Widget>[
                  for (final (OrbKind, OrbState) o
                      in const <(OrbKind, OrbState)>[
                        (OrbKind.day, OrbState.done),
                        (OrbKind.day, OrbState.current),
                        (OrbKind.day, OrbState.locked),
                        (OrbKind.weekGoal, OrbState.locked),
                        (OrbKind.phaseEnd, OrbState.locked),
                        (OrbKind.boss, OrbState.locked),
                      ])
                    OrbNode(
                      kind: o.$1,
                      state: o.$2,
                      semanticLabel: '${o.$1.name} ${o.$2.name}',
                      onPressed: () {},
                    ),
                ],
              ),
              _gap(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  MannyIllustration(height: 88, look: look, onWorld: true),
                  const SizedBox(width: 4),
                  Expanded(
                    child: MannyBubble(
                      text: 'Moin Jakob, los geht’s. Dein Weg beginnt hier.',
                      onClose: () {},
                    ),
                  ),
                ],
              ),
              _gap(),
              const GlassCard(child: Text('Karte E1: card 92 %, kein Blur.')),
              _gap(),
              CategoryCard(
                kind: CategoryKind.physio,
                title: 'Physio',
                semanticLabel: 'Physio 17:00',
                meta: 'Köln-Ehrenfeld',
                time: '17:00',
                actions: <Widget>[
                  CuraChip(
                    label: 'Tauschen',
                    icon: Icons.swap_horiz_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
              _gap(),
              ChoiceCard(
                title: 'Kreuzbandriss',
                selected: true,
                onPressed: () {},
              ),
              _gap(),
              ChoiceCard(
                title: 'Bänderriss',
                selected: false,
                onPressed: () {},
              ),
              _gap(),
              DateCard(valueText: '3. September 2026', onPressed: () {}),
              _gap(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  const StatusChip(label: 'Erledigt', kind: StatusKind.success),
                  const StatusChip(label: 'Schmerz', kind: StatusKind.warn),
                  const StatusChip(label: 'Zuhause'),
                  StatusChip(label: 'Praxis', selected: true, onPressed: () {}),
                ],
              ),
              _gap(),
              PrimaryPill(
                label: 'Training starten',
                icon: Icons.play_arrow_rounded,
                onPressed: () {},
              ),
              _gap(),
              const PrimaryPill(label: 'Heute erledigt', onPressed: null),
              _gap(),
              GlassPill(label: 'Abbrechen', onPressed: () {}),
              _gap(),
              CuraSnackbar(
                text: 'Eingetragen.',
                actionLabel: 'Rückgängig',
                onAction: () {},
              ),
              _gap(),
              MannyLookPicker(value: look, onChanged: (_) {}),
              if (withDialog) ...<Widget>[
                _gap(),
                CuraDialog(
                  icon: Icons.delete_outline_rounded,
                  title: 'Alles löschen?',
                  message: 'Name, Pfad und Streak werden gelöscht.',
                  actions: <Widget>[
                    GlassPill(label: 'Abbrechen', onPressed: () {}),
                    GlassPill(label: 'Ja, alles löschen', onPressed: () {}),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: FloatingNav(
          items: kShowcaseNav,
          currentIndex: 1,
          onSelected: (_) {},
        ),
      ),
      Positioned(
        right: 18,
        bottom: _kNavOccupied + 16,
        child: MannyButton(onPressed: () {}),
      ),
    ],
  );
}

/// Höhe der Leiste samt unterem Rand (72 + 24) ohne Safe Area.
const double _kNavOccupied = 96;
