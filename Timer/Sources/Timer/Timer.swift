import SwiftUI
import Foundation
import Combine
import AudioToolbox

#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    // MARK: - 상태 변수들
    @State private var isSettingTime = true
    @State private var isTimerRunning = false
    @State private var timer = Foundation.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var selectedSeconds = 0
    
    @State private var totalTimeRemaining = 0
    @State private var initialTotalTime = 1
    
    @State private var showAlert = false
    @State private var animateOcean = false
    
    // [설정] 어두운 회색 정의 (타이머 작동 시 배경)
    let darkGrayColor = Color(red: 0.15, green: 0.15, blue: 0.15)
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // MARK: - 화면 전환 로직
            if isSettingTime {
                // [화면 1] 시간 설정 (배경: 화이트)
                VStack {
                    Text("타이머 설정")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    
                    HStack(spacing: 15) {
                        CustomNumberPicker(value: $selectedHours, range: 0...99, unit: "시", isDarkBackground: false)
                        CustomNumberPicker(value: $selectedMinutes, range: 0...59, unit: "분", isDarkBackground: false)
                        CustomNumberPicker(value: $selectedSeconds, range: 0...59, unit: "초", isDarkBackground: false)
                    }
                }
                .padding()
                
            } else {
                // [화면 2] 타이머 작동 중 (배경: 어두운 회색)
                ZStack {
                    // 1. 바다 스타일 효과
                    if isTimerRunning {
                        OceanEffectRing(animate: $animateOcean)
                    }
                    
                    // 2. 배경 트랙
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                    
                    // 3. 진행률 원
                    Circle()
                        .trim(from: 0.0, to: CGFloat(totalTimeRemaining) / CGFloat(initialTotalTime))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.white)
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.linear(duration: 1.0), value: totalTimeRemaining)
                    
                    // 4. 남은 시간 텍스트
                    Text(formatTime(totalTimeRemaining))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(.white)
                        .padding()
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                }
                .frame(width: 300, height: 300)
                .padding()
                .onTapGesture {
                    hideKeyboard()
                }
            }
            
            Spacer()
            
            // MARK: - 하단 버튼 영역
            HStack(spacing: 20) {
                if isSettingTime {
                    // 시작 버튼
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
                    .tint(Color.blue)
                    
                } else {
                    // 일시정지/계속 버튼
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
                    .tint(isTimerRunning ? Color.cyan : Color.blue)
                    
                    // [수정됨] 취소 버튼: 일시정지와 동일한 UI + 대조적인 색상(빨강)
                    Button(action: {
                        resetToSetting()
                    }) {
                        Text("취소")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent) // 일시정지 버튼과 동일한 스타일
                    .tint(Color.red) // 어두운 배경 및 파란색 버튼과 확실히 대비되는 빨간색
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isSettingTime ? Color.white : darkGrayColor)
        .animation(.easeInOut(duration: 0.3), value: isSettingTime)
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
    
    // MARK: - Helper Functions
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
        animateOcean = false
    }
    
    func formatTime(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// MARK: - Ocean Effect Ring
struct OceanEffectRing: View {
    @Binding var animate: Bool
    
    let oceanGradient = AngularGradient(
        gradient: Gradient(colors: [
            Color(red: 0.0, green: 0.1, blue: 0.5),
            Color.blue,
            Color.cyan,
            Color.teal,
            Color(red: 0.0, green: 0.1, blue: 0.5)
        ]),
        center: .center
    )
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(oceanGradient, lineWidth: 35)
                .blur(radius: 15)
                .rotationEffect(Angle(degrees: animate ? 360 : 0))
                .animation(Animation.linear(duration: 8.0).repeatForever(autoreverses: false), value: animate)
            
            Circle()
                .stroke(oceanGradient, lineWidth: 35)
                .blur(radius: 5)
                .rotationEffect(Angle(degrees: animate ? 360 : 0))
                .animation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false), value: animate)
        }
        .scaleEffect(animate ? 1.05 : 0.95)
        .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animate)
    }
}

// MARK: - Custom Number Picker
struct CustomNumberPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    var isDarkBackground: Bool
    
    @State private var lastDragValue: CGFloat = 0
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
        formatter.maximumIntegerDigits = 2
        formatter.minimum = 0
        formatter.maximum = 99
        return formatter
    }()
    
    var textColor: Color {
        return isDarkBackground ? .white : .black
    }
    
    var body: some View {
        VStack(spacing: 15) {
            
            Text(formatNumber(getPrevValue()))
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundColor(Color.gray.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { gesture in handleDrag(translation: gesture.translation.height) }
                        .onEnded { _ in lastDragValue = 0 }
                )
            
            HStack(spacing: 0) {
                TextField("00", value: $value, formatter: numberFormatter)
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
                    .foregroundColor(textColor)
                    .onChange(of: value) { newValue in
                        if newValue > range.upperBound { value = range.upperBound }
                        if newValue < range.lowerBound { value = range.lowerBound }
                    }
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                
                Text(unit)
                    .font(.system(size: 20))
                    .foregroundColor(textColor)
                    .padding(.bottom, 10)
            }
            
            Text(formatNumber(getNextValue()))
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundColor(Color.gray.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { gesture in handleDrag(translation: gesture.translation.height) }
                        .onEnded { _ in lastDragValue = 0 }
                )
        }
        .frame(width: 100)
        .padding(.vertical, 10)
        .background(isDarkBackground ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    func handleDrag(translation: CGFloat) {
        let step: CGFloat = 30
        let diff = translation - lastDragValue
        if diff > step { decrementValue(); lastDragValue = translation }
        else if diff < -step { incrementValue(); lastDragValue = translation }
    }
    
    func formatNumber(_ number: Int) -> String { String(format: "%02d", number) }
    func incrementValue() { value = (value < range.upperBound) ? value + 1 : range.lowerBound }
    func decrementValue() { value = (value > range.lowerBound) ? value - 1 : range.upperBound }
    func getPrevValue() -> Int { (value > range.lowerBound) ? value - 1 : range.upperBound }
    func getNextValue() -> Int { (value < range.upperBound) ? value + 1 : range.lowerBound }
}

#Preview {
    ContentView()
}