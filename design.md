# DET Tool First Page Design Guide

이 문서는 DET 계열 툴의 첫 페이지(진입 화면)를 동일한 기준으로 설계하기 위한 공통 디자인 규칙이다.
기준 출처는 D:\MyProject\FillBlank\DET_Tool.md의 디자인 시스템 섹션이다.

## 1) 공통 원칙
- 모든 툴은 ReadSpeak 스타일을 원형으로 사용한다.
- 모바일 우선 레이아웃을 유지한다.
- 데스크톱에서도 모바일 폭으로 보이도록 중앙 정렬한다.
- 외부 라이브러리(CDN 포함) 없이 동작 가능한 구조를 우선한다.

## 2) 색상 토큰 (공통)
```css
:root {
  --blue:   #3B82F6;
  --blue-d: #2563EB;
  --orange: #F59E0B;
  --red:    #EF4444;
  --green:  #10B981;
  --text:   #111827;
  --dim:    #9CA3AF;
  --border: #E5E7EB;
  --panel:  #F9FAFB;
}
```

## 3) 레이아웃 기준
```css
.screen {
  position: fixed;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
}

@media (min-width: 520px) {
  .screen {
    max-width: 480px;
    left: 50%;
    transform: translateX(-50%);
    border-left:  1px solid var(--border);
    border-right: 1px solid var(--border);
  }
}
```

## 4) 공통 컴포넌트 스펙
- 주 버튼: 높이 52px, radius 14px, 16px/700, 배경 --blue
- 보조 버튼: 높이 48px, radius 12px, 배경 --panel, 테두리 --border
- 카드: radius 12px, 1.5px --border, padding 18px 20px
- 타이머: 52px/800, 색상 --text
- 프로그레스바: 높이 5px, 색상 --orange, transition 0.9s linear
- 탭 하이라이트: -webkit-tap-highlight-color: transparent

## 5) 첫 페이지 고정 구조
모든 툴의 첫 페이지는 아래 순서를 기본 구조로 사용한다.

1. 응원/상태 한 줄 카피 (선택)
2. 툴 제목 (H1)
3. 부제/설명 한 줄
4. 유형 배지(예: 유형 2)
5. 간단한 안내 문장 1~2줄
6. 요약 지표 2~3개 카드 (시간, 문제 수, 문장 수 등)
7. 핵심 전략 카드
8. 흔한 실수 카드
9. 하단 고정 시작 버튼(Primary CTA)

## 6) 타이포그래피
- 기본 폰트 스택: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif
- 제목은 명확하고 두껍게(700~800), 본문은 400~500 유지
- 첫 페이지는 정보 밀도를 높이지 말고 즉시 시작 가능 상태를 우선한다

## 7) 상태/행동 규칙
- Primary 버튼은 페이지에서 가장 강조되는 요소로 유지
- 위험/주의 정보는 빨강 계열, 전략/가이드는 노랑 계열 카드 사용
- 텍스트 대비는 WCAG 가독성 수준을 만족하도록 유지

## 8) 화면 전환 규칙
- 멀티 화면은 .hidden 토글 기반으로 전환한다.
- 페이지 이동 없이 fixed screen 전환 패턴을 유지한다.
- 화면 id 예시: #home, #prep, #rec, #result

## 9) 첫 페이지 QA 체크리스트
- 모바일(360~430px)에서 깨짐 없이 보이는가
- 데스크톱에서 중앙 480px 프레임으로 보이는가
- 시작 버튼이 첫 화면에서 즉시 인지되는가
- 전략/주의 카드 위계가 명확한가
- 색상/간격/카드 반경이 공통 토큰과 일치하는가

## 10) 적용 범위
- 이 문서는 DET 계열 모든 툴의 첫 페이지에 우선 적용한다.
- 기능별 개별 요소가 필요해도 1~9의 공통 기준을 먼저 만족해야 한다.
