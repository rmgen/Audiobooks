import 'dart:async';
import 'dart:io';

import 'package:audiobooks/app/data/models/track.dart';
import 'package:audiobooks/app/data/models/album.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import 'package:audiobooks/app/utils/database.dart';

class MediaScanner {
  MediaScanner(this.localDatabase);
  final LocalDatabase localDatabase;

  /// These are the audiobok media types accepted
  static const List<String> AUDIO_MEDIA_TYPES = ['.mp3', '.m4b'];

  Future<void> queryMediaFolders() async {
    final results =
        await localDatabase.query(table: LocalDatabase.directoryPaths);
    // ignore: prefer_final_locals
    List<String> paths = [];
    for (final result in results!) {
      paths.add(result['directoryPath']! as String);
    }

    for (final String path in paths) {
      final Directory directory = Directory(path);
      final List<FileSystemEntity> entitites =
          await directory.list(recursive: true).toList();

      for (final FileSystemEntity entity in entitites) {
        final String extensiton = p.extension(entity.path);
        if (AUDIO_MEDIA_TYPES.contains(extensiton)) {
          final Track track = await getMediaInfo(entity.path);

          /// Adds album
          if (!(track.albumName == null && track.trackName == null)) {
            print('Added ${track.trackName} to db');
            _addAlbumToDatabase(Album(
              albumName: track.albumName!,
              albumAuthor: track.albumArtistName,
              albumArt: track.albumArt,
              albumLength: track.albumLength,
            ));

            /// Adds media to database
            await _addAudiobookToDatabase(track);
          }

          // if (Get.isSnackbarOpen!) Get.back();
          Get.snackbar("New book !", 'Added new audiobook ${track.trackName}');
        }
      }
    }
  }

  Future<Track> getMediaInfo(String mediaPath) async {
    final retriever = MetadataRetriever();
    await retriever.setFile(File(mediaPath));
    final Metadata metadata = await retriever.metadata;
    final Track _audiobook = Track.fromMap(metadata.toMap())
      ..path = mediaPath
      ..albumArt = retriever.albumArt;
    return _audiobook;
  }

  Future<void> _addAlbumToDatabase(Album album) async {
    final String albumsTable = LocalDatabase.albumsTable;
    final String recentlyAddedTable = LocalDatabase.recentlyAddedTable;

    localDatabase.database.transaction((txn) async {
      final int albumId = await txn.rawInsert('''
        INSERT OR IGNORE INTO $albumsTable (
          currentTrackId, albumDuration, albumName, albumAuthor,
          albumLength, albumArt
        ) VALUES ( ?,?,?,?,?,?)
      ''', [
        album.currentTrackId,
        album.albumDuration,
        album.albumName,
        album.albumAuthor,
        album.albumLength,
        album.albumArt,
      ]);

      // When there is a unique album it is added to the database
      // A return type of 0 means that there was a match confict
      if (albumId != 0) {
        // Inserts to the recently added table because of course its been
        // recently added huh
        await txn.rawInsert('''
          INSERT OR IGNORE INTO $recentlyAddedTable 
            (albumId) VALUES (?)
        ''', [albumId]);

        // This queries the number of objects present in the shelves table
        final resultsSet = await txn.query(LocalDatabase.shelvesTable,
            columns: ['numberOf'],
            where: 'shelfName = ?',
            whereArgs: ['Recently added']);
        if (resultsSet.isNotEmpty) {
          final int numberOf = resultsSet.first['numberOf']! as int;
          // Updates the number of objects in the shelves table
          // increments it by one
          await txn.update(
              LocalDatabase.shelvesTable, {'numberOf': numberOf + 1},
              where: 'shelfName = ?', whereArgs: ['Recently added']);
        }
      }
    });
  }

  Future<void> _addAudiobookToDatabase(Track track) async {
    final String tracksTable = LocalDatabase.tracksTable;
    final String albumsTable = LocalDatabase.albumsTable;

    localDatabase.database.transaction((txn) async {
      int? albumId;
      if (track.albumName != null) {
        final resultsSet = await txn.query(albumsTable,
            columns: ['albumId'],
            where: 'albumName = ?',
            whereArgs: [track.albumName]);
        albumId = resultsSet.first['albumId'] as int?;
      }
      await txn.rawInsert('''
          INSERT OR IGNORE INTO $tracksTable
          (albumId, trackName, trackArtistNames,albumName,albumArtistName,
            trackNumber,albumLength, year,genre,authorName,
            writerName, discNumber, mimeType, trackDuration, bitrate, path, currentPosition, albumArt
            ) VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
          ) 
          
      ''', [
        albumId,
        track.trackName,
        if (track.trackArtistNames != null)
          track.trackArtistNames!.join('|').toString()
        else
          null,
        track.albumName,
        track.albumArtistName,
        track.trackNumber,
        track.albumLength,
        track.year,
        track.genre,
        track.authorName,
        track.writerName,
        track.discNumber,
        track.mimeType,
        track.trackDuration,
        track.bitrate,
        track.path,
        track.currentPosition,
        track.albumArt
      ]);
    });
  }
}
