class Note {
  final int? id;
  final String title;
  final String content;
  final int? createdAt;
  final int? updatedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  // Convertir une Note en Map pour l'insertion dans la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Créer une Note à partir d'un Map (comme un enregistrement de la base de données)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}