import 'create_note_page.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/note.dart';
import 'edit_note_page.dart';
import 'package:intl/intl.dart';

enum SortOption {
  alphabetical,
  creationDate,
  lastModified
}

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> _notes = [];
  SortOption _currentSortOption = SortOption.lastModified; // Tri par défaut

  @override
  void initState() {
    super.initState();
    _loadAndSortNotes();
  }

  _loadNotes() async {
    final notesMapList = await DatabaseHelper.instance.getNotes();
    _notes = notesMapList.map((noteMap) => Note.fromMap(noteMap)).toList();
  }

  _sortNotes() {
    setState(() {
      switch (_currentSortOption) {
        case SortOption.alphabetical:
          _notes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          break;
        case SortOption.creationDate:
          _notes.sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) {
              return 0; // Gérer le cas où une date est nulle
            }
            return b.createdAt!.compareTo(a.createdAt!); // Ordre décroissant (plus récent en premier)
          });
          break;
        case SortOption.lastModified:
          _notes.sort((a, b) {
            if (a.updatedAt == null || b.updatedAt == null) {
              return 0; // Gérer le cas où une date est nulle
            }
            return b.updatedAt!.compareTo(a.updatedAt!); // Ordre décroissant (plus récent en premier)
          });
          break;
      }
    });
  }

  _loadAndSortNotes() async {
    await _loadNotes();
    _sortNotes();
  }

  _navigateToEditNotePage(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNotePage(
          note: note,
          onNoteUpdated: _loadAndSortNotes, // Recharge et trie après la mise à jour
        ),
      ),
    );
  }


  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'à l\'instant';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'il y a $minutes minute${minutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'il y a $hours heure${hours > 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'il y a $days jour${days > 1 ? 's' : ''}';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bloc-Note'),
        actions: <Widget>[
          PopupMenuButton<SortOption>(
            onSelected: (SortOption result) {
              setState(() {
                _currentSortOption = result;
                _sortNotes();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.alphabetical,
                child: Text('Alphabétique'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.creationDate,
                child: Text('Date de création'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.lastModified,
                child: Text('Dernière modification'),
              ),
            ],
            icon: Icon(Icons.sort),
          ),
          // IconButton(
          //   icon: Icon(Icons.delete_forever),
          //   onPressed: () => _deleteDatabase(context),
          // ),
        ],
      ),
      body: _notes.isEmpty
          ? Center(child: Text('Aucune note disponible.'))
          : ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          var note = _notes[index];
          final lines = note.content.split('\n');
          //final firstLine = lines.isNotEmpty ? lines[0] : '';
          //final previewContent = firstLine.length > 40 ? firstLine.substring(0, 40) + '...' : firstLine;
          final linesLength = lines.isNotEmpty && lines.length >3
              ? lines[0].length + lines[1].length + lines[2].length
              : note.content.length;
          final previewContent = note.content.length < 40
              ? lines.length > 3
                ? "${lines[0]}\n${lines[1]}\n${lines[2]}\n..."
                : note.content
              : lines.length > 3 && linesLength < 40
                ? "${lines[0]}\n${lines[1]}\n${lines[2]}\n..."
                : note.content.substring(0, 40) + '...';

          final creationDate = note.createdAt != null ? DateTime.fromMillisecondsSinceEpoch(note.createdAt!) : null;
          final lastModifiedDate = note.updatedAt != null ? DateTime.fromMillisecondsSinceEpoch(note.updatedAt!) : null;

          final lastModifiedAgo = _formatTimeAgo(lastModifiedDate);
          final creationDateShortFormatted = creationDate != null ? DateFormat('dd/MM/yyyy').format(creationDate) : '';

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                note.title,
                style: TextStyle( // Ajout du style ici
                  fontWeight: FontWeight.bold, // Met le texte en gras
                  fontSize: 18.0, // Augmente légèrement la taille (la valeur par défaut est généralement 16.0)
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(previewContent),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (lastModifiedAgo.isNotEmpty)
                    Text('Modifié $lastModifiedAgo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  if (creationDateShortFormatted.isNotEmpty)
                    Text('Créé le: $creationDateShortFormatted', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              onTap: () {
                _navigateToEditNotePage(note);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateNotePage,
        child: Icon(Icons.add),
      ),
    );
  }

  _navigateToCreateNotePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNotePage(onNoteCreated: _loadAndSortNotes), // Recharge et trie après la création
      ),
    );
  }
}