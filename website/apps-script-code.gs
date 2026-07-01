const SHEET_NAME = '예약요청';
const NOTIFY_EMAIL = 'your-email@example.com'; // 여기에 알림 받을 이메일 주소를 입력하세요

function doPost(e) {
  const data = JSON.parse(e.postData.contents);
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_NAME) || ss.insertSheet(SHEET_NAME);

  if (sheet.getLastRow() === 0) {
    sheet.appendRow(['접수시각', '이름', '연락처', '진료항목', '희망날짜', '희망시간대', '문의내용']);
  }

  sheet.appendRow([
    new Date(),
    data.name,
    data.tel,
    data.item,
    data.date,
    data.time,
    data.memo || ''
  ]);

  MailApp.sendEmail({
    to: NOTIFY_EMAIL,
    subject: '[김태효탑내과] 새 예약 요청 - ' + data.name,
    body:
      '이름: ' + data.name + '\n' +
      '연락처: ' + data.tel + '\n' +
      '진료항목: ' + data.item + '\n' +
      '희망날짜: ' + data.date + '\n' +
      '희망시간대: ' + data.time + '\n' +
      '문의내용: ' + (data.memo || '없음')
  });

  return ContentService
    .createTextOutput(JSON.stringify({ result: 'success' }))
    .setMimeType(ContentService.MimeType.JSON);
}
