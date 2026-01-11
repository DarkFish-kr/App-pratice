import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 숫자 포맷팅용
import 'salary_page.dart';

class HourlyPage extends StatefulWidget {
  const HourlyPage({super.key});

  @override
  State<HourlyPage> createState() => _HourlyPageState();
}

class _HourlyPageState extends State<HourlyPage> {
  // 금액 포맷터 (예: 10,320)
  final currencyFormat = NumberFormat("#,###", "ko_KR");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 상단 헤더
              const Text(
                '시급 계산기',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // 연봉 계산기로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SalaryPage()),
                  );
                },
                child: const Text(
                  '연봉 계산기로 이동하기',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              // 메인 카드 (분홍색)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4B8B8).withOpacity(0.7), // 디자인의 분홍색
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputRow('시급', '10,320원'),
                    const Divider(color: Colors.black54),
                    const SizedBox(height: 10),

                    const Text(
                      '근무 일자',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildDaySelector(), // 요일 선택 위젯
                    const Divider(color: Colors.black54),

                    const SizedBox(height: 10),
                    const Text(
                      '근무 형태',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildWorkTypeSelector(), // 근무 형태 위젯
                    const Divider(color: Colors.black54),

                    _buildInputRow('근무 시간', '8시간'),
                    const Divider(color: Colors.black54),

                    const SizedBox(height: 20),
                    const Text(
                      '최종 월급',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // 결과 표시 영역
                    _buildResultRow('주급', '495,360원'),
                    _buildResultRow('월급', '1,981,440원'),
                    _buildResultRow('연봉', '23,777,280원'),
                    _buildResultRow('예상 주휴시간', '8시간'),
                    _buildResultRow('예상 주휴수당', '82,560원'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '2026년 최저시급 : 10,320원',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 입력 필드 위젯 빌더
  Widget _buildInputRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  // 결과 행 위젯 빌더
  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(
            value,
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }

  // 요일 선택기 (단순 UI용)
  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ["일", "월", "화", "수", "목", "금", "토"].map((day) {
        bool isSelected = (day == "수"); // 예시로 '수'요일만 선택된 상태 표현
        return CircleAvatar(
          backgroundColor: isSelected ? Colors.black54 : Colors.transparent,
          radius: 16,
          child: Text(
            day,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black),
          ),
        );
      }).toList(),
    );
  }

  // 근무 형태 선택기 (단순 UI용)
  Widget _buildWorkTypeSelector() {
    return Row(
      children: [
        Chip(label: const Text('오전'), backgroundColor: Colors.black26),
        const SizedBox(width: 10),
        Chip(label: const Text('오후'), backgroundColor: Colors.black26),
        const SizedBox(width: 10),
        const Text('야간'),
      ],
    );
  }
}
