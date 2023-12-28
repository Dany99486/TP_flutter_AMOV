import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tp_flutter/screens/poi/POIPage.dart';
import '../../models/Local.dart';
import 'package:location/location.dart';
import '../HistoryPage.dart';
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
  late Stream<List<Local>> locationsStream;
  bool orderByDistance = false;
  bool orderByAlphabetic = false;
  Map<String, dynamic>? allSharedPreferences;
  StreamSubscription<LocationData>? _locationSubscription;

  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  LocationData _locationData = LocationData.fromMap({
    "latitude": 40.192639,
    "longitude": -8.411899,
  });


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
  void getLocation() async {
    _locationSubscription=location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {_locationData = currentLocation;});
    });
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    _locationData = await location.getLocation();
    setState(() {});
    _locationSubscription?.cancel();
    _locationSubscription=null;
  }
  /*int getDistance(Location location) {
    var _locationData =  location.getLocation();
    return 0;
  }*/

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

  @override
  void initState() {
    super.initState();
    loadSharedPreferences();
    locationsStream = getLocationsStream();
  }

  Stream<List<Local>> getLocationsStream() async* {
    while (true) {
      try {
        final locations = await readLocationsFromFirebase();
        yield locations;
        await Future.delayed(const Duration(
            seconds: 5));
      } catch (e) {
        print('Error fetching locations: $e');
        yield <Local>[];
        await Future.delayed(
            const Duration(seconds: 5));
      }
    }
  }

  Future<List<Local>> readLocationsFromFirebase() async {
    List<Local> response = [];
    QuerySnapshot querySnapshot;
    var db = FirebaseFirestore.instance;

    try {
      querySnapshot = await db.collection('locations').get();

      for (var document in querySnapshot.docs) {
        Local location = Local(
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
          (document.get('likes') ?? 0).toInt(),
          (document.get('dislikes') ?? 0).toInt(),
        );
        response.add(location);
      }
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
        backgroundColor: const Color(0xFF02458A),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(
                context,
                HistoryPage.routeName,
              );            },
          ),
        ],
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Divider(),
            const Text(
              'Order by',
              style: TextStyle(
                fontSize: 18,

              ),
            ),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Distance'),
                    value: orderByDistance,
                    onChanged: (value) {
                      setState(() {
                        orderByDistance = value!;
                        if(orderByDistance) { getLocation(); }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Name'),
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
            const Divider(), // Adiciona um Divider abaixo da Row
            StreamBuilder<List<Local>>(
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
                  else if (orderByDistance){
                    snapshot.data!.sort((a, b) => getDistance(a).compareTo(getDistance(b)));
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
                                  child:  Text(snapshot.data![index].name),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
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
                                  icon: const Icon(Icons.location_on),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context,
                                        POIPage.routeName,
                                        arguments: {
                                          'location': snapshot.data![index],
                                        }
                                    );
                                  },
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10.0), // Adicionando padding ao Divider
                                    child: Divider(), // Divider entre o title e o subtitle
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.thumb_up),
                                      const SizedBox(width: 4), // Adicionando espaço entre o ícone e o texto
                                      Text("${snapshot.data![index].likes}"),
                                      const Spacer(),
                                      const Icon(Icons.thumb_down),
                                      const SizedBox(width: 4), // Adicionando espaço entre o ícone e o texto
                                      Text("${snapshot.data![index].dislikes}"),
                                    ],
                                  ),
                                ],
                              ),
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
  double getDistance(Local local){
    //getLocation();
    double latitude=_locationData.latitude!;
    double longitude=_locationData.longitude!;
    double x=(latitude-local.latitude!).abs();
    double y =(longitude-local.longitude!).abs();
    print(sqrt(x*x+y+y));
    return sqrt(x*x+y+y);
  }
}
