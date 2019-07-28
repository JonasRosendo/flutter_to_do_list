import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _taskList = [];
  Map<String, dynamic> lastRemoved;
  int lastRemovedPosition;

  final _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _taskList = json.decode(data);
      });
    });
  }

  void _addTask() {
    setState(() {
      Map<String, dynamic> newTaskMap = Map();
      newTaskMap['title'] = _taskController.text;
      _taskController.text = "";
      newTaskMap["done"] = false;
      _taskList.add(newTaskMap);
      _saveData();
    });
  }

  Future<Null> refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _taskList.sort((a, b){
        if(a["done"] && !b["done"]) return 1;
        else if(!a["done"] && b["done"]) return -1;
        else return 0;
      });

      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("To-Do List"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                        labelText: "New Task",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addTask,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(child: ListView.builder(
              padding: EdgeInsets.only(top: 10.0),
              itemCount: _taskList.length,
              itemBuilder: buildList,
            ), onRefresh: refresh),
          ),
        ],
      ),
    );
  }

  Widget buildList(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_taskList[index]["title"]),
        value: _taskList[index]["done"],
        secondary: CircleAvatar(
          child: Icon(_taskList[index]["done"] ? Icons.check : Icons.error),
        ),
        onChanged: (bool c) {
          setState(() {
            _taskList[index]["done"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          lastRemoved = Map.from(_taskList[index]);
          lastRemovedPosition = index;
          _taskList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(label: "Desfazer", onPressed: () {
              setState(() {
                _taskList.insert(lastRemovedPosition, lastRemoved);
                _saveData();
              });
            }),
            duration: Duration(seconds: 5),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_taskList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      e.toString();
      return null;
    }
  }
}
