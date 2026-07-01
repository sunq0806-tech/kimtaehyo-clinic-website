(function(){
  var btn = document.createElement('button');
  btn.className = 'top-btn';
  btn.type = 'button';
  btn.setAttribute('aria-label', '맨 위로 이동');
  btn.textContent = 'TOP';
  document.body.appendChild(btn);

  function onScroll(){
    if (window.scrollY > 480) btn.classList.add('show');
    else btn.classList.remove('show');
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  btn.addEventListener('click', function(){
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
})();

(function(){
  var headerRow = document.querySelector('.header-row');
  var gnb = document.querySelector('.gnb');
  var headerCta = document.querySelector('.header-cta');
  if (!headerRow || !gnb || !headerCta) return;

  var toggle = document.createElement('button');
  toggle.className = 'nav-toggle';
  toggle.type = 'button';
  toggle.setAttribute('aria-label', '메뉴 열기');
  toggle.setAttribute('aria-expanded', 'false');
  toggle.textContent = '☰';
  headerRow.insertBefore(toggle, headerCta);

  function closeMenu(){
    gnb.classList.remove('open');
    toggle.setAttribute('aria-expanded', 'false');
    toggle.textContent = '☰';
  }

  toggle.addEventListener('click', function(){
    var willOpen = !gnb.classList.contains('open');
    gnb.classList.toggle('open', willOpen);
    toggle.setAttribute('aria-expanded', willOpen ? 'true' : 'false');
    toggle.textContent = willOpen ? '✕' : '☰';
  });

  gnb.querySelectorAll('a').forEach(function(a){
    a.addEventListener('click', closeMenu);
  });

  document.addEventListener('click', function(e){
    if (!gnb.classList.contains('open')) return;
    if (gnb.contains(e.target) || toggle.contains(e.target)) return;
    closeMenu();
  });
})();

(function(){
  var bar = document.createElement('div');
  bar.className = 'mobile-cta-bar';
  bar.innerHTML =
    '<a class="tel" href="tel:055-812-8275">📞 전화 문의</a>' +
    '<a class="reserve" href="index.html#reserve">예약 요청</a>';
  document.body.appendChild(bar);
})();
