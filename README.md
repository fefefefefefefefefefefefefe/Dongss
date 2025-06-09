# Dongss
졸업작품 웹 프로젝트






## 🎯 우리가 만드는 구조: 웹앱 풀스택

[프론트엔드(Web App)]  ←→  [백엔드(Node.js, Express, Socket.IO)]  ←→  [MySQL]
        ↑ (React 등)                 ↑ (API + 실시간)                  ↑ (DB)
        
1️⃣ 프론트엔드 (웹앱)

React, Vue, 또는 기본 JS/HTML로 가능

실시간 데이터 받을 때는 Socket.IO 클라이언트 사용

댓글, 피드, 게시판, 채팅 등 UI 구현


2️⃣ 백엔드

Node.js + Express: API 서버

Socket.IO: 실시간 소켓 통신

MySQL: 데이터 저장(피드, 유저, 댓글 등)

3️⃣ MySQL

데이터베이스: Workbench로 테이블 설계/관리

🟢 실전 개발 순서 추천

MySQL & Workbench 설치
→ 테이블 설계/생성

Node.js 프로젝트 생성
→ express, socket.io, mysql2 등 설치
→ 서버 코드 작성, API/실시간 기능 구현

프론트엔드 프로젝트 생성 (React 추천)
→ Create React App 또는 Vite로 빠르게 시작
→ Socket.IO 클라이언트 설치 후, 실시간 데이터 UI 구현
