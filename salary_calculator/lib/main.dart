import 'package:flutter/material.dart';
import 'hourly_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '급여 계산기',
      debugShowCheckedModeBanner: false, // 디버그 띠 제거
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // 배경색 흰색
        fontFamily: 'AppleSDGothicNeo', // 맥 기본 폰트 (설치된 경우)
      ),
      home: const HourlyPage(), // 앱 실행 시 시급 계산기 먼저 표시
    );
  }
}
