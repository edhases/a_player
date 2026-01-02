import 'package:flutter/material.dart';
import 'package:vor_player/src/rust/api/simple.dart'; // Переконайся, що шлях правильний
import 'package:vor_player/src/rust/frb_generated.dart';

Future<void> main() async {
  // Ініціалізація мосту між Dart та Rust
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Прибираємо стрічку "Debug"
      theme: ThemeData.dark(), // Темна тема за замовчуванням
      home: Scaffold(
        backgroundColor: Colors.black, // Стиль Poweramp (Глибокий чорний)
        body: Center(
          child: AudioControl(),
        ),
      ),
    );
  }
}

class AudioControl extends StatefulWidget {
  @override
  _AudioControlState createState() => _AudioControlState();
}

class _AudioControlState extends State<AudioControl> {
  String status = "Ready";
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Технічний текст статусу
        Text(
          status,
          style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 18,
              fontFamily: "Courier", // Моноширинний шрифт для "техно" вигляду
              fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(height: 50),

        // Кнопка керування (Стилізована під Poweramp)
        GestureDetector(
          onTap: () async {
            if (isPlaying) {
              // Викликаємо Rust функцію зупинки
              // Оскільки функція синхронна в Rust, тут вона поверне результат миттєво
              var res = stopAudio();
              setState(() {
                status = res; // "Audio Stopped"
                isPlaying = false;
              });
            } else {
              // Викликаємо Rust функцію старту
              var res = startSineWave();
              setState(() {
                status = res; // "Audio Started! (440Hz)"
                isPlaying = true;
              });
            }
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPlaying ? Colors.cyanAccent.withOpacity(0.1) : Colors.grey[900],
              border: Border.all(
                color: isPlaying ? Colors.cyanAccent : Colors.grey.shade800,
                width: 3,
              ),
              boxShadow: isPlaying ? [
                BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 2
                )
              ] : [],
            ),
            child: Icon(
              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 80,
              color: isPlaying ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}