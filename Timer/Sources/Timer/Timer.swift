import SwiftUI
import Foundation
import Combine
import AudioToolbox

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 메인 뷰
struct ContentView: View {
    // MARK: - 1. 상태 변수들
    @State private var isSettingTime = true
    @State private var isTimerRunning = false
    @State private var timer = Foundation.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var selectedSeconds = 0
    
    @State private var totalTimeRemaining: Double = 0
    @State private var initialTotalTime: Double = 1
    
    @State private var animateOcean = false
    
    // [게이미피케이션] 수집한 해양 생물 리스트
    @State private var collectedCreatures: [String] = []
    @State private var showRewardAlert = false
    @State private var newCreature = ""
    
    // 해양 생물 도감 (랜덤 획득용)
    let marineLife = ["🐠", "🐟", "🐡", "🦈", "🐋", "🐳", "🐬", "🐙", "🦑", "🦐", "🦞", "🦀", "🐚", "🪸", "🦦"]
    
    // MARK: - 2. [시각 UX] 심해 잠수 효과 (Deep Dive Gradient)
    // 시간이 지날수록 배경이 더 어두워지는 계산 속성
    var dynamicBackgroundColor: Color {
        if isSettingTime {
            return Color.white
        } else {
            // 진행률 (0.0 ~ 1.0)
            let progress = 1.0 - (totalTimeRemaining / initialTotalTime)
            
            // 시작 색상: 어두운 회색 (Deep Gray)
            let startR: Double = 0.2
            let startG: Double = 0.25
            let startB: Double = 0.35
            
            // 종료 색상: 거의 완전한 검정 (Abyss Black)
            let endR: Double = 0.02
            let endG: Double = 0.02
            let endB: Double = 0.05
            
            // 색상 보간 (Interpolation)
            let r = startR + (endR - startR) * progress
            let g = startG + (endG - startG) * progress
            let b = startB + (endB - startB) * progress
            
            return Color(red: r, green: g, blue: b)
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // MARK: - 화면 전환 로직
            if isSettingTime {
                // [화면 1] 설정 및 도감 화면
                VStack(spacing: 40) {
                    VStack {
                        Text("타이머 설정")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                        
                        HStack(spacing: 15) {
                            CustomNumberPicker(value: $selectedHours, range: 0...99, unit: "시", isDarkBackground: false)
                            CustomNumberPicker(value: $selectedMinutes, range: 0...59, unit: "분", isDarkBackground: false)
                            CustomNumberPicker(value: $selectedSeconds, range: 0...59, unit: "초", isDarkBackground: false)
                        }
                    }
                    
                    // [게이미피케이션] 나의 바다 (수집품 보관함)
                    VStack(alignment: .leading) {
                        Text("나의 바다 🌊")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .padding(.leading, 10)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                if collectedCreatures.isEmpty {
                                    Text("집중을 완료하고 바다 친구들을 모아보세요!")
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding()
                                } else {
                                    ForEach(collectedCreatures.reversed(), id: \.self) { creature in
                                        Text(creature)
                                            .font(.system(size: 40))
                                            .padding(5)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 60)
                    }
                    .padding(.horizontal)
                }
                .padding()
                
            } else {
                // [화면 2] 타이머 작동 중 (심해 잠수 효과)
                ZStack {
                    // 1. 바다 스타일 링
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
                    VStack {
                        Text(formatTime(Int(ceil(totalTimeRemaining))))
                            .font(.system(size: 60, weight: .bold, design: .monospaced))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 2)
                        
                        // 심해 깊이 표현 (재미 요소)
                        if isTimerRunning {
                            Text("현재 수심: \(Int((1.0 - totalTimeRemaining/initialTotalTime) * 1000))m")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 5)
                        }
                    }
                    .padding()
                }
                .frame(width: 300, height: 300)
                .padding()
                .onTapGesture {
                    hideKeyboard()
                }
            }
            
            Spacer()
            
            // MARK: - 하단 버튼 영역 (키보드 단축키 포함)
            HStack(spacing: 20) {
                if isSettingTime {
                    // 시작 버튼
                    Button(action: {
                        playBubbleSound()
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
                    // [키보드 단축키] Space, Enter로 시작
                    .keyboardShortcut(.defaultAction)
                    
                } else {
                    // 일시정지/계속 버튼
                    Button(action: {
                        playBubbleSound()
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
                    // [키보드 단축키] Space로 일시정지/재개
                    .keyboardShortcut(.space, modifiers: [])
                    
                    // 취소 버튼
                    Button(action: {
                        playBubbleSound()
                        resetToSetting()
                    }) {
                        Text("취소")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    // [키보드 단축키] ESC로 취소
                    .keyboardShortcut(.cancelAction)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        // [시각 UX] 동적 배경색 적용
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(dynamicBackgroundColor)
        .animation(.easeInOut(duration: 1.0), value: dynamicBackgroundColor)
        .onTapGesture {
            hideKeyboard()
        }
        // [보상 알림] 타이머 완주 시
        .alert(isPresented: $showRewardAlert) {
            Alert(
                title: Text("집중 완료! 🎉"),
                message: Text("심해 탐험을 마치고 새로운 친구를 만났습니다.\n획득: \(newCreature)"),
                dismissButton: .default(Text("확인"), action: {
                    resetToSetting()
                })
            )
        }
        // 타이머 로직
        .onReceive(timer) { _ in
            if !isSettingTime && isTimerRunning {
                if totalTimeRemaining > 0 {
                    totalTimeRemaining -= 1
                } else {
                    // 타이머 종료 (0초)
                    finishTimer()
                }
            }
        }
    }
    
    // MARK: - 3. 로직 함수들
    
    func finishTimer() {
        isTimerRunning = false
        animateOcean = false
        
        // 알람 소리 재생
        playAlarmSound()
        
        // [게이미피케이션] 랜덤 해양 생물 뽑기 및 저장
        if let creature = marineLife.randomElement() {
            newCreature = creature
            collectedCreatures.append(creature)
        }
        
        showRewardAlert = true
    }
    
    // [청각 UX] 버튼 클릭 시 물방울 소리 (System Sound 1103: Tink)
    func playBubbleSound() {
        AudioServicesPlaySystemSound(1103)
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
        // Double 타입으로 변환
        totalTimeRemaining = Double((selectedHours * 3600) + (selectedMinutes * 60) + selectedSeconds)
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

// MARK: - Ocean Effect Ring (동일)
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

// MARK: - Custom Number Picker (동일)
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
