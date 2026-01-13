import SwiftUI
import Foundation
import Combine
import AudioToolbox

#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @State private var isSettingTime = true
    @State private var isTimerRunning = false
    @State private var timer = Foundation.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var selectedSeconds = 0
    
    @State private var totalTimeRemaining = 0
    @State private var initialTotalTime = 1 
    
    @State private var showAlert = false
    
    // [변경] 바다 효과 애니메이션 상태 변수 (이전: animateFire)
    @State private var animateOcean = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if isSettingTime {
                // [화면 1] 시간 설정
                HStack(spacing: 15) {
                    CustomNumberPicker(value: $selectedHours, range: 0...99, unit: "시")
                    CustomNumberPicker(value: $selectedMinutes, range: 0...59, unit: "분")
                    CustomNumberPicker(value: $selectedSeconds, range: 0...59, unit: "초")
                }
                .padding()
            } else {
                // [화면 2] 타이머 작동 중 (바다 효과 및 프로그레스 바)
                ZStack {
                    // [변경 1] 바다 스타일 효과 (가장 뒤쪽 배경)
                    // 타이머가 작동 중일 때만 나타납니다.
                    if isTimerRunning {
                        OceanEffectRing(animate: $animateOcean)
                    }
                    
                    // 2. 회색 배경 원 (트랙)
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.1)
                        .foregroundColor(Color.gray)
                    
                    // 3. 진행률 원 (시간에 따라 줄어듬)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(totalTimeRemaining) / CGFloat(initialTotalTime))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.white.opacity(0.9)) // 바다색 위에서 잘 보이도록 흰색 강조
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.linear(duration: 1.0), value: totalTimeRemaining)
                    
                    // 4. 남은 시간 텍스트
                    Text(formatTime(totalTimeRemaining))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(.white) // 텍스트도 흰색으로
                        .padding()
                        // 배경 위에서 잘 보이도록 그림자 추가
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                }
                .frame(width: 300, height: 300)
                .padding()
                .onTapGesture {
                    hideKeyboard()
                }
            }
            
            Spacer()
            
            // 하단 버튼 영역
            HStack(spacing: 20) {
                if isSettingTime {
                    Button(action: {
                        startTimerFromSetting()
                    }) {
                        Text("타이머 시작")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    // [변경] 시작 버튼 색상을 바다 컨셉(파란색)으로 변경
                    .tint(Color.blue) 
                } else {
                    Button(action: {
                        if isTimerRunning { pauseTimer() } else { resumeTimer() }
                    }) {
                        Text(isTimerRunning ? "일시정지" : "계속")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    // [변경] 상태에 따른 버튼 색상 (작동중: 청록 / 정지: 파랑)
                    .tint(isTimerRunning ? Color.cyan : Color.blue)
                    
                    Button(action: {
                        resetToSetting()
                    }) {
                        Text("취소")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        // [변경] 전체 배경색을 검정으로 설정하여 바다 효과 극대화
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black) 
        .onTapGesture {
            hideKeyboard()
        }
        .alert("타이머 종료", isPresented: $showAlert) {
            Button("확인", role: .cancel) {
                resetToSetting()
            }
        } message: {
            Text("설정하신 시간이 모두 지났습니다.")
        }
        .onReceive(timer) { _ in
            if !isSettingTime && isTimerRunning {
                if totalTimeRemaining > 0 {
                    totalTimeRemaining -= 1
                } else {
                    isTimerRunning = false
                    playAlarmSound()
                    showAlert = true
                }
            }
        }
    }
    
    func playAlarmSound() {
        AudioServicesPlaySystemSound(1005)
        #if os(iOS)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        #endif
    }
    
    func hideKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    func startTimerFromSetting() {
        hideKeyboard()
        totalTimeRemaining = (selectedHours * 3600) + (selectedMinutes * 60) + selectedSeconds
        
        initialTotalTime = totalTimeRemaining > 0 ? totalTimeRemaining : 1
        
        if totalTimeRemaining > 0 {
            isSettingTime = false
            resumeTimer()
            // 타이머 시작 시 바다 애니메이션 트리거
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateOcean = true
            }
        }
    }
    
    func resumeTimer() {
        isTimerRunning = true
        self.timer = Foundation.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
    
    func pauseTimer() {
        isTimerRunning = false
        self.timer.upstream.connect().cancel()
    }
    
    func resetToSetting() {
        pauseTimer()
        isSettingTime = true
        animateOcean = false // 리셋 시 애니메이션 정지
    }
    
    func formatTime(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// --- [새로 교체된 컴포넌트] 바다 스타일 효과 링 (Ocean Effect Ring) ---
struct OceanEffectRing: View {
    @Binding var animate: Bool
    
    // 심해(Deep Blue) ~ 표층(Cyan) 그라데이션 색상
    let oceanGradient = AngularGradient(
        gradient: Gradient(colors: [
            Color(red: 0.0, green: 0.1, blue: 0.5), // 심해색
            Color.blue,
            Color.cyan,                             // 얕은 바다색
            Color.teal,
            Color(red: 0.0, green: 0.1, blue: 0.5)  // 자연스러운 연결
        ]),
        center: .center
    )
    
    var body: some View {
        ZStack {
            // [Layer 1] 배경 글로우 (물속 빛 번짐 효과)
            Circle()
                .stroke(oceanGradient, lineWidth: 35)
                .blur(radius: 15) // 부드럽게 퍼지는 느낌
                .rotationEffect(Angle(degrees: animate ? 360 : 0))
                .animation(Animation.linear(duration: 8.0).repeatForever(autoreverses: false), value: animate)
            
            // [Layer 2] 메인 물결 (선명한 링)
            Circle()
                .stroke(oceanGradient, lineWidth: 35)
                .blur(radius: 5)
                // 천천히 회전하며 심해의 흐름 표현
                .rotationEffect(Angle(degrees: animate ? 360 : 0))
                .animation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false), value: animate)
        }
        // 물결이 숨쉬는 듯한 스케일 효과
        .scaleEffect(animate ? 1.05 : 0.95)
        .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animate)
    }
}

// --- 커스텀 피커 (기존 코드 유지) ---
struct CustomNumberPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    
    @State private var lastDragValue: CGFloat = 0
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
        formatter.maximumIntegerDigits = 2
        formatter.minimum = 0
        formatter.maximum = 99
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 15) {
            
            Text(formatNumber(getPrevValue()))
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundColor(Color.gray.opacity(0.5)) // 배경이 검정이므로 가독성 조정
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            handleDrag(translation: gesture.translation.height)
                        }
                        .onEnded { _ in
                            lastDragValue = 0
                        }
                )
            
            HStack(spacing: 0) {
                TextField("00", value: $value, formatter: numberFormatter)
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
                    .foregroundColor(Color.white) // 배경 검정이므로 흰색으로 변경
                    .onChange(of: value) { newValue in
                        if newValue > range.upperBound { value = range.upperBound }
                        if newValue < range.lowerBound { value = range.lowerBound }
                    }
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                
                Text(unit)
                    .font(.system(size: 20))
                    .foregroundColor(Color.white) // 배경 검정이므로 흰색으로 변경
                    .padding(.bottom, 10)
            }
            
            Text(formatNumber(getNextValue()))
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundColor(Color.gray.opacity(0.5)) // 배경이 검정이므로 가독성 조정
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            handleDrag(translation: gesture.translation.height)
                        }
                        .onEnded { _ in
                            lastDragValue = 0
                        }
                )
        }
        .frame(width: 100)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.1)) // 배경을 반투명 흰색으로 조정
        .cornerRadius(15)
    }
    
    func handleDrag(translation: CGFloat) {
        let step: CGFloat = 30
        let diff = translation - lastDragValue
        
        if diff > step {
            decrementValue()
            lastDragValue = translation
        } else if diff < -step {
            incrementValue()
            lastDragValue = translation
        }
    }
    
    func formatNumber(_ number: Int) -> String {
        return String(format: "%02d", number)
    }
    
    func incrementValue() {
        if value < range.upperBound { value += 1 } else { value = range.lowerBound }
    }
    
    func decrementValue() {
        if value > range.lowerBound { value -= 1 } else { value = range.upperBound }
    }
    
    func getPrevValue() -> Int {
        return value > range.lowerBound ? value - 1 : range.upperBound
    }
    
    func getNextValue() -> Int {
        return value < range.upperBound ? value + 1 : range.lowerBound
    }
}

#Preview {
    ContentView()
}