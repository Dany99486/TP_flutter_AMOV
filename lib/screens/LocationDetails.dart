import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/Location.dart';

class LocationDetailPage extends StatelessWidget {
  static const String routeName = '/locationDetail';

  @override
  Widget build(BuildContext context) {

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Location location = args['location'];
    final Function(int) changeLocationGradeFunction = args['changeLocationGradeFunction'];
    final int initialLocationGradeValue = args['initialLocationGradeValue'];
    int selectedValue = initialLocationGradeValue;
    final storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child(location.photoUrl!);
    int? nValue;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${location.grade}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Icon(Icons.star, color: Colors.amber),
            Text(
              location.name,
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
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: Text('Rate Location'),
                    value: selectedValue,
                    onChanged: (newValue) {
                      nValue = newValue;
                    },
                    items: List.generate(5, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child:
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text((index + 1).toString()),
                            const Icon(Icons.star, color: Colors.amber),
                          ],
                        ),

                      );
                    }),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (nValue != null) {
                      changeLocationGradeFunction(nValue!); //salva no search-preferences
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Rating saved!'),
                              content: Text('Your rating has been saved successfully.'),
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Error'),
                            content: Text('Error saving your rating'),
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
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
                    location.description!,
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
              "Created by: ${location.createdBy!}",
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