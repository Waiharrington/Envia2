import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/config/init.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages/tabs/receive_tab.dart';
import 'package:localsend_app/pages/tabs/send_tab.dart';
import 'package:localsend_app/pages/tabs/settings_tab.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/widget/responsive_builder.dart';
import 'package:refena_flutter/refena_flutter.dart';

enum HomeTab {
  receive(Icons.south_rounded),
  send(Icons.north_east_rounded),
  settings(Icons.tune_rounded)
  ;

  const HomeTab(this.icon);

  final IconData icon;

  String get label {
    switch (this) {
      case HomeTab.receive:
        return t.receiveTab.title;
      case HomeTab.send:
        return t.sendTab.title;
      case HomeTab.settings:
        return t.settingsTab.title;
    }
  }
}

class HomePage extends StatefulWidget {
  final HomeTab initialTab;

  /// It is important for the initializing step
  /// because the first init clears the cache
  final bool appStart;

  const HomePage({required this.initialTab, required this.appStart, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with Refena {
  bool _dragAndDropIndicator = false;

  @override
  void initState() {
    super.initState();

    ensureRef((ref) async {
      ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(widget.initialTab));
      await postInit(context, ref, widget.appStart);
    });
  }

  @override
  Widget build(BuildContext context) {
    Translations.of(context); // rebuild on locale change
    final vm = context.watch(homePageControllerProvider);

    return DropTarget(
      onDragEntered: (_) {
        setState(() {
          _dragAndDropIndicator = true;
        });
      },
      onDragExited: (_) {
        setState(() {
          _dragAndDropIndicator = false;
        });
      },
      onDragDone: (event) async {
        // the drop may contain a mix of files and directories
        final droppedDirectories = event.files.where((file) => Directory(file.path).existsSync()).toList();
        final droppedFiles = event.files.where((file) => !Directory(file.path).existsSync()).toList();

        for (final directory in droppedDirectories) {
          await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(directory.path));
        }

        if (droppedFiles.isNotEmpty) {
          await ref
              .redux(selectedSendingFilesProvider)
              .dispatchAsync(AddFilesAction(files: droppedFiles, converter: CrossFileConverters.convertXFile));
        }
        vm.changeTab(HomeTab.send);
      },
      child: ResponsiveBuilder(
        builder: (sizingInformation) {
          final isMobile = sizingInformation.isMobile;
          final colors = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: colors.surface,
            body: SafeArea(
              child: Row(
                children: [
                  if (!isMobile)
                    _BrandSidebar(
                      selectedIndex: vm.currentTab.index,
                      compact: !sizingInformation.isDesktop,
                      onSelect: (index) => vm.changeTab(HomeTab.values[index]),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _BrandTopBar(pageTitle: vm.currentTab.label, compact: isMobile),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.fromLTRB(isMobile ? 8 : 12, 2, isMobile ? 8 : 12, isMobile ? 4 : 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColorWithElevation,
                              borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
                              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.55)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                PageView(
                                  controller: vm.controller,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: const [ReceiveTab(), SendTab(), SettingsTab()],
                                ),
                                if (_dragAndDropIndicator)
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [colors.primary, colors.secondary],
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.file_download_rounded, size: 100, color: Colors.white),
                                        const SizedBox(height: 24),
                                        Text(t.sendTab.placeItems, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: isMobile
                ? _BrandBottomBar(selectedIndex: vm.currentTab.index, onSelect: (index) => vm.changeTab(HomeTab.values[index]))
                : null,
          );
        },
      ),
    );
  }
}

class _BrandSidebar extends StatelessWidget {
  final int selectedIndex;
  final bool compact;
  final ValueChanged<int> onSelect;

  const _BrandSidebar({required this.selectedIndex, required this.compact, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 82 : 236,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D6BB4), Color(0xFF5530B1), Color(0xFF351D79)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: const Color(0xFF4E36A8).withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          if (compact)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 28),
              child: Image.asset('assets/img/somosdos/s2-mark.png', width: 46, height: 46, semanticLabel: 'Somos Dos'),
            )
          else ...[
            const SizedBox(height: 4),
            Image.asset('assets/img/somosdos/wordmark-white.png', width: 184, height: 120, fit: BoxFit.contain, semanticLabel: 'Somos Dos Studio'),
            const Text(
              'ENVIA2',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 2.2, fontSize: 12),
            ),
            const SizedBox(height: 38),
          ],
          for (var i = 0; i < HomeTab.values.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SidebarDestination(tab: HomeTab.values[i], selected: selectedIndex == i, compact: compact, onTap: () => onSelect(i)),
            ),
          const Spacer(),
          if (!compact)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('SOMOS DOS STUDIO', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.3)),
            ),
        ],
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  final HomeTab tab;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _SidebarDestination({required this.tab, required this.selected, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : Colors.white.withValues(alpha: 0.76);
    return Tooltip(
      message: compact ? tab.label : '',
      child: Material(
        color: selected ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14, vertical: 12),
            child: compact
                ? Center(child: Icon(tab.icon, color: foreground, size: 23))
                : Row(
                    children: [
                      Icon(tab.icon, color: foreground, size: 21),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          tab.label,
                          style: TextStyle(color: foreground, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                        ),
                      ),
                      if (selected) const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _BrandTopBar extends StatelessWidget {
  final String pageTitle;
  final bool compact;

  const _BrandTopBar({required this.pageTitle, required this.compact});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 18 : 28, compact ? 10 : 18, compact ? 18 : 28, 10),
      child: Row(
        children: [
          Image.asset('assets/img/somosdos/s2-mark.png', width: compact ? 34 : 38, height: compact ? 34 : 38, semanticLabel: 'Somos Dos'),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Envia2', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1)),
              if (!compact) Text('SOMOS DOS STUDIO', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant, letterSpacing: 1.2)),
            ],
          ),
          const Spacer(),
          if (!compact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(99)),
              child: Text(
                pageTitle,
                style: textTheme.labelLarge?.copyWith(color: colors.onPrimaryContainer, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _BrandBottomBar({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColorWithElevation,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.55)),
          boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            for (var i = 0; i < HomeTab.values.length; i++)
              Expanded(
                child: _MobileDestination(tab: HomeTab.values[i], selected: selectedIndex == i, onTap: () => onSelect(i)),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileDestination extends StatelessWidget {
  final HomeTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _MobileDestination({required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant),
              const SizedBox(height: 3),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
