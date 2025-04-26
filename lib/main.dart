import 'package:flutter/material.dart';
import 'screens/notes_page.dart';
import 'package:sqflite/sqflite.dart'; // Importation de sqflite pour Android et Linux
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Importation de sqflite_common_ffi pour Linux
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Importation spécifique au Web
import 'dart:io' show Platform; // Importation de Platform pour détecter la plateforme
import 'package:flutter/foundation.dart'; // Nécessaire pour kIsWeb

void main() {
  // Initialisation en fonction de la plateforme
  if (kIsWeb) {
    // Utilisation de sqflite_common_ffi_web pour le Web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isLinux) {
    // Utilisation de sqflite_common_ffi pour Linux
    databaseFactory = databaseFactoryFfi;
  } else if (Platform.isAndroid || Platform.isIOS) {
    // Pour Android et iOS, sqflite gère la base de données automatiquement
    //databaseFactory = databaseFactoryFfi;
  }

  // Lancement de l'application
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloc-Note',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotesPage(), // Ta page principale
    );
  }
}
