import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Location.dart';
import 'LocationDetails.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key, required this.title});
  final String title;
  static const String routeName = '/';
  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late Stream<List<Location>> locationsStream;
  bool orderByDistance = false;
  bool orderByAlphabetic = false;
  int _myLocationGrade = 0;

  Future<void> initLocationGrade() async {
    var prefs = await SharedPreferences.getInstance();
    setState (() { _myLocationGrade = prefs.getInt ('rate') ?? 0; } );
  }

  void _changeLocationGrade(int newGradeValue) async {
    setState (() { _myLocationGrade = newGradeValue; } );
    var prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rate', _myLocationGrade);
  }

  void initState() {
    super.initState();
    initLocationGrade();
    locationsStream = getLocationsStream();
  }

  Stream<List<Location>> getLocationsStream() async* {
    while (true) {
      try {
        final locations = await readLocationsFromFirebase();
        yield locations;
        await Future.delayed(Duration(
            seconds: 5)); // Espera 5 segundos antes de buscar novamente
      } catch (e) {
        print('Error fetching locations: $e');
        yield <Location>[]; // Retorna uma lista vazia em caso de erro
        await Future.delayed(
            Duration(seconds: 5)); // Tentará novamente após 5 segundos
      }
    }
  }

  Future<List<Location>> readLocationsFromFirebase() async {
    List<Location> response = [];
    QuerySnapshot querySnapshot;
    var db = FirebaseFirestore.instance;

    try {
      querySnapshot = await db.collection('locations').get();

      querySnapshot.docs.forEach((document) {
        Location location = Location(
          document.get('id') ?? '',
          document.get('name') ?? '',
          (document.get('latitude') ?? 0.0).toDouble(),
          (document.get('longitude') ?? 0.0).toDouble(),
          document.get('description') ?? '',
          document.get('photoUrl') ?? '',
          document.get('createdBy') ?? '',
          (document.get('votes') ?? 0).toInt(),
          (document.get('grade') ?? 0.0).toDouble(),
          document.get('category') ?? '',
        );
        response.add(location);
      });
    } catch (e) {
      print('Error: $e');
      throw Exception('Error fetching locations');
    }
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF02458A),
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: () {
              // Vai para a página de consultar últimas 10 pesquisas
            },
          ),
        ],
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Divider(),
            Text(
              'Order by',
              style: TextStyle(
                fontSize: 18,

              ),
            ),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: Text('Distance'),
                    value: orderByDistance,
                    onChanged: (value) {
                      setState(() {
                        orderByDistance = value!;
                        // Apply logic for ordering by distance
                      });
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: Text('Name'),
                    value: orderByAlphabetic,
                    onChanged: (value) {
                      setState(() {
                        orderByAlphabetic = value!;
                        // Apply logic for ordering alphabetically
                      });
                    },
                  ),
                ),
              ],
            ),
            Divider(), // Adiciona um Divider abaixo da Row
            StreamBuilder<List<Location>>(
              stream: getLocationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(snapshot.data![index].name),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${snapshot.data![index].grade}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Icon(Icons.star, color: Colors.amber),
                                  ],
                                ),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.more_vert),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context,
                                        LocationDetailPage.routeName,
                                        arguments: {
                                          'location': snapshot.data![index],
                                          'changeLocationGradeFunction': _changeLocationGrade,
                                          'initialLocationGradeValue': _myLocationGrade
                                        }

                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ],
      ),
    );
  }
}