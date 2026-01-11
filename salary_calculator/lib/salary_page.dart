import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'hourly_page.dart';

class SalaryPage extends StatefulWidget {
  const SalaryPage({super.key});

  @override
  State<SalaryPage> createState() => _SalaryPageState();
}

class _SalaryPageState extends State<SalaryPage> {
  final TextEditingController _salaryController = TextEditingController(
    text: '25000000',
  );
  final currencyFormat = NumberFormat("#,###", "ko_KR");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            children: [
              const Text(
                '연봉 계산기',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HourlyPage()),
                  );
                },
                child: const Text(
                  '시급 계산기로 이동하기',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFBDE0FE).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField('연봉', _salaryController, '원'),
                    const Divider(color: Colors.black54),

                    _buildStaticInputRow('비과세액', '0원'),
                    const Divider(color: Colors.black54),

                    _buildStaticInputRow('부양가족수 (본인포함)', '1명'),
                    const Divider(color: Colors.black54),

                    _buildStaticInputRow('20세 이하 자녀 수', '0명'),
                    const Divider(color: Colors.black54),

                    const SizedBox(height: 20),

                    _buildResultRow('국민연금 (4.5%)', '98,950원'),
                    _buildResultRow('건강보험 (3.545%)', '74,890원'),
                    _buildSubResultRow('지방소득세 (10%)', '9,840원'),
                    _buildResultRow('고용보험 (0.9%)', '18,750원'),
                    _buildResultRow('근로소득세(간이세액)', '22,090원'),
                    _buildSubResultRow('지방소득세 (10%)', '2,200원'),

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('년 예상 실수령액', style: TextStyle(color: Colors.red)),
                        Text(
                          '22,279,360원',
                          style: TextStyle(
                            color: Colors.red,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('• 월 환산 금액', style: TextStyle(color: Colors.red)),
                        Text(
                          '1,856,613원',
                          style: TextStyle(
                            color: Colors.red,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String suffix,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            width: 150,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              decoration: InputDecoration(suffixText: suffix),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticInputRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }

  Widget _buildSubResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('• $label', style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
