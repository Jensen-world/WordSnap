import '../models/notebook.dart';
import '../storage/web_storage.dart';

class NotebookRepository {
  final _store = WebStorage();

  Future<List<Notebook>> getAll() async {
    return _store.getNotebooks(orderBy: 'isDefault DESC, createdAt DESC').map((m) => Notebook.fromMap(m)).toList();
  }

  Future<Notebook?> getById(int id) async {
    final nb = _store.getNotebooks().where((n) => n['id'] == id).firstOrNull;
    if (nb == null) return null;
    return Notebook.fromMap(nb);
  }

  Future<Notebook> insert(Notebook notebook) async {
    final id = _store.insertNotebook(notebook.toMap());
    return notebook.copyWith(id: id);
  }

  Future<void> update(Notebook notebook) async {
    _store.updateNotebook(notebook.toMap());
  }

  Future<void> delete(int id) async {
    _store.deleteNotebook(id);
  }

  Future<int> getWordCount(int notebookId) async {
    return _store.countWords(notebookId: notebookId);
  }
}
