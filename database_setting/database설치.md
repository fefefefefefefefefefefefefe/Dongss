# Donstory DataBase 설정

1. Nodejs 설치
   
   URL : https://nodejs.org/ko
   
---

2. mySQL 설치
   
   URL : https://dev.mysql.com/downloads/installer/
   

![image](https://github.com/user-attachments/assets/4b9ec385-55f6-4b3e-a610-b0adc71484f6)


Next 클릭

![image](https://github.com/user-attachments/assets/00270d3a-b00c-432f-bf45-2d918b52387a)

그대로 next 클릭

![image](https://github.com/user-attachments/assets/e3e0b431-28fe-472a-9e3a-0aab50366880)

비밀번호 설정 한 후에 next 클릭

![image](https://github.com/user-attachments/assets/09e83e14-ec04-4450-8c7c-5b241ac179bd)

next 클릭

![image](https://github.com/user-attachments/assets/429e64e8-75bc-4e06-a98b-5abb38fcfeec)

next 클릭

![image](https://github.com/user-attachments/assets/7f1bb1ba-7732-4cbf-9dc7-68f6e6200e38)

Execute 클릭

![image](https://github.com/user-attachments/assets/5bf7cbaf-b8a9-4f1f-a36e-a8370c11c756)

password에다가 비밀번호 입력 후에 next

--- 

### node.js 명령어

win + R 
cmd입력 후

mkdir sns-backed
cd sns-backed
npm init -y

![image](https://github.com/user-attachments/assets/ffc37742-d14a-482e-92d7-c8477e08d13c)


---

### VSCODE 활용

**0. 패키지 설치(cmd)**

| **pip installs**  |  설명 |
|--------------|----------|
|  npm install bcryptjs jsonwebtoken |  회원가입 & 로그인 기능  |
|                                    |          |




**1. VScode TERMINAL에서  입력**

| **pip installs**  |
|--------------|
|  npm init -y  |
|  npm install express mysql2 cors dotenv  |
|  npm install socket.io  |




![image](https://github.com/user-attachments/assets/620a7883-d43a-4eff-ac2e-efc5178bd115)

---
# DongStory 스키마 요약표

| 테이블명            | 주요 컬럼/기능                                                      |
|---------------------|---------------------------------------------------------------------|
| user                | id, username, password, name, nickname, profile_img, email, ...     |
| follow              | follower_id, following_id, created_at                               |
| community           | id, name, description, admin_id, is_private, created_at             |
| post                | id, user_id, community_id, title, content, is_anonymous, ...        |
| post_file           | id, post_id, file_url, file_type, is_thumbnail, uploaded_at          |
| tag                 | id, name                                                            |
| post_tag            | post_id, tag_id                                                     |
| comment             | id, post_id, user_id, content, parent_id, is_anonymous, ...         |
| post_like           | id, post_id, user_id, created_at                                    |
| comment_like        | id, comment_id, user_id, created_at                                 |
| emoji               | id, name                                                            |
| post_reaction       | post_id, user_id, emoji_id, created_at                              |
| chat_room           | id, name, is_group, created_at                                      |
| chat_room_user      | id, chatroom_id, user_id, left_at                                   |
| chat_message        | id, chatroom_id, sender_id, message, file_url, is_deleted, ...      |
| notification        | id, user_id, type, message, is_read, source_user_id, ...            |
| report              | id, reporter_id, target_type, target_id, reason, created_at         |
| user_block          | id, user_id, blocked_user_id, created_at                            |
| profile_visit       | id, visitor_id, profile_user_id, visited_at                         |
| search_history      | id, user_id, keyword, searched_at                                   |
| feed_cache          | id, user_id, post_id, score, created_at                             |
| file_report         | id, file_id, reporter_id, reason, created_at                        |



---

### DataBase 최종 테이블/기능 설명 

| 테이블명                 | 주요 컬럼/기능                                                                                                                                                                | 설명                                            |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| **user**             | id, username, password, name, nickname, profile\_img, bio, email, gender, email\_verified, status, website, location, birthday, oauth\_provider, oauth\_id, created\_at | 회원의 기본 정보와 프로필, 상태, 외부 로그인 정보 등               |
| **follow**           | follower\_id, following\_id, created\_at                                                                                                                                | 팔로우(친구) 관계 정보. 팔로워-팔로잉 관계                     |
| **community**        | id, name, description, admin\_id, is\_private, created\_at                                                                                                              | 커뮤니티(게시판) 정보. 이름/설명/관리자/공개 여부 등               |
| **post**             | id, user\_id, community\_id, title, content, is\_anonymous, visibility, view\_count, comment\_count, is\_blinded, is\_deleted, created\_at, updated\_at                 | 게시글(작성자/커뮤니티/제목/내용/익명/공개범위/조회수/블라인드/삭제/수정일 등) |
| **post\_file**       | id, post\_id, file\_url, file\_type, is\_thumbnail, uploaded\_at                                                                                                        | 게시글 첨부파일/이미지(대표 이미지 포함, 여러 파일 가능)             |
| **tag**              | id, name                                                                                                                                                                | 태그 목록(예: #질문, #후기 등)                          |
| **post\_tag**        | post\_id, tag\_id                                                                                                                                                       | 게시글별 태그 연결(한 게시글에 여러 태그 가능)                   |
| **comment**          | id, post\_id, user\_id, content, parent\_id, is\_anonymous, is\_blinded, is\_deleted, created\_at, updated\_at                                                          | 댓글 및 대댓글(작성자, 상위댓글, 익명/블라인드/삭제/수정 등)          |
| **post\_like**       | id, post\_id, user\_id, created\_at, unique\_post\_like                                                                                                                 | 게시글 좋아요(누가 어느 글을 좋아했는지)                       |
| **comment\_like**    | id, comment\_id, user\_id, created\_at, unique\_comment\_like                                                                                                           | 댓글 좋아요(누가 어느 댓글을 좋아했는지)                       |
| **emoji**            | id, name                                                                                                                                                                | 이모지(리액션) 목록(#좋아요, #웃음 등)                      |
| **post\_reaction**   | post\_id, user\_id, emoji\_id, created\_at, PRIMARY KEY(post\_id, user\_id, emoji\_id)                                                                                  | 게시글별 다양한 이모지(리액션) 반응 정보                       |
| **chat\_room**       | id, name, is\_group, created\_at                                                                                                                                        | 채팅방 정보(이름, 그룹 여부 등)                           |
| **chat\_room\_user** | id, chatroom\_id, user\_id, left\_at                                                                                                                                    | 채팅방 참여자 정보(나간 시점 포함)                          |
| **chat\_message**    | id, chatroom\_id, sender\_id, message, file\_url, is\_deleted, created\_at                                                                                              | 채팅 메시지(내용/파일/삭제 등)                            |
| **notification**     | id, user\_id, type, message, is\_read, source\_user\_id, related\_post\_id, related\_comment\_id, chat\_message\_id, chat\_room\_id, created\_at                        | 알림(댓글/좋아요/채팅/팔로우 등, 읽음 여부, 관련 활동 정보 포함)       |
| **report**           | id, reporter\_id, target\_type, target\_id, reason, created\_at                                                                                                         | 신고(누가, 무엇을, 왜 신고했는지)                          |
| **user\_block**      | id, user\_id, blocked\_user\_id, created\_at, unique\_block                                                                                                             | 차단(누가, 누구를 차단했는지)                             |
| **profile\_visit**   | id, visitor\_id, profile\_user\_id, visited\_at                                                                                                                         | 프로필 방문 기록(누가, 누구 프로필을, 언제 방문)                 |
| **search\_history**  | id, user\_id, keyword, searched\_at                                                                                                                                     | 사용자별 검색 기록(검색 키워드, 시각 등)                      |
| **feed\_cache**      | id, user\_id, post\_id, score, created\_at                                                                                                                              | 추천 피드/포스트 캐시(추천 점수 기반, 맞춤 피드 등에 활용)           |
| **file\_report**     | id, file\_id, reporter\_id, reason, created\_at                                                                                                                         | 게시글 첨부파일 신고(악성 이미지, 파일 등 대응)                  |

---


















---
### DataBase 명령어.


**1. DB생성**
CREATE DATABASE sns_db DEFAULT CHARACTER SET utf8mb4;
USE sns_db;

**2. 테이블 만들기**

-- 0. 필수: 문자 인코딩(utf8mb4) 세팅 (선택)
SET NAMES utf8mb4;


-- 1. 테이블 수정 

외래키 제약 켜기
   - SET FOREIGN_KEY_CHECKS = 1;


외래키 제약 끄기
   - SET FOREIGN_KEY_CHECKS = 0;

   

 : 외래키가 되어있으면 함부로 테이블을 삭제할 수 없기 때문에 해놓았다.
 
-- 문자 인코딩 설정(선택)
SET NAMES utf8mb4;

-- 1. 회원(프로필, 자기소개, 상태 등 포함)

-- 기본 로그인/식별 정보만
CREATE TABLE user (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    nickname VARCHAR(50) UNIQUE,
    status ENUM('active', 'inactive', 'suspended', 'deleted') DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 확장 프로필
CREATE TABLE user_profile (
    user_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    profile_img VARCHAR(255),
    bio TEXT,
    gender VARCHAR(10),
    website VARCHAR(255),
    location VARCHAR(100),
    birthday DATE,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
);

-- 소셜(OAuth) 연동
CREATE TABLE user_oauth (
    user_id INT PRIMARY KEY,
    oauth_provider VARCHAR(50),
    oauth_id VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
);

-- 인증/보안
CREATE TABLE user_security (
    user_id INT PRIMARY KEY,
    email_verified BOOLEAN DEFAULT FALSE,
    last_login_at DATETIME DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
);

---

-- 2. 팔로우(친구) 관계
CREATE TABLE follow (
    follower_id INT NOT NULL,
    following_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, following_id),
    FOREIGN KEY (follower_id) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (following_id) REFERENCES user(id) ON DELETE CASCADE
);
---
-- 3. 커뮤니티(게시판)
CREATE TABLE community (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255),
    admin_id INT,
    is_private BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES user(id)
);
---
-- 4. 게시글
CREATE TABLE post (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    community_id INT NOT NULL,
    title VARCHAR(100),
    content TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE,
    visibility ENUM('public', 'followers', 'private') DEFAULT 'public',
    view_count INT DEFAULT 0,
    comment_count INT DEFAULT 0,
    is_blinded BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (community_id) REFERENCES community(id) ON DELETE CASCADE
);
---
-- 5. 첨부파일(게시글)
CREATE TABLE post_file (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    file_url VARCHAR(255),
    file_type VARCHAR(30),
    is_thumbnail BOOLEAN DEFAULT FALSE,
    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES post(id) ON DELETE CASCADE
);
---
-- 6. 태그/해시태그
CREATE TABLE tag (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);
---
CREATE TABLE post_tag (
    post_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY(post_id, tag_id),
    FOREIGN KEY (post_id) REFERENCES post(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tag(id) ON DELETE CASCADE
);
---
-- 7. 댓글/대댓글
CREATE TABLE comment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT,
    parent_id INT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    is_blinded BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT NULL,
    FOREIGN KEY (post_id) REFERENCES post(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES comment(id) ON DELETE CASCADE
);
---
-- 8. 좋아요/공감 (게시글/댓글)
CREATE TABLE post_like (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_post_like (post_id, user_id),
    FOREIGN KEY (post_id) REFERENCES post(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
);
---
CREATE TABLE comment_like (
    id INT AUTO_INCREMENT PRIMARY KEY,
    comment_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_comment_like (comment_id, user_id),
    FOREIGN KEY (comment_id) REFERENCES comment(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
);
---
-- 9. 이모지/리액션 (게시글/댓글 확장용)
CREATE TABLE emoji (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE post_reaction (
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    emoji_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, user_id, emoji_id),
    FOREIGN KEY (post_id) REFERENCES post(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (emoji_id) REFERENCES emoji(id) ON DELETE CASCADE
);
---
-- 10. 알림 (모든 활동/채팅 알림 통합)
CREATE TABLE chat_room (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    is_group BOOLEAN,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE chat_message (
    id INT AUTO_INCREMENT PRIMARY KEY,
    chatroom_id INT NOT NULL,
    sender_id INT NOT NULL,
    message TEXT,
    file_url VARCHAR(255),
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (chatroom_id) REFERENCES chat_room(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES user(id) ON DELETE CASCADE
);

CREATE TABLE notification (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,               -- 알림 받는 유저
    type VARCHAR(30),                   -- 알림 종류 (chat_message, comment, like 등)
    message VARCHAR(255),               -- 알림 내용
    is_read BOOLEAN DEFAULT FALSE,
    source_user_id INT NULL,            -- 알림 발생자
    related_post_id INT NULL,           -- 관련 게시글
    related_comment_id INT NULL,        -- 관련 댓글
    chat_message_id INT NULL,           -- 관련 채팅 메시지
    chat_room_id INT NULL,              -- 관련 채팅방
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (source_user_id) REFERENCES user(id) ON DELETE SET NULL,
    FOREIGN KEY (related_post_id) REFERENCES post(id) ON DELETE SET NULL,
    FOREIGN KEY (related_comment_id) REFERENCES comment(id) ON DELETE SET NULL,
    FOREIGN KEY (chat_message_id) REFERENCES chat_message(id) ON DELETE SET NULL,
    FOREIGN KEY (chat_room_id) REFERENCES chat_room(id) ON DELETE SET NULL
);

CREATE TABLE chat_room_user (
    id INT AUTO_INCREMENT PRIMARY KEY,
    chatroom_id INT NOT NULL,
    user_id INT NOT NULL,
    left_at DATETIME DEFAULT NULL,
    FOREIGN KEY (chatroom_id) REFERENCES chat_room(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
);
---
-- 11. 신고/차단
CREATE TABLE report (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reporter_id INT NOT NULL,
    target_type VARCHAR(30),
    target_id INT NOT NULL,
    reason VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reporter_id) REFERENCES user(id) ON DELETE CASCADE
);

CREATE TABLE user_block (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    blocked_user_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_block (user_id, blocked_user_id),
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (blocked_user_id) REFERENCES user(id) ON DELETE CASCADE
);
---
-- 12. 추가 기능: 프로필 방문 기록
CREATE TABLE profile_visit (
    id INT AUTO_INCREMENT PRIMARY KEY,
    visitor_id INT NOT NULL,
    profile_user_id INT NOT NULL,
    visited_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (visitor_id) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (profile_user_id) REFERENCES user(id) ON DELETE CASCADE
);
---
-- 13. 추가 기능: 검색 기록
CREATE TABLE search_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    keyword VARCHAR(100),
    searched_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
);
---
-- 14. 추가 기능: 피드 추천/순위 로그
CREATE TABLE feed_cache (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    score FLOAT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES post(id) ON DELETE CASCADE
);
---
-- 15. 추가 기능: 파일/이미지 신고 관리
CREATE TABLE file_report (
    id INT AUTO_INCREMENT PRIMARY KEY,
    file_id INT NOT NULL,
    reporter_id INT NOT NULL,
    reason VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (file_id) REFERENCES post_file(id) ON DELETE CASCADE,
    FOREIGN KEY (reporter_id) REFERENCES user(id) ON DELETE CASCADE
);

**3. 생성된 테이블에 더미데이터 추가.**









