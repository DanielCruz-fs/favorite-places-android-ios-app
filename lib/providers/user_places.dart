import 'dart:io';

import 'package:favorite_places/models/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// we use this library to get the path of the app's directory
// 'cause we need to store the image file in the app's directory and
// different platforms have different directories for storing files
import 'package:path_provider/path_provider.dart' as syspaths;

// we use this library to manipulate the path of the image file
import 'package:path/path.dart' as path;

import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

Future<Database> _getDataBase() async {
  // save the place to the database
  final dbPath = await sql.getDatabasesPath();
  // create and open the database
  final db = await sql.openDatabase(path.join(dbPath, 'places.db'),
      onCreate: (db, version) {
    return db.execute(
        'CREATE TABLE user_places(id TEXT PRIMARY KEY, title TEXT, image TEXT, lat REAL, lng REAL, address TEXT)');
  }, version: 1);

  return db;
}

class UserPlacesNotifier extends StateNotifier<List<Place>> {
  UserPlacesNotifier() : super(const []);

  Future<void> loadPlaces() async {
    // fix dir path ios production https://github.com/flutter/flutter/issues/50268#issuecomment-584420419
    // refs: https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/learn/lecture/37267038#questions/20594712
    final appDir = await syspaths.getApplicationDocumentsDirectory();

    final db = await _getDataBase();

    // to clear the database table
    // db.execute('DELETE FROM user_places');

    final data = await db.query('user_places');
    data.map((place) {
      state = [
        ...state,
        Place(
          id: place['id'] as String,
          title: place['title'] as String,
          image: File('${appDir.path}/${place['image'] as String}'),
          location: PlaceLocation(
            latitude: place['lat'] as double,
            longitude: place['lng'] as double,
            address: place['address'] as String,
          ),
        ),
      ];
    }).toList();
  }

  void addPlace(String title, File image, PlaceLocation location) async {
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final filename = path.basename(image.path);
    final copiedImage = await image.copy('${appDir.path}/$filename');

    final newPlace =
        Place(title: title, image: copiedImage, location: location);

    final db = await _getDataBase();
    db.insert(
      'user_places',
      {
        'id': newPlace.id,
        'title': newPlace.title,
        'image': filename,
        'lat': newPlace.location.latitude,
        'lng': newPlace.location.longitude,
        'address': newPlace.location.address,
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );

    state = [...state, newPlace];
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNotifier, List<Place>>(
  (ref) => UserPlacesNotifier(),
);

// now the images are not stored in the app's memory, but in the app's directory
// which is private to the app and can't be accessed by other apps
// but to clean up the images when the user deletes a place, we need to add a method.
// and also, when user deletes the app, we need to clean up the images
// how to do that? we can use the path_provider library to get the app's directory and
// then delete the images when the user deletes a place or the app.
// we can do that also manually with xcode or android studio, but it's better to do it programmatically

/**
 * Using Xcode:
	•	Connect your iPhone to your computer.
	•	Open Xcode and go to the “Devices and Simulators” window (Window -> Devices and Simulators).
	•	Select your device, then find your app under “Installed Apps.”
	•	You can download the container of your app, which includes all files stored in your app’s directory (including the Documents directory where your image is stored).
 */