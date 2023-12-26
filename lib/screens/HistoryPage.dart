
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tp_flutter/screens/poi/POIDetails.dart';

import '../models/POI.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.title});
  static const String routeName = '/HistoryPage';
  final String title;

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<POI> historyList = [];
  StreamController<List<POI>> _historyStreamController = StreamController<List<POI>>();


  @override
  void initState() {
    super.initState();
    _loadHistoryStream();
  }
  void _loadHistoryStream() async {
    await loadHistory(); // Load historyList
    _historyStreamController.add(historyList);
  }
  @override
  void dispose() {
    _historyStreamController.close();
    super.dispose();
  }
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
  void deleteHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('history');
    setState(() {
      historyList = [];
    });
    _historyStreamController.add([]); // Adicione essa linha para notificar a StreamBuilder

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
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              deleteHistory();
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          StreamBuilder<List<POI>>(
            stream: _historyStreamController.stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print("sem net");
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                print("erro");
                return Center(child: Text('Error: ${snapshot.error}'));
              } /*else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                print("what");
                return const Center(child: CircularProgressIndicator());
              }*/ else {
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
                                      POIDetailPage.routeName,
                                      /*arguments: {
                                        'location': location,
                                        'poi': snapshot.data![index],
                                        'changePoiGradeFunction': setSharedPreferences,
                                        'initialPoiGradeValue': allSharedPreferences?[snapshot.data![index].id] as int? ?? -1,
                                      }*/
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