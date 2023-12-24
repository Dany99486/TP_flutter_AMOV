import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/Location.dart';
import '../models/POI.dart';

class POIDetailPage extends StatefulWidget {
  static const String routeName = '/PoiDetail';

  @override
  _POIDetailPageState createState() => _POIDetailPageState();
}

class _POIDetailPageState extends State<POIDetailPage> {
  String? _error;
  Color likeButtonColor = Colors.grey;
  int initialLocationGradeValue = 0;
  bool isLiked = false;

  void incrementeLikes(String locationParent,String docName, bool dec) async {
    var db = FirebaseFirestore.instance;

    print("fcwa");
    var document = db.collection('locations').doc(locationParent).collection('pointsOfInterest').doc(docName);
    var data = await document.get(const GetOptions(source: Source.server));
    if (data.exists) {
      print("aquiiiiiiiiiiiiiiiiiiiiiiii\n\n");
      var values = data['likes'] + 1;
      document.update({'likes': values}).then(
              (res) => setState(() { _error = null; }),
          onError: (e) => setState(() { _error = e.toString();})
      );
      if(dec){
        var values = data['dislikes'] - 1;
        if(values >= 0){
          document.update({'dislikes': values}).then(
                  (res) => setState(() { _error = null; }),
              onError: (e) => setState(() { _error = e.toString();})
          );
        }
      }

    } else {
      setState(() { _error = "Document doesn't exist";});
    }
  }

  void incrementeDislikes(String locationParent,String docName, bool dec) async {
    var db = FirebaseFirestore.instance;
    var document = db.collection('locations').doc(locationParent).collection('pointsOfInterest').doc(docName);
    var data = await document.get(const GetOptions(source: Source.server));
    if (data.exists) {
      var values = data['dislikes'] + 1;
      document.update({'dislikes': values}).then(
              (res) => setState(() { _error = null; }),
          onError: (e) => setState(() { _error = e.toString();})
      );
      if(dec){
        var values = data['likes'] - 1;
        if(values >= 0) {
          document.update({'likes': values}).then(
                  (res) =>
                  setState(() {
                    _error = null;
                  }),
              onError: (e) =>
                  setState(() {
                    _error = e.toString();
                  })
          );
        }
      }

    } else {
      setState(() { _error = "Document doesn't exist";});
    }
  }


  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final POI location = args['poi'];
    final Location locationParent = args['location'];

    final Function(String, int) changeLocationGradeFunction = args['changePoiGradeFunction'];
    dynamic initialLocationGradeValue = args['initialPoiGradeValue'];
    print("location id: " + location.id+ " locationParent id: " + locationParent.id);

    if(initialLocationGradeValue == 1) {
      print("simmmmmmmmmmmmmmmmmmmmmmmmm");
      isLiked = true;
    } else if(initialLocationGradeValue == 2) {
      print("naoooooooooooooooooooooooooooo");
      isLiked = false;
    }
    print("wtffffffffffffffffffffffff-"+initialLocationGradeValue.toString());
    final storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child(location.photoUrl!);

    return Scaffold(

      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    fit: BoxFit.scaleDown,
                  ),
                );
              } else {
                return SizedBox();
              }
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Divider(),
          ),
          initialLocationGradeValue == 1 || initialLocationGradeValue == 2
              ? Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if(!isLiked) {
                      setState(() {
                        changeLocationGradeFunction(location.id, 1);
                        incrementeLikes(locationParent.id,location.name, true);
                        isLiked = true;
                      });
                      showRatingChangedDialog(context);
                    }
                  },
                  icon: Icon(Icons.thumb_up),
                  color: isLiked ? Color(0xFF02458A) : Colors.grey,
                  iconSize: 56.0,
                ),
                SizedBox(width: 16.0),
                IconButton(
                  onPressed: () {
                    if(isLiked) {
                      setState(() {
                        changeLocationGradeFunction(location.id, 2);
                        incrementeDislikes(locationParent.id,location.name, true);
                        isLiked = false;
                      });
                      showRatingChangedDialog(context);
                    }
                  },
                  color: !isLiked ? Color(0xFF02458A) : Colors.grey,
                  icon: Icon(Icons.thumb_down),
                  iconSize: 56.0,
                ),
              ],
            ),
          ): Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      changeLocationGradeFunction(location.id, 1);
                      incrementeLikes(locationParent.id,location.name, false);
                      isLiked = true;
                    });
                    showRatingChangedDialog(context);
                  },
                  icon: Icon(Icons.thumb_up),
                  iconSize: 56.0,
                ),
                SizedBox(width: 16.0),
                IconButton(
                  onPressed: () {
                    setState(() {
                      changeLocationGradeFunction(location.id, 2);
                      incrementeDislikes(locationParent.id,location.name, false);
                      isLiked = false;
                    });
                    showRatingChangedDialog(context);
                  },
                  icon: Icon(Icons.thumb_down),
                  iconSize: 56.0,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(height: 20),
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
        color: Colors.white,
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Created by: ${location.createdBy!}",
              style: const TextStyle(
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

void showRatingChangedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Rate changed!'),
        content: Text('Rate changed with success'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
