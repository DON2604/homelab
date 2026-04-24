import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelab_mobile/features/faces/domain/models/face_models.dart';
import 'package:homelab_mobile/features/faces/domain/repositories/faces_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final facesRepositoryProvider = Provider<FacesRepository>(
  (_) => const FacesRepository(),
);

// ── All person clusters ───────────────────────────────────────────────────────

/// Fetches all persons (face clusters) from the server.
final personsProvider = FutureProvider.autoDispose<List<FaceCluster>>((ref) {
  final repo = ref.watch(facesRepositoryProvider);
  return repo.getPersons();
});

// ── Images for a specific person ──────────────────────────────────────────────

/// Fetches all face images for [personId].
final personImagesProvider =
    FutureProvider.autoDispose.family<List<FaceImage>, int>((ref, personId) {
  final repo = ref.watch(facesRepositoryProvider);
  return repo.getPersonImages(personId);
});

// ── Rename notifier ───────────────────────────────────────────────────────────

class RenamePersonNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> rename(int personId, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(facesRepositoryProvider).renamePerson(personId, name),
    );
    // Invalidate the persons list so it refreshes
    ref.invalidate(personsProvider);
  }
}

final renamePersonProvider =
    AsyncNotifierProvider<RenamePersonNotifier, void>(RenamePersonNotifier.new);
