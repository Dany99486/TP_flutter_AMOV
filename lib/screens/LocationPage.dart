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
  Map<String, dynamic>? allSharedPreferences;



  Future<Map<String, dynamic>> loadAllSharedPreferences() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().fold<Map<String, dynamic>>(
        {},
            (Map<String, dynamic> accumulator, String key) {
          accumulator[key] = prefs.get(key);
          return accumulator;
        }
    );
  }


  Future<void> loadSharedPreferences() async {
    Map<String, dynamic> sharedPreferences = await loadAllSharedPreferences();
    setState(() {
      allSharedPreferences = sharedPreferences;
    });
  }


  void setSharedPreferences(String key, dynamic value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (value is String) {

      await prefs.setString(key, value);
      allSharedPreferences?.clear();
      loadSharedPreferences();

    } else if (value is int) {

      await prefs.setInt(key, value);
      allSharedPreferences?.clear();
      loadSharedPreferences();

    }
  }

  void initState() {
    super.initState();
    loadSharedPreferences();
    locationsStream = getLocationsStream();
  }

  Stream<List<Location>> getLocationsStream() async* {
    while (true) {
      try {
        final locations = await readLocationsFromFirebase();
        yield locations;
        await Future.delayed(Duration(
            seconds: 5));
      } catch (e) {
        print('Error fetching locations: $e');
        yield <Location>[];
        await Future.delayed(
            Duration(seconds: 5));
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
                  if (orderByAlphabetic) {
                    snapshot.data!.sort((a, b) => a.name.compareTo(b.name));
                  }
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
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.more_vert),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context,
                                        LocationDetailPage.routeName,
                                        arguments: {
                                          'location': snapshot.data![index],
                                          'changeLocationGradeFunction': setSharedPreferences,
                                          'initialLocationGradeValue': allSharedPreferences?[snapshot.data![index].id] as int? ?? -1
                                        }
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.location_on),
                                  onPressed: () {

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