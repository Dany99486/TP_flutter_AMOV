import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'models/Location.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
      initialRoute: LocationPage.routeName,
      routes: {
        LocationPage.routeName : (context) => const LocationPage(title: 'Locations'),
        LocationDetailPage.routeName: (context) =>  LocationDetailPage(),
      },
    );
  }
}

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
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Icon(Icons.star, color: Colors.amber),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.more_vert),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        LocationDetailPage.routeName,
                                        arguments: snapshot.data![index]
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
        ),
    );
  }
}
class LocationDetailPage extends StatelessWidget {
  static const String routeName = '/locationDetail';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Location;
    final storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child(args.photoUrl!);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${args.grade}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Icon(Icons.star, color: Colors.amber),
            Text(
              args.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          FutureBuilder<String>(
            future: ref.getDownloadURL(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading image'));
              } else if (snapshot.hasData) {
                return Container(
                  height: 200, // Defina a altura da imagem
                  width: double.infinity,
                  child: Image.network(
                    snapshot.data!,
                    fit: BoxFit.cover,
                  ),
                );
              } else {
                return SizedBox();
              }
            },
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    // Lógica para abrir o mapa
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Color(0xFF02458A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.all(15),
                    child: Icon(
                      Icons.info,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 7),
                InkWell(
                  onTap: () {
                    // Lógica para exibir pontos de interesse
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Color(0xFF02458A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.all(15),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Evaluate Location',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Ajusta o preenchimento interno
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    // Lógica para submeter a avaliação
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: ListView(
                padding: EdgeInsets.zero, // Remova o padding do ListView
                children: [
                  SizedBox(height: 20), // Espaçamento do topo
                  const Text(
                    'Description:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    args.description!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(top: 10),
        color: Colors.white, // Cor de fundo do footer
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Created by: ${args.createdBy!}",
              style:const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
