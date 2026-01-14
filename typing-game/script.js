// ==========================================
// 1. 데이터 저장소
// ==========================================
const DATA = {
    ko: {
        consonants: [
            "ㅁ", "ㄴ", "ㅇ", "ㄹ", "ㅎ", 
            "ㅂ", "ㅈ", "ㄷ", "ㄱ", "ㅅ", 
            "ㅋ", "ㅌ", "ㅊ", "ㅍ"
        ],
        vowels: [
            "ㅗ", "ㅓ", "ㅏ", "ㅣ", 
            "ㅛ", "ㅕ", "ㅑ", "ㅐ", "ㅔ", 
            "ㅠ", "ㅜ", "ㅡ"
        ],
        words: [
            "사과", "바나나", "포도", "수박", "복숭아",
            "자동차", "비행기", "자전거", "기차", "버스",
            "서울", "부산", "대구", "광주", "대전",
            "하늘", "구름", "바람", "태양", "달",
            "학교", "선생님", "친구", "공부", "운동"
        ],
        sentences: [
            "가는 말이 고와야 오는 말이 곱다.",
            "낮말은 새가 듣고 밤말은 쥐가 듣는다.",
            "천 리 길도 한 걸음부터 시작한다.",
            "호랑이도 제 말 하면 온다.",
            "코딩은 논리적인 사고를 기르는 훈련입니다."
        ],
        long: [
            "별 헤는 밤 - 윤동주\n계절이 지나가는 하늘에는 가을로 가득 차 있습니다. 나는 아무 걱정도 없이 가을 속의 별들을 다 헤일 듯합니다.",
            "소나기 - 황순원\n소년은 개울가에서 소녀를 보자 곧 윤 초시네 증손녀딸이라는 걸 알 수 있었다. 소녀는 개울에다 손을 잠그고 물장난을 하고 있는 것이다."
        ]
    },
    en: {
        consonants: [
            "a", "s", "d", "f", "j", "k", "l", ";"
        ],
        vowels: [
            "q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
            "z", "x", "c", "v", "b", "n", "m"
        ],
        words: [
            "apple", "banana", "cherry", "date", "elderberry",
            "red", "green", "blue", "yellow", "purple",
            "cat", "dog", "bird", "fish", "rabbit",
            "one", "two", "three", "four", "five",
            "spring", "summer", "autumn", "winter"
        ],
        sentences: [
            "The quick brown fox jumps over the lazy dog.",
            "Actions speak louder than words.",
            "Keep calm and carry on.",
            "Knowledge is power.",
            "Time is money."
        ],
        long: [
            "Steve Jobs Speech\nYour time is limited, so don't waste it living someone else's life. Don't be trapped by dogma which is living with the results of other people's thinking.",
            "Harry Potter\nMr. and Mrs. Dursley, of number four, Privet Drive, were proud to say that they were perfectly normal, thank you very much."
        ]
    }
};

// ==========================================
// 2. 상태 변수
// ==========================================
let currentLang = 'ko';     
let currentLevel = 'consonants';
let startTime; 
let timerInterval;
let isTyping = false;
let nextQuoteText = null; 

// ==========================================
// 3. DOM 요소
// ==========================================
const quoteDisplayElement = document.getElementById('quoteDisplay');
const nextQuoteDisplayElement = document.getElementById('nextQuoteDisplay');
const quoteInputElement = document.getElementById('quoteInput');
const timerElement = document.getElementById('timer');
const cpmElement = document.getElementById('cpm'); 
const accuracyElement = document.getElementById('accuracy');

const langKoBtn = document.getElementById('lang-ko');
const langEnBtn = document.getElementById('lang-en');
const subBtns = document.querySelectorAll('.sub-btn');

const btnConsonants = document.getElementById('btn-consonants');
const btnVowels = document.getElementById('btn-vowels');
const btnWords = document.getElementById('btn-words');
const btnSentences = document.getElementById('btn-sentences');
const btnLong = document.getElementById('btn-long');

// ==========================================
// 4. 기능 함수
// ==========================================

function changeLang(lang) {
    currentLang = lang;
    
    if (lang === 'ko') {
        langKoBtn.classList.add('active');
        langEnBtn.classList.remove('active');
        quoteInputElement.placeholder = "입력하려면 여기를 클릭하세요...";
        
        btnConsonants.innerText = "자음";
        btnVowels.innerText = "모음";
        btnWords.innerText = "낱말";
        btnSentences.innerText = "단문";
        btnLong.innerText = "장문";
    } else {
        langEnBtn.classList.add('active');
        langKoBtn.classList.remove('active');
        quoteInputElement.placeholder = "Click here to type...";
        
        btnConsonants.innerText = "Home Row";
        btnVowels.innerText = "Top/Bot";
        btnWords.innerText = "Words";
        btnSentences.innerText = "Sentences";
        btnLong.innerText = "Paragraphs";
    }
    
    nextQuoteText = null;
    renderNewQuote();
}

function changeLevel(level) {
    currentLevel = level;
    subBtns.forEach(btn => {
        if(btn.getAttribute('onclick').includes(level)) {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    });
    
    nextQuoteText = null;
    renderNewQuote();
}

function getRandomQuote() {
    const dataList = DATA[currentLang][currentLevel];
    return dataList[Math.floor(Math.random() * dataList.length)];
}

// 게임 로직
function renderNewQuote() {
    // 1. 스타일 조정
    if (currentLevel === 'consonants' || currentLevel === 'vowels') {
        quoteDisplayElement.classList.add('single-char');
    } else {
        quoteDisplayElement.classList.remove('single-char');
    }

    // 2. 입력창 스타일 초기화 (노란 불 끄기)
    quoteInputElement.classList.remove('finished');

    let quote;

    if (!nextQuoteText) {
        quote = getRandomQuote();
        nextQuoteText = getRandomQuote();
    } else {
        quote = nextQuoteText;
        nextQuoteText = getRandomQuote();
    }

    quoteDisplayElement.innerHTML = '';
    quote.split('').forEach(character => {
        const characterSpan = document.createElement('span');
        characterSpan.innerText = character;
        quoteDisplayElement.appendChild(characterSpan);
    });
    
    nextQuoteDisplayElement.innerText = nextQuoteText;

    quoteInputElement.value = null;
    resetGame();
}

// [NEW] 엔터 키 감지 이벤트 리스너 추가
quoteInputElement.addEventListener('keydown', (e) => {
    // 사용자가 누른 키가 'Enter' 인지 확인
    if (e.key === 'Enter') {
        e.preventDefault(); // 줄바꿈 방지

        const arrayQuote = quoteDisplayElement.querySelectorAll('span');
        const arrayValue = quoteInputElement.value.split('');

        // 입력한 길이가 원본 길이보다 길거나 같으면 다음으로 넘어감
        if (arrayValue.length >= arrayQuote.length) {
            renderNewQuote();
        }
    }
});

// 입력 이벤트 (실시간 색상 변경 및 완료 체크)
quoteInputElement.addEventListener('input', () => {
    if (!isTyping) {
        startTimer();
        isTyping = true;
    }

    const arrayQuote = quoteDisplayElement.querySelectorAll('span');
    const arrayValue = quoteInputElement.value.split('');

    let correctCount = 0;
    
    arrayQuote.forEach((characterSpan, index) => {
        const character = arrayValue[index];

        if (character == null) {
            characterSpan.classList.remove('correct');
            characterSpan.classList.remove('incorrect');
        } else if (character === characterSpan.innerText) {
            characterSpan.classList.add('correct');
            characterSpan.classList.remove('incorrect');
            correctCount++;
        } else {
            characterSpan.classList.remove('correct');
            characterSpan.classList.add('incorrect');
        }
    });

    updateStats(correctCount, arrayValue.length);

    // [수정] 자동 넘김 제거 -> 대신 '완료 상태' 시각적 표시
    if (arrayValue.length >= arrayQuote.length) {
        quoteInputElement.classList.add('finished'); // CSS에서 테두리 색 변경
    } else {
        quoteInputElement.classList.remove('finished');
    }
});

// 통계 및 타이머
function updateStats(correctCount, totalTyped) {
    let accuracy = 0;
    if (totalTyped > 0) {
        accuracy = (correctCount / totalTyped) * 100;
    }
    accuracyElement.innerText = Math.round(accuracy);

    const timeInSeconds = getTimerTime();
    if (timeInSeconds > 0) {
        const timeInMinutes = timeInSeconds / 60;
        const cpm = totalTyped / timeInMinutes;
        cpmElement.innerText = Math.round(cpm);
    } else {
        cpmElement.innerText = 0;
    }
}

function startTimer() {
    startTime = new Date();
    timerInterval = setInterval(() => {
        timerElement.innerText = getTimerTime();
        if (quoteInputElement.value.length > 0) {
            const correctChars = document.querySelectorAll('.correct').length;
            updateStats(correctChars, quoteInputElement.value.length);
        }
    }, 1000);
}

function resetGame() {
    if (timerInterval) clearInterval(timerInterval);
    timerElement.innerText = 0;
    cpmElement.innerText = 0;
    accuracyElement.innerText = 100;
    isTyping = false;
    startTime = null;
    quoteInputElement.classList.remove('finished'); // 리셋 시 스타일 제거
}

function getTimerTime() {
    return Math.floor((new Date() - startTime) / 1000);
}

// 초기화
renderNewQuote();