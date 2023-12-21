import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'models/Location.dart';

void initFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initFirebase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PraticalWork2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF02458A)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Locations'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Stream<List<Location>> locationsStream;
  bool orderByDistance = false;
  bool orderByAlphabetic = false;

  void initState() {
    super.initState();
    locationsStream = getLocationsStream();
  }

  Stream<List<Location>> getLocationsStream() async* {
    while (true) {
      try {
        final locations = await readLocationsFromFirebase();
        yield locations;
        await Future.delayed(Duration(seconds: 5)); // Espera 5 segundos antes de buscar novamente
      } catch (e) {
        print('Error fetching locations: $e');
        yield <Location>[]; // Retorna uma lista vazia em caso de erro
        await Future.delayed(Duration(seconds: 5)); // Tentará novamente após 5 segundos
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
        body: Center(
          child: Column(
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

                    return Center(child: CircularProgressIndicator());

                  } else if (snapshot.hasError) {

                    return Center(child: Text('Error: ${snapshot.error}'));

                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {

                    return Center(child: CircularProgressIndicator());

                  } else {
                    return Expanded(
                      child: ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              title: Text(snapshot.data![index].name),
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
        ),
    );
  }
}
