import 'package:audiobooks/app/data/models/track_entry.dart';
import 'package:audiobooks/app/modules/home/providers/track_provider.dart';
import 'package:audiobooks/app/routes/app_pages.dart';
import 'package:audiobooks/app/utils/database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum TabState { Unread, Reading, Finished }

class HomeController extends GetxController {
  final LocalDatabase localDatabase = LocalDatabase();

  final _tabState = TabState.Reading.obs;
  final _unreadTracks = List<TrackEntry>.empty(growable: true).obs;
  final _nowReadingTracks = List<TrackEntry>.empty(growable: true).obs;
  final _finishedTracks = List<TrackEntry>.empty(growable: true).obs;

  TabState get tabState => _tabState.value;
  List<TrackEntry> get unreadTracks => _unreadTracks;
  List<TrackEntry> get nowReadingTracks => _nowReadingTracks;
  List<TrackEntry> get finishedTracks => _finishedTracks;

  set tabState(TabState value) {
    _tabState.value = value;
    addTracks();
  }

  @override
  void onInit() {
    // Checks if the databse schema is initialized
    openDatabase().then((databaseOpen) async {
      if (databaseOpen) await localDatabase.initializeDatabaseSchema();
      // Checks if there are loaded paths
      await checkDirectoryPathsExist().then((directoryLoaded) =>
          !directoryLoaded ? Get.toNamed(Routes.MEDIA_FOLDERS) : null);
      addTracks();
    });

    super.onInit();
  }

  @override
  void onClose() {}

  Future<bool> openDatabase() async => localDatabase.openLocalDatabase();

  Future<bool> checkDirectoryPathsExist() async {
    final results =
        await localDatabase.query(table: LocalDatabase.directoryPaths);
    return !results.isBlank!;
  }

  Future<void> addTracks() async {
    final TrackProvider _provider = TrackProvider(localDatabase);

    /// Gets all the now reading tracks
    switch (_tabState.value) {
      case TabState.Unread:
        await _provider
            .getTrackEntries(LocalDatabase.unreadTracksTable)
            .then((value) {
          _unreadTracks.clear();
          _unreadTracks.addAll(value);
        });
        break;

      case TabState.Reading:
        await _provider
            .getTrackEntries(LocalDatabase.nowListeningTracksTable)
            .then((value) {
          _nowReadingTracks.clear();
          _nowReadingTracks.addAll(value);
        });
        break;

      case TabState.Finished:
        await _provider
            .getTrackEntries(LocalDatabase.finishedTracksTable)
            .then((value) {
          _finishedTracks.clear();
          _finishedTracks.addAll(value);
        });
        break;
      default:
    }
  }

  /// Honestly this will not scale and is very slow thing takes O(n2) time
  void addUnique(List<TrackEntry> newTracks, List<TrackEntry> oldTracks) {
    for (final track in newTracks) {
      if (!oldTracks.contains(track)) {
        oldTracks.add(track);
      }
    }
  }
}
