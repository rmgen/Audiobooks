import 'package:audiobooks/app/data/models/album.dart';
import 'package:audiobooks/app/data/models/track.dart';
import 'package:audiobooks/app/modules/home/providers/album_provider.dart';
import 'package:audiobooks/app/modules/home/providers/player_provider.dart';
import 'package:audiobooks/app/modules/home/providers/track_provider.dart';
import 'package:audiobooks/app/utils/database.dart';
import 'package:get/get.dart';

class AlbumController extends GetxController {
  AlbumController({required LocalDatabase localDatabase, required this.album})
      : _localDatabase = localDatabase;

  final LocalDatabase _localDatabase;
  final Album album;
  TrackProvider get _trackProvider => TrackProvider(_localDatabase);
  AlbumProvider get _albumProvider => AlbumProvider(_localDatabase);
  PlayerProvider get _playerProvider => PlayerProvider(_localDatabase);

  final _tracks = List<Track>.empty(growable: true).obs;
  final _currentTrack = Track.empty().obs;

  List<Track> get tracks => _tracks;
  Track get currentTrack => _currentTrack.value;

  Future<void> getTracksInAlbum() async {
    await _trackProvider.getTracksInAlbum(album.albumId!).then((value) {
      _tracks.addAll(value);
    });
  }

  Future<void> updateCurrentTrack(int trackId) async {
    await _albumProvider.updateCurrentTrackInCollection(
        trackId: trackId, albumId: album.albumId!);
  }

  Future<void> getCurrentTrack() async {
    if (album.currentTrackId != null) {
      final int currentTrackId =
          await _albumProvider.getCurrentTrackId(album.currentTrackId!);
      if (currentTrackId != 0) {
        _currentTrack.value = await _trackProvider.getTrackById(currentTrackId);
      } else {
        _currentTrack.value = _tracks.first;
      }
    } else {
      _currentTrack.value = _tracks.first;
    }
  }

  Future<int> getCurrentTrackPosition() async {
    return _playerProvider
        .getCurrentTrackPlayPosition(_currentTrack.value.trackId!);
  }

  Future<void> goToNextTrack() async {
    final int currentIndex = _tracks.indexWhere(
        (element) => element.trackId == _currentTrack.value.trackId);
    final int nextTrackIndex = currentIndex + 1;
    if (_tracks.length > nextTrackIndex) {
      _currentTrack.value = _tracks[nextTrackIndex];
      await updateCurrentTrack(_tracks[nextTrackIndex].trackId!);
    }
  }

  Future<void> goToPreviousTrack() async {
    final int currentIndex = _tracks.indexWhere(
        (element) => element.trackId == _currentTrack.value.trackId);
    final int previousTrackIndex = currentIndex - 1;
    if (previousTrackIndex >= 0) {
      _currentTrack.value = _tracks[previousTrackIndex];
      await updateCurrentTrack(_tracks[previousTrackIndex].trackId!);
    }
  }

  @override
  void onInit() {
    getTracksInAlbum().then((value) => getCurrentTrack());
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }
}
