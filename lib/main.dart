import 'package:music_player/src/player_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyMusicBoxApp());
}

class MyMusicBoxApp extends StatelessWidget {
  const MyMusicBoxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Music Box',
      theme: ThemeData(
        primaryColor: Colors.red.shade200,
      ),
      home: PlayerPage(buildContext: context),
    );
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({Key? key, required this.buildContext}) : super(key: key);
  final BuildContext buildContext;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late String filePath;
  late PlayerWidget _playerWidget;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      filePath =
          'https://firebasestorage.googleapis.com/v0/b/codelab-assets.appspot.com/o/firebase-song.mp3?alt=media&token=44d4fc4f-20f6-40e0-998b-f9cf033a7d07';
    } else {
      filePath = 'better-together.mp3';
    }

    _playerWidget = PlayerWidget(url: filePath, context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Box'),
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade200,
              Colors.red.shade300,
            ],
          ),
        ),
        child: ListView(
          children: <Widget>[
            SizedBox(
              child: Center(
                  child: Container(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      spreadRadius: 8,
                      blurRadius: 16,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.asset(
                    'assets/better-together.png',
                    width: (MediaQuery.of(context).size.width * 0.8),
                    fit: BoxFit.contain,
                  ),
                ),
              )),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: const Center(
                child: Text(
                  'A Firebase Song',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: const BorderRadius.all(Radius.circular(25.0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [_playerWidget],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
