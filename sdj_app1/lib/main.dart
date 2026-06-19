import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color.fromARGB(255, 111, 223, 223)),
      ),
      home: const MyHomePage(title: 'しおんapp'),
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
  int _counter = 1;
  String _message = '(message)';
  String _joke = '(joke)';
  SharedPreferences? _sp;

  void _setCounter(x) {
    setState( () {
      _counter = x;
    } );
    _sp?.setInt('count',_counter);
  }

  @override
  void initState() {          //asyncは時間がかかるよって意味
    SharedPreferences.getInstance().then( (sp) {
      _sp = sp;
      setState((){
        _counter = _sp?.getInt('count') ?? 1;
      });
    });
    final ref = FirebaseFirestore.instance.collection('app_data').doc('current');
    ref.snapshots().listen(  (ss){
      if (ss.exists) {
        final data = ss.data();
        setState((){
        _message = data?['message'] ?? _message;
        });
      }
    });

    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,          //上の部分
            child: Row(
              children: [
                Expanded(flex:3, child: Image.network("https://picsum.photos/seed/$_counter/400/300")),          //上の左部分
                Expanded(          //上の右部分
                  flex:1,
                  child: Column(
                    children: [
                      FittedBox(          //上の右部分の1つ目
                        child: Text(
                          "count=${_counter}",
                          style: TextStyle(fontSize: 20),
                        )
                      ),
                      Expanded(          //2つ目
                        child:ElevatedButton(
                          child: Text("+1"),
                          onPressed: () => _setCounter(_counter + 1),
                        )
                      ),
                      Expanded(          //3つ目
                        child:ElevatedButton(
                          child: Text("-1"),
                          onPressed: () => _setCounter(_counter - 1),
                        )
                      ),
                      Expanded(          //4つ目
                        child:ElevatedButton(
                          child: Icon(Icons.refresh),
                          onPressed: () => _setCounter(1),
                        )
                      ),
                      Expanded(          //4つ目
                        child:ElevatedButton(
                          child: Text("joke"),
                          onPressed: () async{
                            final r = await http.get(
                              Uri.parse(
                                "https://v2.jokeapi.dev/joke/Programming?type=single",
                              ),
                            );
                            final m =
                                jsonDecode(r.body) as Map<String, dynamic>;
                            setState(() {
                            _joke = m['joke'] ?? _joke;
                            });
                          },
                        )
                      ),
                    ],
                  )
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2, 
            child: Column(
              children: [
                Expanded(child: Text(_joke)),
                Expanded(child: Text(_message)),
                Expanded(child: TextField(
                    onSubmitted: (s){
                      final db = FirebaseFirestore.instance;
                      db.collection("app_data").doc("current").set({
                        "message": s
                      });

                      final data = {'message': s, 'name': 'SHION'};
                      final url = Uri.parse(
                        'https://97759f37-a044-4fd6-93c9-535dec286571-00-p9gmu9n8nec3.riker.replit.dev/api/messages',
                      );

                      http.post(
                        url,
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(data),
                      );


                    },
                )),
              ],
            ),
          ),      //下の部分
        ],
      ),
    );
  }
}
