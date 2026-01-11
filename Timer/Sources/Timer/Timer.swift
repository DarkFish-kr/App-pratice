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
    
    // [추가] 불꽃 애니메이션 회전을 위한 상태 변수
    @State private var animateFire = false
    
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
                // [화면 2] 타이머 작동 중 (불꽃 및 프로그레스 바)
                ZStack {
                    // [추가 1] 불이 타오르는 효과 (가장 뒤쪽 배경)
                    // 타이머가 작동 중일 때만 나타납니다.
                    if isTimerRunning {
                        BurningFireRing(animate: $animateFire)
                    }
                    
                    // 2. 회색 배경 원 (트랙)
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.1)
                        .foregroundColor(Color.gray)
                    
                    // 3. 진행률 원 (시간에 따라 줄어듬)
                    // 불꽃이 너무 강렬해서 진행바가 잘 안 보일 수 있으니 색상을 흰색으로 변경하여 가독성을 높였습니다.
                    Circle()
                        .trim(from: 0.0, to: CGFloat(totalTimeRemaining) / CGFloat(initialTotalTime))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.white.opacity(0.8)) // [변경] 흰색 반투명
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.linear(duration: 1.0), value: totalTimeRemaining)
                    
                    // 4. 남은 시간 텍스트
                    Text(formatTime(totalTimeRemaining))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding()
                        // [추가] 불꽃 배경 위에서도 잘 보이도록 그림자 추가
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
                    // [추가] 시작 버튼도 불타는 색상(주황/빨강)으로 변경
                    .tint(Color.orange) 
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
                    // [추가] 상태에 따른 버튼 색상 변경
                    .tint(isTimerRunning ? Color.red.opacity(0.8) : Color.orange)
                    
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
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
            // [추가] 타이머 시작 시 불꽃 애니메이션 트리거
            // 약간의 딜레이를 주어 화면 전환 후 자연스럽게 시작되도록 함
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateFire = true
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
        animateFire = false // [추가] 리셋 시 애니메이션 정지
    }
    
    func formatTime(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// --- [새로 추가된 컴포넌트] 활활 타오르는 불꽃 고리 ---
struct BurningFireRing: View {
    @Binding var animate: Bool
    
    // 불꽃 색상 그라데이션 정의 (빨강 -> 주황 -> 노랑 -> 주황 -> 빨강)
    let fireGradient = AngularGradient(
        gradient: Gradient(colors: [Color.red, Color.orange, Color.yellow, Color.orange, Color.red]),
        center: .center
    )
    
    var body: some View {
        ZStack {
            // [Layer 1] 바깥쪽 고리 (시계 방향으로 천천히 회전)
            Circle()
                .stroke(fireGradient, lineWidth: 35) // 두께를 두껍게
                .blur(radius: 8) // 블러 효과로 불꽃처럼 번지게 표현
                .rotationEffect(Angle(degrees: animate ? 360 : 0))
                // 무한 반복 애니메이션
                .animation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false), value: animate)
            
            // [Layer 2] 안쪽 고리 (반시계 방향으로 조금 더 빠르게 회전)
            Circle()
                .stroke(fireGradient, lineWidth: 35)
                .blur(radius: 8)
                // 반대 방향 회전 (-360도) 및 다른 속도 (duration 3.0)로 혼돈스러운 불길 표현
                .rotationEffect(Angle(degrees: animate ? -360 : 0))
                .animation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false), value: animate)
        }
        // 전체적으로 약간 커졌다 작아졌다 하는 숨쉬는 효과 추가
        .scaleEffect(animate ? 1.05 : 0.95)
        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
    }
}

// --- 커스텀 피커 (기존과 동일) ---
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
                .foregroundColor(Color.gray.opacity(0.3))
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
                    .foregroundColor(Color.black)
                    .onChange(of: value) { newValue in
                        if newValue > range.upperBound { value = range.upperBound }
                        if newValue < range.lowerBound { value = range.lowerBound }
                    }
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                
                Text(unit)
                    .font(.system(size: 20))
                    .foregroundColor(Color.black)
                    .padding(.bottom, 10)
            }
            
            Text(formatNumber(getNextValue()))
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundColor(Color.gray.opacity(0.3))
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
        .background(Color.gray.opacity(0.05))
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