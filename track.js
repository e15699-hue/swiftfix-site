/* 迅修電腦：自家點擊紀錄（2026-11-19 上線）
   每次開頁記一次 view、每次點連結記一次 click，寫入 Supabase site_clicks 表。
   只記站別、頁面、連結、來源頁，不記 IP、不寫 cookie、不含個資。
   anon key 是公開安全金鑰，表格 RLS 只開放匿名寫入、不可讀取。 */
(function () {
  var SUPABASE_URL = 'https://wkoswirgtcvdrvqlshki.supabase.co';
  var ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indrb3N3aXJndGN2ZHJ2cWxzaGtpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0MjEyNDUsImV4cCI6MjEwNzk5NzI0NX0.0X0Nfpka1fkNn1wwG2p5UHqUgkPFffsAsb2ih9DRxWU';
  var SITE = 'swiftfix';
  function send(event, target) {
    try {
      var body = JSON.stringify({
        site: SITE,
        page: location.pathname || '/',
        event: event,
        target: target || null,
        referrer: document.referrer || null
      });
      fetch(SUPABASE_URL + '/rest/v1/site_clicks', {
        method: 'POST',
        headers: {
          'apikey': ANON_KEY,
          'Authorization': 'Bearer ' + ANON_KEY,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: body,
        keepalive: true
      }).catch(function () {});
    } catch (e) {}
  }
  send('view');
  document.addEventListener('click', function (e) {
    var a = e.target && e.target.closest ? e.target.closest('a') : null;
    if (a && a.getAttribute('href')) {
      send('click', a.getAttribute('href').slice(0, 200));
    }
  });
})();
