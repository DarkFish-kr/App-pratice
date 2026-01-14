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
    
    // 저장소 키 (Key)
    let saveKey = "SavedMarineCreatures"
    
    // MARK: - 2. [시각 UX] 심해 잠수 효과 (Deep Dive Gradient)
    var dynamicBackgroundColor: Color {
        if isSettingTime {
            return Color.white
        } else {
            let progress = 1.0 - (totalTimeRemaining / initialTotalTime)
            
            // Deep Gray -> Abyss Black
            let startR: Double = 0.2, startG: Double = 0.25, startB: Double = 0.35
            let endR: Double = 0.02, endG: Double = 0.02, endB: Double = 0.05
            
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
                        HStack {
                            Text("나의 바다 🌊")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            // (선택사항) 초기화 버튼: 테스트용
                            if !collectedCreatures.isEmpty {
                                Button("방생하기") {
                                    collectedCreatures.removeAll()
                                    saveData() // 삭제 후 저장
                                }
                                .font(.caption2)
                                .foregroundColor(.red.opacity(0.5))
                            }
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 10)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                if collectedCreatures.isEmpty {
                                    Text("집중을 완료하고 바다 친구들을 모아보세요!")
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding()
                                } else {
                                    // 최신순으로 보여주기 위해 reversed() 사용
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
                .onAppear {
                    loadData() // 앱 시작 시(또는 화면 나타날 시) 데이터 불러오기
                }
                
            } else {
                // [화면 2] 타이머 작동 중
                ZStack {
                    if isTimerRunning { OceanEffectRing(animate: $animateOcean) }
                    
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(totalTimeRemaining) / CGFloat(initialTotalTime))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.white)
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.linear(duration: 1.0), value: totalTimeRemaining)
                    
                    VStack {
                        Text(formatTime(Int(ceil(totalTimeRemaining))))
                            .font(.system(size: 60, weight: .bold, design: .monospaced))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 2)
                        
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
                .onTapGesture { hideKeyboard() }
            }
            
            Spacer()
            
            // MARK: - 하단 버튼 영역
            HStack(spacing: 20) {
                if isSettingTime {
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
                    .keyboardShortcut(.defaultAction)
                    
                } else {
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
                    .keyboardShortcut(.space, modifiers: [])
                    
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
                    .keyboardShortcut(.cancelAction)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(dynamicBackgroundColor)
        .animation(.easeInOut(duration: 1.0), value: dynamicBackgroundColor)
        .onTapGesture { hideKeyboard() }
        .alert(isPresented: $showRewardAlert) {
            Alert(
                title: Text("집중 완료! 🎉"),
                message: Text("심해 탐험을 마치고 새로운 친구를 만났습니다.\n획득: \(newCreature)"),
                dismissButton: .default(Text("확인"), action: {
                    resetToSetting()
                })
            )
        }
        .onReceive(timer) { _ in
            if !isSettingTime && isTimerRunning {
                if totalTimeRemaining > 0 {
                    totalTimeRemaining -= 1
                } else {
                    finishTimer()
                }
            }
        }
    }
    
    // MARK: - 3. 로직 함수들 (데이터 저장 포함)
    
    func finishTimer() {
        isTimerRunning = false
        animateOcean = false
        playAlarmSound()
        
        if let creature = marineLife.randomElement() {
            newCreature = creature
            collectedCreatures.append(creature)
            saveData() // [저장] 새로운 생물 획득 시 즉시 저장
        }
        
        showRewardAlert = true
    }
    
    // [데이터 저장] UserDefaults에 배열 저장
    func saveData() {
        // UserDefaults는 배열을 직접 저장할 수 없으므로 JSON 데이터로 변환
        if let encoded = try? JSONEncoder().encode(collectedCreatures) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    // [데이터 로드] 앱 켜질 때 불러오기
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
            let decoded = try? JSONDecoder().decode([String].self, from: data) {
            collectedCreatures = decoded
        }
    }
    
    func playBubbleSound() { AudioServicesPlaySystemSound(1103) }
    
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

// MARK: - Ocean Effect Ring & Picker (변동 없음)
struct OceanEffectRing: View {
    @Binding var animate: Bool
    let oceanGradient = AngularGradient(
        gradient: Gradient(colors: [Color(red: 0, green: 0.1, blue: 0.5), Color.blue, Color.cyan, Color.teal, Color(red: 0, green: 0.1, blue: 0.5)]),
        center: .center
    )
    var body: some View {
        ZStack {
            Circle().stroke(oceanGradient, lineWidth: 35).blur(radius: 15).rotationEffect(Angle(degrees: animate ? 360 : 0))
                .animation(Animation.linear(duration: 8.0).repeatForever(autoreverses: false), value: animate)
            Circle().stroke(oceanGradient, lineWidth: 35).blur(radius: 5).rotationEffect(Angle(degrees: animate ? 360 : 0))
                .animation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false), value: animate)
        }
        .scaleEffect(animate ? 1.05 : 0.95).animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animate)
    }
}

struct CustomNumberPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    var isDarkBackground: Bool
    @State private var lastDragValue: CGFloat = 0
    let numberFormatter: NumberFormatter = {
        let f = NumberFormatter(); f.minimumIntegerDigits = 2; f.maximumIntegerDigits = 2; return f
    }()
    
    var textColor: Color { isDarkBackground ? .white : .black }
    
    var body: some View {
        VStack(spacing: 15) {
            Text(formatNumber(getPrevValue())).font(.system(size: 30, weight: .medium, design: .rounded)).foregroundColor(Color.gray.opacity(0.5)).frame(maxWidth: .infinity).frame(height: 40).contentShape(Rectangle())
                .gesture(DragGesture().onChanged { g in handleDrag(translation: g.translation.height) }.onEnded { _ in lastDragValue = 0 })
            HStack(spacing: 0) {
                TextField("00", value: $value, formatter: numberFormatter).font(.system(size: 50, weight: .bold, design: .rounded)).multilineTextAlignment(.center).frame(width: 70).foregroundColor(textColor)
                    .onChange(of: value) { n in if n > range.upperBound { value = range.upperBound }; if n < range.lowerBound { value = range.lowerBound } }
                Text(unit).font(.system(size: 20)).foregroundColor(textColor).padding(.bottom, 10)
            }
            Text(formatNumber(getNextValue())).font(.system(size: 30, weight: .medium, design: .rounded)).foregroundColor(Color.gray.opacity(0.5)).frame(maxWidth: .infinity).frame(height: 40).contentShape(Rectangle())
                .gesture(DragGesture().onChanged { g in handleDrag(translation: g.translation.height) }.onEnded { _ in lastDragValue = 0 })
        }
        .frame(width: 100).padding(.vertical, 10).background(isDarkBackground ? Color.white.opacity(0.1) : Color.gray.opacity(0.1)).cornerRadius(15)
    }
    func handleDrag(translation: CGFloat) {
        let step: CGFloat = 30; let diff = translation - lastDragValue
        if diff > step { decrementValue(); lastDragValue = translation } else if diff < -step { incrementValue(); lastDragValue = translation }
    }
    func formatNumber(_ n: Int) -> String { String(format: "%02d", n) }
    func incrementValue() { value = value < range.upperBound ? value + 1 : range.lowerBound }
    func decrementValue() { value = value > range.lowerBound ? value - 1 : range.upperBound }
    func getPrevValue() -> Int { value > range.lowerBound ? value - 1 : range.upperBound }
    func getNextValue() -> Int { value < range.upperBound ? value + 1 : range.lowerBound }
}

#Preview { ContentView() }
