// ※ 참고: 현재 홈페이지 예약 폼은 구글 폼(Google Forms)으로 직접 전송되도록 연결되어 있어
//    이 스크립트 없이도 동작합니다. 구글 폼 대신 Apps Script 방식으로 바꾸고 싶을 때만 사용하세요.
//    (설치 순서는 예약시스템_연동가이드.md 참고)

const SHEET_NAME = '예약요청';
const NOTIFY_EMAIL = 'your-email@example.com'; // 여기에 알림 받을 이메일 주소를 입력하세요
const MAX_LEN = 500; // 항목별 최대 글자 수 (스팸·오입력 방어)

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return jsonResult('error', '요청 본문이 비어 있습니다');
    }
    const data = JSON.parse(e.postData.contents);

    // 필수 항목 확인 + 길이 제한
    const clean = {};
    ['name', 'tel', 'item', 'date', 'time', 'memo'].forEach(function(key) {
      clean[key] = String(data[key] || '').trim().slice(0, MAX_LEN);
    });
    if (!clean.name || !clean.tel || !clean.item || !clean.date || !clean.time) {
      return jsonResult('error', '필수 항목이 누락되었습니다');
    }

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(SHEET_NAME) || ss.insertSheet(SHEET_NAME);

    if (sheet.getLastRow() === 0) {
      sheet.appendRow(['접수시각', '이름', '연락처', '진료항목', '희망날짜', '희망시간대', '문의내용']);
    }

    sheet.appendRow([new Date(), clean.name, clean.tel, clean.item, clean.date, clean.time, clean.memo]);

    // 메일 발송이 실패해도 시트 기록은 유지되도록 별도로 감싼다
    try {
      MailApp.sendEmail({
        to: NOTIFY_EMAIL,
        subject: '[김태효탑내과] 새 예약 요청 - ' + clean.name,
        body:
          '이름: ' + clean.name + '\n' +
          '연락처: ' + clean.tel + '\n' +
          '진료항목: ' + clean.item + '\n' +
          '희망날짜: ' + clean.date + '\n' +
          '희망시간대: ' + clean.time + '\n' +
          '문의내용: ' + (clean.memo || '없음')
      });
    } catch (mailErr) {
      console.error('메일 발송 실패: ' + mailErr);
    }

    return jsonResult('success');
  } catch (err) {
    console.error('예약 접수 실패: ' + err);
    return jsonResult('error', '요청을 처리하지 못했습니다');
  }
}

function jsonResult(result, message) {
  return ContentService
    .createTextOutput(JSON.stringify({ result: result, message: message || '' }))
    .setMimeType(ContentService.MimeType.JSON);
}
