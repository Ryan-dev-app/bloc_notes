import 'dart:async';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/note.dart';

class CreateNotePage extends StatefulWidget {
  final Function onNoteCreated;

  CreateNotePage({required this.onNoteCreated});

  @override
  _CreateNotePageState createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  Timer? _debounceTimer;
  int? _noteId; // Stocke l'ID de la note si elle est créée
  int? _creationDate; // Stocke la date de création

  // Fonction pour créer ou mettre à jour la note et naviguer en arrière
  _saveAndPop() async {
    await _saveNote();
    Navigator.pop(context);
  }

  // Fonction pour créer ou mettre à jour la note
  _saveNote() async {
    final title = _titleController.text;
    final content = _contentController.text;

    if (title.isNotEmpty || content.isNotEmpty) {
      if (_noteId == null) {
        // Créer une nouvelle note
        Note newNote = Note(title: title, content: content);
        _noteId = await DatabaseHelper.instance.insertNote(newNote.toMap());
        print("Nouvelle note créée avec l'ID: $_noteId");

        // Récupérer la date de création après l'insertion
        if (_noteId != null) {
          List<Map<String, dynamic>> createdNote = await DatabaseHelper.instance.getNoteById(_noteId!);
          if (createdNote.isNotEmpty && createdNote.first['created_at'] != null) {
            _creationDate = createdNote.first['created_at'];
            print("Date de création récupérée: ${_creationDate}");
            // Vous pouvez maintenant utiliser _creationDate comme vous le souhaitez
          } else {
            print("Erreur lors de la récupération de la date de création.");
          }
        }

        widget.onNoteCreated(); // Rafraîchit la liste des notes
      } else {
        // Mettre à jour la note existante
        Note updatedNote = Note(id: _noteId, title: title, content: content, createdAt: _creationDate);
        await DatabaseHelper.instance.updateNote(updatedNote.toMap());
        print("Note avec l'ID $_noteId mise à jour.");
        widget.onNoteCreated(); // Rafraîchit la liste des notes
      }
    }
  }

  // Fonction pour la sauvegarde automatique
  void _autoSaveNote() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }
    _debounceTimer = Timer(const Duration(seconds: 1), _saveNote);
  }

  // Méthode pour intercepter le retour
  Future<bool> _onWillPop() async {
    _saveNote(); // Sauvegarde avant de quitter
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bloc-Notes'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              _saveNote(); // Sauvegarde avant de revenir
              Navigator.pop(context);
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _saveAndPop, // Appelle la fonction pour sauvegarder et revenir
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Pour que les enfants prennent toute la largeur
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Entrez le titre de la note...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  onChanged: (text) {
                    _autoSaveNote();
                  },
                ),
              ),
              SizedBox(height: 20),
              Expanded( // Ajout du widget Expanded ici
                child: TextField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    hintText: 'Entrez le contenu de la note...',
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  expands: true, // Permet au TextField de s'étendre dans l'Expanded
                  onChanged: (text) {
                    _autoSaveNote();
                  },
                ),
              ),
              // Le SizedBox en bas n'est plus nécessaire car le TextField prendra tout l'espace
              // SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}