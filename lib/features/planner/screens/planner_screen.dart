import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../models/routine_block.dart';
import '../providers/planner_provider.dart';
import '../services/planner_engine.dart';
import '../widgets/add_block_sheet.dart';
import '../widgets/daily_prayer_summary.dart';
import '../widgets/ramadan_meal_plan.dart';
import '../widgets/weekly_calendar_view.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermissions();
    });
  }

  Future<void> _openAddBlock() async {
    final block = await AddBlockSheet.show(context);
    if (block == null || !mounted) return;
    await ref.read(plannerProvider.notifier).addBlock(block);
  }

  Future<void> _openEditBlock(RoutineBlock block) async {
    final updated = await AddBlockSheet.show(context, existingBlock: block);
    if (updated == null || !mounted) return;
    await ref.read(plannerProvider.notifier).addBlock(updated);
  }

  @override
  Widget build(BuildContext context) {
    final plannerState = ref.watch(plannerProvider);
    final todayIndex = weekdayIndex(DateTime.now());
    final blocksToday =
        PlannerEngine.blocksForDay(plannerState.blocks, todayIndex);
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayLabel = dayLabels[todayIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Day Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add block',
            onPressed: _openAddBlock,
          ),
        ],
      ),
      body: plannerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(plannerProvider.notifier);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (plannerState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        plannerState.error!,
                        style: const TextStyle(color: AppColors.errorRed),
                      ),
                    ),
                  const RamadanMealPlan(),
                  Text(
                    'Weekly Schedule',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Colored blocks are your routines. Dots mark today\'s prayers.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (plannerState.blocks.isNotEmpty && blocksToday.isEmpty)
                    Card(
                      color: AppColors.accentGold.withValues(alpha: 0.12),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.accentGold,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'None of your blocks run on $todayLabel. '
                                'Edit a block and enable today, or add a new one.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  WeeklyCalendarView(
                    blocks: plannerState.blocks,
                    todayContexts: plannerState.todayContexts,
                    onBlockTap: _openEditBlock,
                  ),
                  const SizedBox(height: 24),
                  DailyPrayerSummary(contexts: plannerState.todayContexts),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBlock,
        icon: const Icon(Icons.add),
        label: const Text('Add Block'),
      ),
    );
  }
}
