import 'dart:async';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/note.dart';

class EditNotePage extends StatefulWidget {
  final Note note;
  final Function onNoteUpdated;

  EditNotePage({required this.note, required this.onNoteUpdated});

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note.title;
    _contentController.text = widget.note.content;
  }

  // Fonction pour créer ou mettre à jour la note et naviguer en arrière
  _saveAndPop() async {
    await _saveNote();
    Navigator.pop(context);
  }

  // Fonction pour supprimer la note avec confirmation
  _deleteNote(BuildContext context) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Supprimer cette note ?'),
          content: Text('Êtes-vous sûr de vouloir supprimer cette note ? Cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Ne pas supprimer
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true); // Confirmer la suppression
                await DatabaseHelper.instance.deleteNote(widget.note.id!);
                widget.onNoteUpdated(); // Rafraîchit la liste des notes sur la page précédente
                Navigator.pop(context); // Retour à la page précédente
              },
              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note supprimée.')),
      );
    }
  }

  // Fonction de sauvegarde automatique
  void _autoSaveNote() async {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel(); // Annule le précédent timer
    }

    // Démarre un nouveau timer de 2 secondes
    _debounceTimer = Timer(const Duration(seconds: 1), () async {
      _saveNote();
    });
  }

  _saveNote() async {
    if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty) {
      Note updatedNote = Note(
        id: widget.note.id,
        title: _titleController.text,
        content: _contentController.text,
        createdAt: widget.note.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch, // Mettre à jour la date de modification
      );
      await DatabaseHelper.instance.updateNote(updatedNote.toMap());
      widget.onNoteUpdated(); // Rafraîchit la liste des notes
    }
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
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Color(0xaaa30303),
              ), // Icône de la poubelle
              onPressed: () => _deleteNote(context), // Appelle la fonction de suppression
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre plus gros et en gras
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Sans titre',
                  border: InputBorder.none, // Supprimer le border
                ),
                style: TextStyle(
                  fontSize: 24, // Titre plus gros
                  fontWeight: FontWeight.bold, // Titre en gras
                ),
                maxLines: 1, // Le titre ne doit pas avoir de retour à la ligne
                onChanged: (text) {
                  _autoSaveNote(); // Sauvegarde automatique lors du changement
                },
              ),
              SizedBox(height: 20),
              // Contenu avec une zone de texte large
              Expanded( // Ajout du widget Expanded ici
                child: TextField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    border: InputBorder.none, // Supprimer le border
                  ),
                  style: TextStyle(
                    fontSize: 18, // Contenu un peu plus petit que le titre
                  ),
                  maxLines: null, // Permet les retours à la ligne multiples
                  keyboardType: TextInputType.multiline,
                  onChanged: (text) {
                    _autoSaveNote(); // Sauvegarde automatique lors du changement
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}