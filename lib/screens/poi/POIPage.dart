import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/Local.dart';
import '../../models/POI.dart';
import '../../models/Categories.dart';
import '../HistoryPage.dart';
import 'POIDetails.dart';


class POIPage extends StatefulWidget {
  const POIPage({super.key, required this.title});
  static const String routeName = '/POIPage';
  final String title;

  @override
  _PoiPageState createState() => _PoiPageState();
}

class _PoiPageState extends State<POIPage> {
  late Stream<List<POI>> PoiStream;
  bool orderByDistance = false, orderByCategory = false;
  String? selectedCategory;
  Map<String, dynamic>? allSharedPreferences;
  late List<POI> historyList = [];
  bool orderByAlphabetic = false;

  StreamSubscription<LocationData>? _locationSubscription;

  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  LocationData _locationData = LocationData.fromMap({
    "latitude": 40.192639,
    "longitude": -8.411899,
  });



  Future<void> loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? historyJson = prefs.getString('history');
    print('History List: $historyJson');

    if (historyJson != null) {
      // Decode the JSON string into a List<Map<String, dynamic>>
      List<Map<String, dynamic>> decodedHistory = (json.decode(historyJson) as List<dynamic>).cast<Map<String, dynamic>>();
      // Convert each map into a POI object
      historyList = decodedHistory.map((poiMap) => POI.fromJson(poiMap)).toList();
    }
  }


  Future<void> saveToHistory(POI poi) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get the existing history string or use an empty string if not present
    String? existingHistory = prefs.getString('history');
    List<Map<String, dynamic>> historyList;

    if (existingHistory != null) {
      // Decode the existing JSON string into a list of maps
      List<dynamic> decodedHistory = json.decode(existingHistory);
      historyList = decodedHistory.cast<Map<String, dynamic>>().toList();
    } else {
      historyList = [];
    }
    for (var i = 0; i < historyList.length; i++) {
      if (historyList[i]['id'] == poi.id) {
        return;
      }
    }
    // Add the new POI as a map
    historyList.insert(0, poi.toJson());

    // Limit the list to 10 items
    if (historyList.length > 10) {
      historyList = historyList.sublist(0, 10);
    }

    // Encode the entire list back to a JSON string
    String encodedHistory = json.encode(historyList);

    // Save the encoded list to SharedPreferences
    prefs.setString('history', encodedHistory);
  }
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
    loadHistory();

  }

  Future<List<POI>> readPoiFromFirebase(String docName) async {
    List<POI> response = [];
    QuerySnapshot querySnapshot;
    var db = FirebaseFirestore.instance;

    try {
      querySnapshot = await db.collection('locations').doc(docName).collection('pointsOfInterest').get();

      for (var document in querySnapshot.docs) {

        POI poi = POI(
          document.get('id') ?? '',
          document.get('name') ?? '',
          (document.get('latitude') ?? 0.0).toDouble(),
          (document.get('longitude') ?? 0.0).toDouble(),
          document.get('description') ?? '',
          document.get('photoUrl') ?? '',
          (document.get('likes') ?? 0).toInt(),
          (document.get('dislikes') ?? 0).toInt(),
          document.get('createdBy') ?? '',
          (document.get('grade') ?? 0.0).toDouble(),
          document.get('category') ?? '',
          document.get('locationId') ?? '',
        );
        response.add(poi);
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error fetching locations');
    }
    return response;
  }
  Stream<List<POI>> getPoiStream(String docName) async* {
    while (true) {
      try {
        final poi = await readPoiFromFirebase(docName);
        yield poi;
        await Future.delayed(const Duration(
            seconds: 5));
      } catch (e) {
        print('Error fetching locations: $e');
        yield <POI>[];
        await Future.delayed(
            const Duration(seconds: 5));
      }
    }
  }
  Stream<List<Categories>> getCategoriesStream() async* {
    while (true) {
      try {
        final locations = await readCategoriesFromFirebase();
        yield locations;
        await Future.delayed(const Duration(
            seconds: 5));
      } catch (e) {
        print('Error fetching locations: $e');
        yield <Categories>[];
        await Future.delayed(
            const Duration(seconds: 5));
      }
    }
  }

  Future<List<Categories>> readCategoriesFromFirebase() async {
    List<Categories> response = [];
    QuerySnapshot querySnapshot;
    var db = FirebaseFirestore.instance;

    try {
      querySnapshot = await db.collection('category').get();

      for (var document in querySnapshot.docs) {
        Categories location = Categories(
          document.get('id') ?? '',
          document.get('name') ?? '',
          document.get('description') ?? '',
          document.get('iconUrl') ?? '',
          document.get('createdBy') ?? '',
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
    var args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    Local location = args['location'];
    return Scaffold(

      appBar: AppBar(
        backgroundColor: const Color(0xFF02458A),
        title: Text(
          location.name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(
                context,
                HistoryPage.routeName,
              );
            },
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



          Row(children: [
            Expanded(
              child: CheckboxListTile(
                  title: const Text('Category'),
                  value: orderByCategory,
                  onChanged: (value) {
                    setState(() {
                      orderByCategory = value!;
                    });
                  }
              ),

            ),
            StreamBuilder<List<Categories>>(
              stream: getCategoriesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  // Handle the case where data is not available yet
                  return const CircularProgressIndicator(); // ou algum outro indicador de carregamento
                }

                List<Categories> categories = snapshot.data!;
                print("Categories:");
                for (var i = 0; i < categories.length; i++) {
                  print(categories[i].name);
                }

                List<DropdownMenuItem<String>> dropdownItems = categories.map(
                      (Categories category) => DropdownMenuItem<String>(
                    value: category.name,
                    child: Text(category.name),
                  ),
                ).toList();

                dropdownItems.insert(0,const DropdownMenuItem<String>(
                  value: "Escolha",
                  child: Text("Choose"),
                ));

                return Container(
                  child: DropdownButton<String>(
                    value: selectedCategory ?? dropdownItems.first.value,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                    },
                    items: dropdownItems,
                    hint: const Text('Select Category'),
                  ),
                );
              },
            ),




          ],
          ),
          const Divider(), // Adiciona um Divider abaixo da Row
          StreamBuilder<List<POI>>(
            stream: getPoiStream(location.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {

                return const Center(child: CircularProgressIndicator());

              } else if (snapshot.hasError) {

                return Center(child: Text('Error: ${snapshot.error}'));

              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {

                  return AlertDialog(
                    title: const Text('No Point Of Interest'),
                    content: const Text('There are no Points Of Interest to this location.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Back'),
                      ),
                    ],
                  );

              } else {
                if (orderByAlphabetic) {
                  snapshot.data!.sort((a, b) => a.name.compareTo(b.name));
                } else if (orderByDistance){
                  snapshot.data!.sort((a, b) => getDistance(a).compareTo(getDistance(b)));
                } else if(orderByCategory){
                  snapshot.data!.sort((a, b) => a.category!.compareTo(b.category!));
                }
                if(selectedCategory != null && selectedCategory != "Escolha"){
                  snapshot.data!.removeWhere((element) => element.category != selectedCategory);
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
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  saveToHistory(snapshot.data![index]);
                                  Navigator.pushNamed(
                                      context,
                                      POIDetailPage.routeName,
                                      arguments: {
                                        'location': location,
                                        'poi': snapshot.data![index],
                                        'changePoiGradeFunction': setSharedPreferences,
                                        'initialPoiGradeValue': allSharedPreferences?[snapshot.data![index].id] as int? ?? -1,
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
  double getDistance(POI local){
    //getLocation();
    double latitude=_locationData.latitude!;
    double longitude=_locationData.longitude!;
    double x=(latitude-local.latitude!).abs();
    double y =(longitude-local.longitude!).abs();
    print(sqrt(x*x+y+y));
    return sqrt(x*x+y+y);
  }
}