import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../domain/meter.dart';

class SearchDetailsScreen extends ConsumerWidget {
  const SearchDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metersAsync = ref.watch(searchedMetersProvider);
    final filters = ref.watch(searchFilterProvider);
    final filterNotifier = ref.read(searchFilterProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Record Search'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FIND INSTALLATIONS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textLight, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: TextField(
                    onChanged: filterNotifier.updateQuery,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Enter Phone, Meter ID or Geocode',
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters / Chips
          Container(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                _buildFilterChip('All Status', filters.status == SearchStatus.all, () => filterNotifier.updateStatus(SearchStatus.all)),
                _buildFilterChip('Active', filters.status == SearchStatus.active, () => filterNotifier.updateStatus(SearchStatus.active)),
                _buildFilterChip('Pending', filters.status == SearchStatus.pending, () => filterNotifier.updateStatus(SearchStatus.pending)),
                _buildFilterChip('Faulty', filters.status == SearchStatus.faulty, () => filterNotifier.updateStatus(SearchStatus.faulty)),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: metersAsync.when(
              data: (meters) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: meters.length,
                itemBuilder: (context, index) => _buildResultItem(context, meters[index]),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.primary : AppTheme.borderLight),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppTheme.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, Meter meter) {
    Color statusColor;
    switch (meter.status) {
      case MeterStatus.active:
        statusColor = Colors.green;
        break;
      case MeterStatus.pending:
        statusColor = Colors.orange;
        break;
      case MeterStatus.faulty:
        statusColor = Colors.red;
        break;
    }

    return InkWell(
      onTap: () => GoRouter.of(context).push('/details/${meter.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderLight.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.bolt, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(meter.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meter.status.name.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  Text(meter.customerName, style: const TextStyle(fontSize: 14, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textLight),
                      const SizedBox(width: 4),
                      Text(meter.address, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
