import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'hourly_page.dart';

class SalaryPage extends StatefulWidget {
  const SalaryPage({super.key});

  @override
  State<SalaryPage> createState() => _SalaryPageState();
}

class _SalaryPageState extends State<SalaryPage> {
  // 1. 입력 컨트롤러
  final TextEditingController _salaryController = TextEditingController(
    text: '',
  );
  final TextEditingController _taxFreeController = TextEditingController(
    text: '',
  );
  final TextEditingController _dependentsController = TextEditingController(
    text: '1',
  );
  final TextEditingController _childrenController = TextEditingController(
    text: '0',
  );

  // 자녀 수 에러 메시지
  String? _childrenError;

  // 2. 결과값 변수
  double nationalPension = 0;
  double healthInsurance = 0;
  double careInsurance = 0;
  double employmentInsurance = 0;
  double incomeTax = 0;
  double localTax = 0;

  double totalDeduction = 0;
  double monthlyNetPay = 0;
  double yearlyNetPay = 0;

  final currencyFormat = NumberFormat("#,###", "ko_KR");

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  // 🧮 핵심 계산 로직
  void _calculate() {
    setState(() {
      // 1. 입력값 파싱
      double yearlySalary =
          double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0;
      double yearlyTaxFree =
          double.tryParse(_taxFreeController.text.replaceAll(',', '')) ?? 0;
      int dependents = int.tryParse(_dependentsController.text) ?? 1;
      int children = int.tryParse(_childrenController.text) ?? 0;

      // 유효성 검사: 부양가족수 > 자녀수
      if (dependents <= children) {
        _childrenError = '자녀 수는 전체 부양가족 수보다 적어야 합니다.';
        // 에러 시 초기화
        nationalPension = 0;
        healthInsurance = 0;
        careInsurance = 0;
        employmentInsurance = 0;
        incomeTax = 0;
        localTax = 0;
        totalDeduction = 0;
        monthlyNetPay = 0;
        yearlyNetPay = 0;
        return;
      } else {
        _childrenError = null;
      }

      // 2. 과세 대상 급여 계산
      double yearlyTaxable = yearlySalary - yearlyTaxFree;
      if (yearlyTaxable < 0) yearlyTaxable = 0;

      double monthlyTaxable = yearlyTaxable / 12;

      // 3. 4대 보험 계산

      // 국민연금 (4.75%, 상한 286,650원)
      nationalPension = monthlyTaxable * 0.0475;
      if (nationalPension > 286650) {
        nationalPension = 286650;
      }

      healthInsurance = monthlyTaxable * 0.03595;
      careInsurance = healthInsurance * 0.1314;
      employmentInsurance = monthlyTaxable * 0.009;

      // 4. 소득세 계산 (간이세액표 약식)
      double taxBase =
          monthlyTaxable -
          (nationalPension + healthInsurance + employmentInsurance);
      if (taxBase < 0) taxBase = 0;

      if (taxBase < 1060000) {
        incomeTax = 0;
      } else if (taxBase < 2500000) {
        incomeTax = taxBase * 0.015;
      } else if (taxBase < 4000000) {
        incomeTax = taxBase * 0.035;
      } else if (taxBase < 6000000) {
        incomeTax = taxBase * 0.065;
      } else {
        incomeTax = taxBase * 0.12;
      }

      // 부양가족 공제
      double familyDeduction = (dependents - 1) * 5000.0 + (children * 10000.0);
      incomeTax -= familyDeduction;
      if (incomeTax < 0) incomeTax = 0;

      // 지방소득세
      localTax = incomeTax * 0.1;

      // 5. 최종 결과
      totalDeduction =
          nationalPension +
          healthInsurance +
          careInsurance +
          employmentInsurance +
          incomeTax +
          localTax;

      double monthlyGrossSalary = yearlySalary / 12;
      monthlyNetPay = monthlyGrossSalary - totalDeduction;

      // ★ [수정됨] 연 실수령액 계산 시 286,650원 차감
      // (월 실수령액 * 12) - 286,650
      yearlyNetPay = (monthlyNetPay * 12) - 286650;

      // 혹시라도 계산 결과가 음수가 되지 않도록 방어 코드
      if (yearlyNetPay < 0) yearlyNetPay = 0;
    });
  }

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
                    _buildInputField(
                      '연봉',
                      _salaryController,
                      '원',
                      '연봉을 입력해주세요',
                      [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      null,
                    ),
                    const Divider(color: Colors.black54),

                    _buildInputField(
                      '비과세액 (연간 총액)',
                      _taxFreeController,
                      '원',
                      '0',
                      [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      null,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                      child: Text(
                        '* 대표적인 비과세 항목인 식대는 월 20만원까지입니다.\n  (그 외 항목은 급여명세서를 확인해주세요)',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.black54),

                    _buildInputField(
                      '부양가족수 (본인포함)',
                      _dependentsController,
                      '명',
                      '1',
                      [FilteringTextInputFormatter.digitsOnly],
                      null,
                    ),
                    const Divider(color: Colors.black54),

                    _buildInputField(
                      '20세 이하 자녀 수',
                      _childrenController,
                      '명',
                      '0',
                      [FilteringTextInputFormatter.digitsOnly],
                      _childrenError,
                    ),
                    if (_childrenError == null)
                      const Divider(color: Colors.black54),

                    const SizedBox(height: 20),

                    _buildResultRow('국민연금 (4.75%)', nationalPension),
                    _buildResultRow('건강보험 (3.595%)', healthInsurance),
                    _buildSubResultRow('장기요양 (13.14%)', careInsurance),
                    _buildResultRow('고용보험 (0.9%)', employmentInsurance),
                    _buildResultRow('근로소득세(간이세액)', incomeTax),
                    _buildSubResultRow('지방소득세 (10%)', localTax),

                    const SizedBox(height: 10),
                    const Divider(color: Colors.black54, thickness: 1),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '년 예상 실수령액',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${currencyFormat.format(yearlyNetPay)}원',
                          style: const TextStyle(
                            color: Colors.red,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '• 월 환산 금액',
                          style: TextStyle(color: Colors.red),
                        ),
                        Text(
                          '${currencyFormat.format(monthlyNetPay)}원',
                          style: const TextStyle(
                            color: Colors.red,
                            decoration: TextDecoration.underline,
                            fontSize: 16,
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
    String hintText,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 150,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixText: suffix,
                hintText: hintText,
                errorText: errorText,
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  height: 1.0,
                ),
                hintStyle: TextStyle(
                  color: Colors.black.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (value) => _calculate(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${currencyFormat.format(value)}원',
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }

  Widget _buildSubResultRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('• $label', style: const TextStyle(color: Colors.black54)),
          Text(
            '${currencyFormat.format(value)}원',
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String newText = newValue.text.replaceAll(',', '');
    int value = int.tryParse(newText) ?? 0;
    final formatter = NumberFormat('#,###');
    String newString = formatter.format(value);
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
