import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'community_header_chrome.dart';

/// A community section: its menu label, icon and route segment
/// (`/community/:id/<path>`). The first six are the community shell's tabs,
/// in branch order; Meetings is a page of its own.
class CommunitySection {
  const CommunitySection(this.label, this.icon, this.path, {this.tab = true});

  final String label;
  final IconData icon;
  final String path;

  /// One of the shell's tabs (switched in place) rather than a pushed page.
  final bool tab;
}

const communitySections = [
  CommunitySection('Feed', Icons.dynamic_feed_outlined, 'feed'),
  CommunitySection('Prayer wall', Icons.volunteer_activism_outlined, 'prayer'),
  CommunitySection('Testimonies', Icons.auto_awesome_outlined, 'testimonies'),
  CommunitySection('Pathways', Icons.route_outlined, 'pathways'),
  CommunitySection('Resources', Icons.menu_book_outlined, 'resources'),
  CommunitySection('Info & members', Icons.groups_outlined, 'info'),
  CommunitySection('Meetings', Icons.event_outlined, 'meetings', tab: false),
];

/// The tab sections, in the shell's branch order.
List<CommunitySection> get communityTabSections =>
    communitySections.where((s) => s.tab).toList();

/// The "⋯" menu: the General community (feed, prayer wall, testimonies,
/// Learn), then (when the student has a specific community) each of its
/// sections. [activePath] is 'general', 'general/prayer', ..., or a
/// community section path.
/// [goTab] switches a shell tab in place when given; otherwise sections are
/// opened by route.
List<SectionMenuItem> communityMenuItems(
  BuildContext context, {
  required String? communityId,
  required String activePath,
  void Function(int tabIndex)? goTab,
}) {
  final tabs = communityTabSections;
  return [
    SectionMenuItem(
      label: 'General',
      icon: Icons.public_rounded,
      active: activePath == 'general',
      onSelected: () => context.go('/general-feed'),
    ),
    SectionMenuItem(
      label: 'General prayer wall',
      icon: Icons.volunteer_activism_outlined,
      active: activePath == 'general/prayer',
      onSelected: () => context.go('/general-feed/prayer'),
    ),
    SectionMenuItem(
      label: 'General testimonies',
      icon: Icons.auto_awesome_outlined,
      active: activePath == 'general/testimonies',
      onSelected: () => context.go('/general-feed/testimonies'),
    ),
    SectionMenuItem(
      label: 'Learn',
      icon: Icons.school_outlined,
      active: activePath == 'general/resources',
      onSelected: () => context.push('/general-feed/resources'),
    ),
    if (communityId == null)
      SectionMenuItem(
        label: 'Find a specific community',
        icon: Icons.travel_explore_rounded,
        dividerBefore: true,
        onSelected: () => context.go('/communities'),
      )
    else
      for (final (i, s) in communitySections.indexed)
        SectionMenuItem(
          label: s.label,
          icon: s.icon,
          active: activePath == s.path,
          dividerBefore: i == 0,
          onSelected: () {
            final index = tabs.indexOf(s);
            if (s.tab && goTab != null) {
              goTab(index);
            } else if (s.tab) {
              context.go('/community/$communityId/${s.path}');
            } else {
              context.push('/community/$communityId/${s.path}');
            }
          },
        ),
  ];
}
