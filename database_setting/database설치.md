# Donstory DataBase 설정

1. Nodejs 설치
   
   URL : https://nodejs.org/ko

3. mySQL 설치
   
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

**0. 패키지 설치**

| **pip installs**  |  설명 |
|--------------|----------|
|  npm install bcryptjs jsonwebtoken |  회원가입 & 로그인 기능  |
|                                    |          |




**1. TERMINAL에서  입력**

| **pip installs**  |
|--------------|
|  npm init -y  |
|  npm install express mysql2 cors dotenv  |
|  npm install socket.io  |




![image](https://github.com/user-attachments/assets/620a7883-d43a-4eff-ac2e-efc5178bd115)

---
























### DataBase 명령어.


**1. DB생성**
CREATE DATABASE sns_db DEFAULT CHARACTER SET utf8mb4;
USE sns_db;

**2. 테이블 만들기**

   - CREATE TABLE user (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL,
  profile_img VARCHAR(255),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE post (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  category VARCHAR(30),
  title VARCHAR(100),
  content TEXT,
  image_url VARCHAR(255),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user(id)
);

CREATE TABLE comment (
  id INT AUTO_INCREMENT PRIMARY KEY,
  post_id INT NOT NULL,
  user_id INT NOT NULL,
  content TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (post_id) REFERENCES post(id),
  FOREIGN KEY (user_id) REFERENCES user(id)
);

CREATE TABLE notice (
  id INT AUTO_INCREMENT PRIMARY KEY,
  admin_id INT NOT NULL,
  title VARCHAR(100),
  content TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (admin_id) REFERENCES user(id)
);

CREATE TABLE chat_room (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  is_group BOOLEAN,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE chat_room_user (
  id INT AUTO_INCREMENT PRIMARY KEY,
  chatroom_id INT NOT NULL,
  user_id INT NOT NULL,
  FOREIGN KEY (chatroom_id) REFERENCES chat_room(id),
  FOREIGN KEY (user_id) REFERENCES user(id)
);

CREATE TABLE chat_message (
  id INT AUTO_INCREMENT PRIMARY KEY,
  chatroom_id INT NOT NULL,
  sender_id INT NOT NULL,
  message TEXT,
  file_url VARCHAR(255),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (chatroom_id) REFERENCES chat_room(id),
  FOREIGN KEY (sender_id) REFERENCES user(id)
);

**3. 생성된 테이블에 더미데이터 추가.**









