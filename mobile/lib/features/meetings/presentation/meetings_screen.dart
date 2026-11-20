import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/amber_header_scaffold.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/states/empty_state.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/offline_banner.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../community/presentation/providers/community_providers.dart';
import '../../learning/presentation/learning_providers.dart';
import '../../learning/presentation/widgets/viewer_parts.dart';
import '../domain/meeting.dart';
import 'meeting_providers.dart';

/// How often the check-in button re-checks the clock.
const _clockTick = Duration(minutes: 1);

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// "5:00 PM".
String formatMeetingTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minutes = d.minute.toString().padLeft(2, '0');
  return '$hour:$minutes ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "Tuesday 17 November 2026".
String formatMeetingDay(DateTime d) =>
    '${_weekdayNames[d.weekday - 1]} ${formatLongDate(d)}';

/// Screen 51: Meetings (`/community/:id/meetings`). Back goes to Info.
class MeetingsScreen extends ConsumerStatefulWidget {
  const MeetingsScreen({super.key, required this.communityId});

  final String communityId;

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  Timer? _tick;
  var _rsvpBusy = false;
  var _checkInBusy = false;

  @override
  void initState() {
    super.initState();
    // The check-in window opens and closes with time; re-evaluate it.
    _tick = Timer.periodic(_clockTick, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  MeetingScheduleController get _controller =>
      ref.read(meetingScheduleProvider(widget.communityId).notifier);

  Future<void> _toggleGoing(Meeting m) async {
    if (_rsvpBusy) return;
    setState(() => _rsvpBusy = true);
    try {
      await _controller.setGoing(m, !m.going);
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _rsvpBusy = false);
    }
  }

  Future<void> _checkIn(Meeting m, String communityName) async {
    if (_checkInBusy) return;
    setState(() => _checkInBusy = true);
    try {
      final badges = await _controller.checkIn(
        m,
        label: 'Attended the $communityName meeting',
      );
      if (!mounted) return;
      if (badges.isNotEmpty) {
        // The Badge earned screen is the confirmation; a snackbar would
        // cover its buttons.
        ref.read(badgeQueueProvider.notifier).addAll(badges);
        showQueuedBadges(context, ref);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('You are checked in. See you soon!')),
          );
      }
    } on CheckInClosed {
      if (mounted) showErrorSnack(context, 'Check-in is closed right now.');
    } on AlreadyCheckedIn {
      if (mounted) showErrorSnack(context, 'You have already checked in.');
    } catch (_) {
      if (mounted) showErrorSnack(context);
    } finally {
      if (mounted) setState(() => _checkInBusy = false);
    }
  }

  void _addToCalendar() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Adding to your calendar is coming soon.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.communityId;
    final community = ref.watch(communityByIdProvider(id)).valueOrNull;
    final schedule = ref.watch(meetingScheduleProvider(id));
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final now = ref.watch(meetingClockProvider)();
    final window = ref.watch(meetingRepositoryProvider).window;

    return AmberHeaderScaffold(
      title: 'Meetings',
      subtitle: community?.name,
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/community/$id/info'),
      body: schedule.when(
        loading: () => const Skeleton(showHeader: false, cardCount: 2),
        error: (_, _) => ErrorView(
          onRetry: () => ref.invalidate(meetingScheduleProvider(id)),
        ),
        data: (s) {
          final next = s.next;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const OfflineBanner(),
              if (next == null)
                const EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'No meetings scheduled',
                  body: 'Your super-mentor has not set a meeting time yet.',
                )
              else ...[
                _Card(
                  title: 'Next meeting',
                  children: [
                    Text(
                      '${formatMeetingDay(next.startsAt)} · '
                      '${formatMeetingTime(next.startsAt)}',
                      style: AppTextStyles.cardTitle,
                    ),
                    if (next.room.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(next.room, style: AppTextStyles.body),
                    ],
                    const SizedBox(height: 14),
                    Semantics(
                      toggled: next.going,
                      child: next.going
                          ? AppPrimaryButton(
                              label: 'I am going',
                              height: 48,
                              isLoading: _rsvpBusy,
                              onPressed: online && !_rsvpBusy
                                  ? () => _toggleGoing(next)
                                  : null,
                            )
                          : AppSecondaryButton(
                              label: 'I am going',
                              height: 48,
                              isLoading: _rsvpBusy,
                              onPressed: online && !_rsvpBusy
                                  ? () => _toggleGoing(next)
                                  : null,
                            ),
                    ),
                    const SizedBox(height: 10),
                    AppSecondaryButton(
                      label: 'Add to calendar',
                      icon: Icons.event_available_outlined,
                      height: 48,
                      onPressed: _addToCalendar,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Card(
                  title: 'At the meeting?',
                  children: [
                    Text(
                      'Confirm you are here. Your attendance is recorded in '
                      'your activity.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 14),
                    AppPrimaryButton(
                      label: next.attended ? 'You are checked in' : 'I am here',
                      height: 48,
                      isLoading: _checkInBusy,
                      onPressed:
                          online &&
                              !next.attended &&
                              !_checkInBusy &&
                              window.isOpen(next, now)
                          ? () => _checkIn(next, community?.name ?? 'community')
                          : null,
                    ),
                    if (!next.attended && !window.isOpen(next, now)) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Check-in opens ${window.opensBefore.inMinutes} '
                        'minutes before the meeting starts.',
                        style: AppTextStyles.fieldLabel.copyWith(
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (s.past.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Past meetings', style: AppTextStyles.sectionHeading),
                const SizedBox(height: 8),
                for (final m in s.past) _PastRow(m),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.cardSmall),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.eyebrow),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _PastRow extends StatelessWidget {
  const _PastRow(this.m);

  final Meeting m;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.cardSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatMeetingDay(m.startsAt),
              style: AppTextStyles.bodyMedium,
            ),
          ),
          AppChip(
            label: m.attended ? 'Attended' : 'Missed',
            icon: m.attended ? Icons.check_rounded : Icons.close_rounded,
            backgroundColor: m.attended
                ? AppColors.primarySoft
                : AppColors.cream,
          ),
        ],
      ),
    );
  }
}
