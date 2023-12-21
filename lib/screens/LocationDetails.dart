import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/Location.dart';

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