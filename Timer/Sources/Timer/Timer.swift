import SwiftUI
import Foundation // Timer 클래스를 사용하기 위해 명시

// @main 어트리뷰트가 있으면 파일 이름이 main.swift가 아니어도 진입점으로 인식됩니다.
@main
struct TimerExecutable: App { // 구조체 이름을 'Timer'와 겹치지 않게 'TimerExecutable' 등으로 변경
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 300, minHeight: 200)
        }
    }
}

struct ContentView: View {
    @State private var timeRemaining = 60
    @State private var isTimerRunning = false
    
    // [중요] 모듈명(Timer)과의 충돌을 피하기 위해 'Foundation.Timer'라고 명시합니다.
    @State private var timer = Foundation.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // 타이머 제어를 위한 연결 객체
    @State private var cancellable: Any? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("\(timeRemaining)")
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .padding()
            
            HStack(spacing: 20) {
                Button(action: {
                    if isTimerRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(isTimerRunning ? "일시정지" : "시작")
                        .frame(width: 80)
                }
                
                Button(action: {
                    resetTimer()
                }) {
                    Text("초기화")
                        .frame(width: 80)
                }
            }
        }
        .padding()
        // 타이머 이벤트 수신
        .onReceive(timer) { _ in
            if isTimerRunning && timeRemaining > 0 {
                timeRemaining -= 1
            } else if timeRemaining == 0 {
                isTimerRunning = false
            }
        }
        // 앱 시작 시 타이머가 바로 돌지 않도록 초기화
        .onAppear {
            pauseTimer()
        }
    }
    
    func startTimer() {
        isTimerRunning = true
        // 멈춰있던 타이머를 다시 연결 (Upstream connect)
        self.timer = Foundation.Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
    
    func pauseTimer() {
        isTimerRunning = false
        // 타이머 연결 끊기 (타이머 멈춤 효과)
        self.timer.upstream.connect().cancel()
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = 60
    }
}