


npm install nodemailer


### 코드 관련

const nodemailer = require('nodemailer');

// Gmail SMTP로 transporter 생성
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'your_email@gmail.com',        // 보내는 Gmail 주소
        pass: '앱비밀번호'                   // Gmail 앱비밀번호 (계정/비번 아님)
    }
});

// 메일 옵션
const mailOptions = {
    from: 'your_email@gmail.com',              // 보내는 사람
    to: '받는사람@example.com',                 // 받는 사람(쉼표로 여러명 가능)
    subject: 'SNS 이메일 인증 테스트',
    html: '<h1>이메일 인증 안내</h1><p>인증 링크: <a href="#">여기 클릭</a></p>'
};

// 메일 발송
transporter.sendMail(mailOptions, (err, info) => {
    if (err) {
        console.error('메일 발송 에러:', err);
    } else {
        console.log('메일 전송 성공:', info.response);
    }
});
