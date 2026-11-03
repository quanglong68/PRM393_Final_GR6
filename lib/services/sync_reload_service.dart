import '../models/app_state.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../viewmodels/roadmap_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';

class SyncReloadResult {
  const SyncReloadResult.success() : errorMessage = null;

  const SyncReloadResult.failure(this.errorMessage);

  final String? errorMessage;

  bool get succeeded => errorMessage == null;
}

/// Reloads all user-owned stores and reports only their actual async states.
class SyncReloadService {
  const SyncReloadService();

  Future<SyncReloadResult> reload({
    required RoadmapViewModel roadmap,
    required TasksViewModel tasks,
    required NotesViewModel notes,
  }) async {
    final stores = <({String name, Future<void> Function() reload, AsyncViewState<dynamic> Function() state})>[
      (
        name: 'Roadmap',
        reload: roadmap.loadData,
        state: () => roadmap.state,
      ),
      (
        name: 'Tasks',
        reload: tasks.loadData,
        state: () => tasks.state,
      ),
      (
        name: 'Notes',
        reload: notes.loadData,
        state: () => notes.state,
      ),
    ];

    await Future.wait(stores.map((store) => store.reload()));

    for (final store in stores) {
      final state = store.state();
      if (state.state == ViewState.error) {
        return SyncReloadResult.failure(
          '${store.name}: ${state.message ?? 'không thể tải dữ liệu.'}',
        );
      }
    }

    return const SyncReloadResult.success();
  }
}
