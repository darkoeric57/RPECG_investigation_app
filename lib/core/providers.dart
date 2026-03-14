import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/meters/data/meter_repository.dart';
import '../features/dashboard/data/investigator_repository.dart';
import '../features/meters/domain/meter.dart';
import '../features/dashboard/domain/investigator.dart';
import 'package:flutter/material.dart';

// Theme Logic
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Repositories
final meterRepositoryProvider = Provider<MeterRepository>((ref) => HiveMeterRepository());
final investigatorRepositoryProvider = Provider<InvestigatorRepository>((ref) => HiveInvestigatorRepository());

// Data Streams / Futures
final investigatorsProvider = FutureProvider<List<Investigator>>((ref) async {
  final repo = ref.watch(investigatorRepositoryProvider);
  return repo.getInvestigators();
});

final metersProvider = FutureProvider<List<Meter>>((ref) async {
  final repo = ref.watch(meterRepositoryProvider);
  return repo.getMeters();
});

// Search Logic
enum SearchStatus { all, active, pending, faulty }

class SearchFilters {
  final String query;
  final SearchStatus status;

  SearchFilters({this.query = '', this.status = SearchStatus.all});

  SearchFilters copyWith({String? query, SearchStatus? status}) {
    return SearchFilters(
      query: query ?? this.query,
      status: status ?? this.status,
    );
  }
}

class SearchFilterNotifier extends StateNotifier<SearchFilters> {
  SearchFilterNotifier() : super(SearchFilters());

  void updateQuery(String query) => state = state.copyWith(query: query);
  void updateStatus(SearchStatus status) => state = state.copyWith(status: status);
}

final searchFilterProvider = StateNotifierProvider<SearchFilterNotifier, SearchFilters>((ref) => SearchFilterNotifier());

final searchedMetersProvider = FutureProvider<List<Meter>>((ref) async {
  final filters = ref.watch(searchFilterProvider);
  final repo = ref.watch(meterRepositoryProvider);
  
  final allMeters = await repo.getMeters();
  
  return allMeters.where((m) {
    final matchesQuery = m.id.toLowerCase().contains(filters.query.toLowerCase()) || 
                       m.customerName.toLowerCase().contains(filters.query.toLowerCase()) ||
                       m.geocode.toLowerCase().contains(filters.query.toLowerCase());
    
    final matchesStatus = filters.status == SearchStatus.all || 
                        m.status.name.toLowerCase() == filters.status.name.toLowerCase();
    
    return matchesQuery && matchesStatus;
  }).toList();
});
