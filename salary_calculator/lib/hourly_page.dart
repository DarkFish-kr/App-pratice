import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'salary_page.dart';

class HourlyPage extends StatefulWidget {
  const HourlyPage({super.key});

  @override
  State<HourlyPage> createState() => _HourlyPageState();
}

class _HourlyPageState extends State<HourlyPage> {
  // 1. 입력 컨트롤러
  final TextEditingController _hourlyWageController = TextEditingController(
    text: '',
  );
  final TextEditingController _startTimeController = TextEditingController(
    text: '20',
  );
  final TextEditingController _endTimeController = TextEditingController(
    text: '5',
  );

  // 2. 상태 변수
  final List<bool> _isSelectedDays = [
    false,
    true,
    true,
    true,
    true,
    true,
    false,
  ];
  final List<String> _weekDays = ["일", "월", "화", "수", "목", "금", "토"];

  final Set<String> _activeWorkTypes = {};
  bool _isOver5Employees = false;

  // ★ [신규] 에러 메시지 변수들
  String? _wageError; // 시급 에러
  String? _startTimeError; // 시작 시간 에러
  String? _endTimeError; // 종료 시간 에러

  // 3. 결과값 변수
  double weeklyPay = 0;
  double monthlyPay = 0;
  double yearlyPay = 0;

  double basePayResult = 0;
  double holidayPayResult = 0;
  double nightPayResult = 0;

  final currencyFormat = NumberFormat("#,###", "ko_KR");

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  // 🧮 핵심 계산 로직
  void _calculate() {
    setState(() {
      int wage =
          int.tryParse(_hourlyWageController.text.replaceAll(',', '')) ?? 0;

      String startText = _startTimeController.text;
      String endText = _endTimeController.text;

      int startHour = int.tryParse(startText) ?? 0;
      int endHour = int.tryParse(endText) ?? 0;

      // ---------------------------------------------------
      // ★ [유효성 검사 통합] 에러가 하나라도 있으면 계산 중단
      // ---------------------------------------------------
      bool hasError = false;

      // 1. 시급 검사 (10,320원 미만 체크)
      // 입력값이 있고(isNotEmpty), 10320 미만일 경우 에러
      if (_hourlyWageController.text.isNotEmpty && wage < 10320) {
        _wageError = '올해의 시급은 10,320원입니다.\n다시 확인 후 입력해주시기 바랍니다'; // 줄바꿈 적용
        hasError = true;
      } else {
        _wageError = null;
      }

      // 2. 시작 시간 검사 (0~24 범위)
      if (startText.isNotEmpty && (startHour < 0 || startHour > 24)) {
        _startTimeError = '잘못 된 시간을 입력하셨습니다.';
        hasError = true;
      } else {
        _startTimeError = null;
      }

      // 3. 종료 시간 검사 (0~24 범위)
      if (endText.isNotEmpty && (endHour < 0 || endHour > 24)) {
        _endTimeError = '잘못 된 시간을 입력하셨습니다.';
        hasError = true;
      } else {
        _endTimeError = null;
      }

      // ★ 에러 발생 시 모든 결과 0원으로 초기화 후 리턴
      if (hasError) {
        weeklyPay = 0;
        monthlyPay = 0;
        yearlyPay = 0;
        basePayResult = 0;
        holidayPayResult = 0;
        nightPayResult = 0;
        _activeWorkTypes.clear();
        return;
      }

      // ---------------------------------------------------
      // 정상 범위일 때만 계산 수행
      // ---------------------------------------------------

      // 1. 근무 시간 계산
      int duration = 0;
      if (endHour > startHour) {
        duration = endHour - startHour;
      } else if (endHour < startHour) {
        duration = (24 - startHour) + endHour;
      } else {
        duration = 0;
      }

      // 2. 야간 시간 카운팅 & 태그 수집
      double nightHoursCount = 0;
      _activeWorkTypes.clear();

      for (int i = 0; i < duration; i++) {
        int currentHour = (startHour + i) % 24;

        if (currentHour >= 6 && currentHour < 14) {
          _activeWorkTypes.add("오전");
        } else if (currentHour >= 14 && currentHour < 22) {
          _activeWorkTypes.add("오후");
        } else {
          _activeWorkTypes.add("야간");
          nightHoursCount++;
        }
      }

      // 3. 주간 총 근로 시간
      int workingDays = _isSelectedDays.where((day) => day == true).length;
      double weeklyHours = duration * workingDays.toDouble();

      // 4. 기본급
      basePayResult = weeklyHours * wage;

      // 5. 주휴수당
      if (weeklyHours < 15) {
        holidayPayResult = 0;
      } else {
        double holidayHours = 0;
        if (weeklyHours >= 40) {
          holidayHours = 8;
        } else {
          holidayHours = (weeklyHours / 40) * 8;
        }
        holidayPayResult = holidayHours * wage;
      }

      // 6. 야간근로수당
      nightPayResult = 0;
      if (_isOver5Employees && nightHoursCount > 0) {
        double weeklyNightHours = nightHoursCount * workingDays;
        nightPayResult = weeklyNightHours * wage * 0.5;
      }

      // 7. 최종 합계
      weeklyPay = basePayResult + holidayPayResult + nightPayResult;
      monthlyPay = (weeklyPay / 7) * 365 / 12;
      yearlyPay = monthlyPay * 12;
    });
  }

  void _toggleDay(int index) {
    setState(() {
      _isSelectedDays[index] = !_isSelectedDays[index];
      _calculate();
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
                '시급 계산기',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
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

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4B8B8).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 시급 (에러 메시지 연결)
                    _buildInputField(
                      '시급',
                      _hourlyWageController,
                      '원',
                      [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      _wageError, // ★ 시급 에러 전달
                    ),

                    // 에러가 없을 때만 구분선 표시 (디자인 깔끔하게)
                    if (_wageError == null)
                      const Divider(color: Colors.black54),
                    const SizedBox(height: 10),

                    const Text(
                      '근무 일자',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildDaySelector(),
                    const Divider(color: Colors.black54),

                    const SizedBox(height: 10),

                    // 근무 시작 시간
                    _buildInputField(
                      '근무 시작 시간 (0~24시)',
                      _startTimeController,
                      '시',
                      [FilteringTextInputFormatter.digitsOnly],
                      _startTimeError,
                    ),
                    if (_startTimeError == null)
                      const Divider(color: Colors.black54),

                    // 근무 종료 시간
                    _buildInputField(
                      '근무 종료 시간 (0~24시)',
                      _endTimeController,
                      '시',
                      [FilteringTextInputFormatter.digitsOnly],
                      _endTimeError,
                    ),
                    if (_endTimeError == null)
                      const Divider(color: Colors.black54),

                    const SizedBox(height: 10),
                    const Text(
                      '근무 형태 (시간에 따라 자동선택)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildWorkTypeSelector(),

                    if (_activeWorkTypes.contains("야간"))
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _isOver5Employees,
                              activeColor: Colors.black,
                              onChanged: (val) {
                                setState(() {
                                  _isOver5Employees = val ?? false;
                                  _calculate();
                                });
                              },
                            ),
                            const Text(
                              '5인 이상 사업장 (야간수당 적용)',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),
                    const Text(
                      '최종 예상 급여',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    _buildResultRow('주급', weeklyPay),
                    _buildResultRow('월급', monthlyPay),
                    _buildResultRow('연봉', yearlyPay),

                    const SizedBox(height: 10),
                    const Divider(
                      color: Colors.black54,
                      thickness: 1,
                      height: 20,
                    ),

                    _buildDetailRow('• 기본급', basePayResult),
                    _buildDetailRow('• 주휴수당 (15시간↑)', holidayPayResult),
                    if (nightPayResult > 0)
                      _buildDetailRow(
                        '• 야간가산수당 (50%)',
                        nightPayResult,
                        isBonus: true,
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
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  ) {
    String hint = label == '시급' ? '시급을 입력해주세요.' : '0';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          SizedBox(
            // 에러 메시지가 길어서 너비를 조금 더 넉넉하게 줌 (150 -> 160)
            width: 160,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: inputFormatters,
              textAlign: TextAlign.end,
              // ★ 에러 메시지가 길 경우 2줄로 표시하도록 maxLines 설정
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixText: suffix,
                hintText: hint,
                errorText: errorText,
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  height: 1.2,
                ), // 글씨체 조정
                errorMaxLines: 3, // 에러 메시지가 길면 줄바꿈 허용
                hintStyle: TextStyle(
                  color: Colors.black.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
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
          Text(
            label,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
          Text(
            '${currencyFormat.format(value)}원',
            style: const TextStyle(
              decoration: TextDecoration.underline,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, double value, {bool isBonus = false}) {
    Color textColor = (value == 0)
        ? Colors.black38
        : (isBonus ? Colors.blue[800]! : Colors.black54);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 14)),
          Text(
            '${currencyFormat.format(value)}원',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        bool isSelected = _isSelectedDays[index];
        return GestureDetector(
          onTap: () => _toggleDay(index),
          child: CircleAvatar(
            backgroundColor: isSelected ? Colors.black54 : Colors.transparent,
            radius: 16,
            child: Text(
              _weekDays[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWorkTypeSelector() {
    return IgnorePointer(
      ignoring: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTypeButton("오전"),
          const SizedBox(width: 37),
          _buildTypeButton("오후"),
          const SizedBox(width: 37),
          _buildTypeButton("야간"),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type) {
    bool isSelected = _activeWorkTypes.contains(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black87 : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: Colors.black12),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black38,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
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
