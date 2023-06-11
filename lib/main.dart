/*
*
* Your task is to create a Flutter frontend for the Note Taking App API. The API is built using Flask and allows users to create, read, update, and delete notes. The API has three endpoints:
* 1. /notes: This endpoint supports both GET and POST requests. A GET request returns a list of all notes in the database, while a POST request creates a new note. The request body for a POST request should include the note's title and content.
* 2. /notes/{note_id}: This endpoint supports GET, PUT, and DELETE requests. A GET request returns the details of the note with the specified note_id, while a PUT request updates the note with the specified note_id.
* 3. The request body for a PUT request should include the updated note's title and content. A DELETE request deletes the note with the specified note_id./keep-alive: This endpoint returns a simple message to confirm that the server is running.
* Your task is to create a Flutter app that allows users to interact with the Note Taking App API. The app should have the following features:
* 1. A home screen that displays a list of all notes in the database. Each note should display the note's title and summary.
* 2. A screen for creating a new note. This screen should allow the user to enter the note's title and content and should have a button to create the note.
* 3. A screen for viewing the details of a single note. This screen should display the note's title, content, and summary, and should have buttons to edit or delete the note.
* 4. A screen for editing a note. This screen should be similar to the screen for creating a new note, but should pre-fill the text fields with the note's current title and content.
* 5. A confirmation dialog that appears when the user tries to delete a note. The dialog should ask the user to confirm that they want to delete the note and should have buttons to confirm or cancel the operation.
* 6. You can use the HTTP package to make requests to the API and retrieve data. When making a POST request to create a new note or a PUT request to update a note, you should include the note's title and content in the request body. When making a DELETE request to delete a note, you should include the note's note_id in the request URL.
* 7. You can use any Flutter widgets or libraries you like to implement the features of the app.
* You can use any Flutter widgets or libraries you like to implement the features of the app.
* */

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note Taking App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const HomePage(),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List notes = [];
  String searchQuery = '';
  bool isSearchBarActive = false;
  FocusNode searchFocusNode = FocusNode();

  Future<void> fetchNotes() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/notes'));
    final List<dynamic> responseData = json.decode(response.body);
    setState(() {
      notes = responseData;
    });
  }

  Future<void> fetchSearchResults(String query) async {
    if (query.isEmpty) {
      fetchNotes();
    } else {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/notes/$query'));
      final List<dynamic> responseData = json.decode(response.body);
      setState(() {
        notes = responseData;
      });
    }
  }

  @override
  void initState() {
    fetchNotes();
    searchFocusNode.addListener(() {
      if (!searchFocusNode.hasFocus) {
        setState(() {
          isSearchBarActive = false;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearchBarActive
            ? TextField(
          focusNode: searchFocusNode,
          onChanged: (value) {
            fetchSearchResults(value);
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search notes...",
            hintStyle: TextStyle(color: Colors.white),
          ),
        )
            : const Text('Notes'),
        actions: <Widget>[
          IconButton(
            icon: Icon(isSearchBarActive ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearchBarActive = !isSearchBarActive;
                if (isSearchBarActive) {
                  searchFocusNode.requestFocus();
                } else {
                  fetchNotes();
                }
              });
            },
          ),
        ],
      ),
      body: ListScreenWidget(notes: notes),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateNoteScreen(),
            ),
          ).then((value) => fetchNotes());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ListScreenWidget extends StatefulWidget {
  final List notes;
  const ListScreenWidget({Key? key, required this.notes}) : super(key: key);

  @override
  _ListScreenWidgetState createState() => _ListScreenWidgetState();
}

class _ListScreenWidgetState extends State<ListScreenWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.notes.length,
      itemBuilder: (BuildContext context, int index) {
        final note = widget.notes[index];
        return ListTile(
          title: Text(note['title']),
          subtitle: Text(note['summary'] ?? 'No summary available'),
          onTap: () async {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetailsScreen(note: note),
              ),
            );
            if (result != null) {
              if (result['deleted'] == true) {
                setState(() {
                  widget.notes.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note deleted successfully')),
                );
              } else {
                setState(() {
                  widget.notes[index] = result;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note saved successfully')),
                );
              }
            }
          },
        );
      },
    );
  }
}

class NoteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> note;

  const NoteDetailsScreen({Key? key, required this.note}) : super(key: key);

  @override
  _NoteDetailsScreenState createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note['title']);
    _bodyController = TextEditingController(text: widget.note['content']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Details'),
        actions: [
          IconButton(
            onPressed: isLoading
                ? null
                : () async {
              setState(() {
                isLoading = true;
              });
              try {
                final response = await http.put(
                  Uri.parse('http://127.0.0.1:5000/notes/${widget.note['id']}'),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(<String, String>{
                    'title': _titleController.text,
                    'content': _bodyController.text,
                  }),
                );
                if (response.statusCode == 200) {
                  Navigator.pop(context, jsonDecode(response.body));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save note.')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to save note.')),
                );
              } finally {
                setState(() {
                  isLoading = false;
                });
              }
            },
            icon: const Icon(Icons.save),
          ),
          IconButton(
            onPressed: isLoading
                ? null
                : () async {
              setState(() {
                isLoading = true;
              });
              try {
                final response = await http.delete(
                  Uri.parse('http://127.0.0.1:5000/notes/${widget.note['id']}'),
                );
                if (response.statusCode == 204) {
                  Navigator.pop(context, {'deleted': true, 'id': widget.note['id']});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete note.')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete note.')),
                );
              } finally {
                setState(() {
                  isLoading = false;
                });
              }
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(  // Add this
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a title',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      hintText: 'Enter some text',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}


class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({Key? key}) : super(key: key);

  @override
  _CreateNoteScreenState createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create New Note'),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(  // Add this
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _contentController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Content',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () async {
                        if (_titleController.text.isNotEmpty &&
                            _contentController.text.isNotEmpty) {
                          setState(() {
                            _loading = true;
                          });
                          try {
                            final response = await http.post(
                              Uri.parse('http://127.0.0.1:5000/notes'),
                              headers: {'Content-Type': 'application/json'},
                              body: json.encode({
                                'title': _titleController.text,
                                'content': _contentController.text,
                              }),
                            );
                            if (response.statusCode == 200) {
                              final data = json.decode(response.body);
                              if (data['summary'] != null) {
                                _titleController.clear();
                                _contentController.clear();
                                _scaffoldKey.currentState?.showSnackBar(
                                  const SnackBar(content: Text('Note created!')),
                                );
                              } else {
                                _scaffoldKey.currentState?.showSnackBar(
                                  const SnackBar(content: Text('Failed to create note')),
                                );
                              }
                            } else {
                              _scaffoldKey.currentState?.showSnackBar(
                                const SnackBar(content: Text('Failed to create note')),
                              );
                            }
                          } catch (e) {
                            _scaffoldKey.currentState?.showSnackBar(
                              const SnackBar(content: Text('Failed to create note')),
                            );
                          } finally {
                            setState(() {
                              _loading = false;
                            });
                          }
                        } else {
                          _scaffoldKey.currentState?.showSnackBar(
                            const SnackBar(content: Text('Please fill all fields')),
                          );
                        }
                      },
                      child: const Text('Create Note'),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
