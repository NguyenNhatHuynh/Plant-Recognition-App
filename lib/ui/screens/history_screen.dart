import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recognition_record.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../widgets/plant_image.dart';
import 'plant_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _pageBackground = Color(0xFFF6F8F4);

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>().revision;
    final dbService = context.read<DatabaseService>();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: FutureBuilder<List<RecognitionRecord>>(
          future: dbService.getHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final records = snapshot.data ?? const <RecognitionRecord>[];
            final sections = _buildSections(records);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      const _HistoryTopBar(),
                      const SizedBox(height: 22),
                      Text(
                        'Lịch sử nhận diện',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF1D2A22),
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              letterSpacing: -0.35,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Xem lại các loài cây bạn đã khám phá.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF68746D),
                              fontSize: 13.8,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 18),
                    ]),
                  ),
                ),
                if (records.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyHistoryState(),
                  )
                else
                  ..._buildSectionSlivers(context, sections),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<_HistorySection> _buildSections(List<RecognitionRecord> records) {
  final now = DateTime.now();
  final sections = <_HistorySection>[];

  for (final record in records) {
    final label = _sectionLabel(record.capturedAt, now);
    if (sections.isEmpty || sections.last.title != label) {
      sections.add(_HistorySection(title: label, records: <RecognitionRecord>[]));
    }
    sections.last.records.add(record);
  }

  return sections;
}

String _sectionLabel(DateTime dateTime, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diff = today.difference(target).inDays;

  if (diff == 0) {
    return 'HÔM NAY';
  }
  if (diff == 1) {
    return 'HÔM QUA';
  }
  if (dateTime.year == now.year) {
    return 'THÁNG ${dateTime.month}';
  }
  return 'THÁNG ${dateTime.month}/${dateTime.year}';
}

List<Widget> _buildSectionSlivers(
  BuildContext context,
  List<_HistorySection> sections,
) {
  return [
    for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) ...[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            sectionIndex == 0 ? 0 : 12,
            16,
            14,
          ),
          child: _HistorySectionLabel(title: sections[sectionIndex].title),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final record = sections[sectionIndex].records[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _HistoryRecordCard(record: record),
              );
            },
            childCount: sections[sectionIndex].records.length,
          ),
        ),
      ),
    ],
  ];
}

class _HistorySection {
  final String title;
  final List<RecognitionRecord> records;

  _HistorySection({
    required this.title,
    required this.records,
  });
}

class _HistoryTopBar extends StatelessWidget {
  const _HistoryTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F2EA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.spa_rounded,
            color: Color(0xFF1C5A45),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Nhận Diện Cây Cối',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1C5A45),
                  fontWeight: FontWeight.w500,
                  fontSize: 14.5,
                ),
          ),
        ),
        IconButton(
          onPressed: () => Scaffold.maybeOf(context)?.openEndDrawer(),
          icon: const Icon(
            Icons.menu_rounded,
            color: Color(0xFF36433C),
          ),
          tooltip: 'Mở menu',
        ),
      ],
    );
  }
}

class _HistorySectionLabel extends StatelessWidget {
  final String title;

  const _HistorySectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            thickness: 1.1,
            color: Color(0xFFD9E1DB),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF496554),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
          ),
        ),
        const Expanded(
          child: Divider(
            thickness: 1.1,
            color: Color(0xFFD9E1DB),
          ),
        ),
      ],
    );
  }
}

class _HistoryRecordCard extends StatelessWidget {
  final RecognitionRecord record;

  const _HistoryRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final plant = record.plant;
    final imagePlant = plant.copyWith(imagePath: record.imagePath);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PlantDetailScreen.route(plant),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFEEF2EE)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 82,
                  height: 82,
                  child: PlantImage(
                    plant: imagePlant,
                    height: 82,
                    width: 82,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        plant.commonName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF1E2B23),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  height: 1.14,
                                ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        plant.scientificName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF5E6B64),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              height: 1.22,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: Color(0xFF7B8680),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _formatDate(record.capturedAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF6D7872),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF165C43),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute - $day/$month/$year';
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2EA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 34,
                color: Color(0xFF1C5A45),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Chưa có lịch sử nhận diện',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF213028),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Khi bạn nhận diện cây, lịch sử sẽ xuất hiện ở đây để xem lại nhanh.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF68746D),
                    height: 1.55,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
