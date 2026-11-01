(function () {
  'use strict';

  var REPO = 'abinaze/tstamp';
  var DOWNLOADS = 'https://github.com/' + REPO + '/releases/latest/download/';
  var PANEL_FOR = { windows: 'windows', linux: 'unix', macos: 'unix' };
  var NAME = { windows: 'Windows', linux: 'Linux', macos: 'macOS' };
  var root = document.documentElement;

  function byId(id) { return document.getElementById(id); }

  function detectOS() {
    var nav = window.navigator;
    var plat = (nav.userAgentData && nav.userAgentData.platform) || nav.platform || '';
    var s = (plat + ' ' + (nav.userAgent || '')).toLowerCase();
    if (/android|iphone|ipad|ipod/.test(s)) { return 'mobile'; }
    if (/windows|win32|win64|wow64/.test(s)) { return 'windows'; }
    if (/macintosh|macintel|macppc|mac os|macos/.test(s)) { return 'macos'; }
    if (/linux|x11|cros|ubuntu|debian|fedora/.test(s)) { return 'linux'; }
    return 'unknown';
  }

  /* ---------- theme toggle ---------- */

  var themeBtn = byId('theme-toggle');

  function currentTheme() {
    var t = root.getAttribute('data-theme');
    if (t === 'light' || t === 'dark') { return t; }
    return (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light';
  }

  function showTheme() {
    var next = currentTheme() === 'dark' ? 'light' : 'dark';
    themeBtn.textContent = next === 'dark' ? 'Dark' : 'Light';
    themeBtn.setAttribute('aria-label', 'Switch to ' + next + ' theme');
  }

  themeBtn.addEventListener('click', function () {
    var next = currentTheme() === 'dark' ? 'light' : 'dark';
    root.setAttribute('data-theme', next);
    try { window.localStorage.setItem('tstamp-theme', next); } catch (e) { /* not saved */ }
    showTheme();
  });
  showTheme();

  /* ---------- mobile menu ---------- */

  var menuBtn = byId('menu-toggle');
  var siteNav = byId('site-nav');
  menuBtn.addEventListener('click', function () {
    var open = siteNav.classList.toggle('open');
    menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
  });
  Array.prototype.forEach.call(siteNav.querySelectorAll('a'), function (a) {
    a.addEventListener('click', function () {
      siteNav.classList.remove('open');
      menuBtn.setAttribute('aria-expanded', 'false');
    });
  });

  /* ---------- install tabs ---------- */

  var tabs = Array.prototype.slice.call(document.querySelectorAll('[role="tab"]'));

  function activate(id, focus) {
    tabs.forEach(function (tab, i) {
      var on = tab.getAttribute('data-panel') === id;
      var panel = byId(tab.getAttribute('aria-controls'));
      tab.setAttribute('aria-selected', on ? 'true' : 'false');
      tab.setAttribute('tabindex', (on || (!id && i === 0)) ? '0' : '-1');
      if (panel) { panel.hidden = !on; }
      if (on && focus) { tab.focus(); }
    });
  }

  tabs.forEach(function (tab, i) {
    tab.addEventListener('click', function () { activate(tab.getAttribute('data-panel'), false); });
    tab.addEventListener('keydown', function (e) {
      var j = -1;
      if (e.key === 'ArrowRight') { j = (i + 1) % tabs.length; }
      else if (e.key === 'ArrowLeft') { j = (i - 1 + tabs.length) % tabs.length; }
      else if (e.key === 'Home') { j = 0; }
      else if (e.key === 'End') { j = tabs.length - 1; }
      if (j >= 0) {
        e.preventDefault();
        activate(tabs[j].getAttribute('data-panel'), true);
      }
    });
  });

  /* ---------- detect the system: hero action and first tab ---------- */

  var os = detectOS();
  var detected = byId('detected');
  var cta = byId('primary-cta');
  var heroCmd = byId('hero-cmd');

  if (PANEL_FOR[os]) {
    activate(PANEL_FOR[os], false);
    detected.textContent = 'Showing the steps for ' + NAME[os] + '. On another system? Choose it below.';
    if (os === 'windows') {
      cta.textContent = 'Download for Windows';
      cta.setAttribute('href', DOWNLOADS + 'tstamp-windows-setup.exe');
    } else {
      cta.textContent = 'Install steps for ' + NAME[os];
      heroCmd.hidden = false;
    }
    if (os === 'macos') { byId('macos-note').classList.add('emph'); }
  } else {
    activate(null, false);
    detected.textContent = (os === 'mobile')
      ? 'Open this page on the computer where you use your terminal.'
      : 'Choose your system.';
  }

  /* ---------- copy buttons ---------- */

  function fallbackCopy(text) {
    var ta = document.createElement('textarea');
    var ok = false;
    ta.value = text;
    ta.setAttribute('readonly', '');
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    try { ok = document.execCommand('copy'); } catch (e) { ok = false; }
    document.body.removeChild(ta);
    return ok;
  }

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text).then(
        function () { return true; },
        function () { return fallbackCopy(text); }
      );
    }
    return Promise.resolve(fallbackCopy(text));
  }

  Array.prototype.forEach.call(document.querySelectorAll('[data-copy]'), function (btn) {
    btn.addEventListener('click', function () {
      var src = byId(btn.getAttribute('data-copy'));
      if (!src) { return; }
      copyText(src.textContent.trim()).then(function (ok) {
        btn.textContent = ok ? 'Copied' : 'Copy failed';
        window.setTimeout(function () { btn.textContent = 'Copy'; }, 2000);
      });
    });
  });

  /* ---------- example output ---------- */

  var DEMO = {
    on: '$ tstamp-a\nGlobal tracking enabled.\nTerminals with the TStamp hook loaded start tracking at their next prompt.\nTracking turns off after a reboot.',
    fail: '$ npm run build\n[T1][2026-10-29 19:42:01.100] START: npm run build\nBuild failed.\n[T1][2026-10-29 19:42:04.200] END: npm run build | EXIT=1 | DURATION=3.10s',
    'export': '$ tstamp export\n[T1][2026-10-29 19:42:01.100] START: npm run build\n[T2][2026-10-29 19:42:02.500] START: npm test\n[T2][2026-10-29 19:42:02.900] END: npm test | EXIT=0 | DURATION=0.40s\n[T1][2026-10-29 19:42:04.200] END: npm run build | EXIT=1 | DURATION=3.10s'
  };
  var out = byId('demo-out');
  var chips = Array.prototype.slice.call(document.querySelectorAll('[data-demo]'));

  function showDemo(key) {
    out.textContent = DEMO[key];
    chips.forEach(function (c) { c.setAttribute('aria-pressed', c.getAttribute('data-demo') === key ? 'true' : 'false'); });
  }
  chips.forEach(function (c) { c.addEventListener('click', function () { showDemo(c.getAttribute('data-demo')); }); });
  showDemo('fail');

  /* ---------- latest release lookup (the only network request) ---------- */

  var note = byId('release-note');
  var meta = byId('hero-meta');
  var controller = (typeof AbortController === 'function') ? new AbortController() : null;
  var timer = controller ? window.setTimeout(function () { controller.abort(); }, 6000) : null;

  fetch('https://api.github.com/repos/' + REPO + '/releases/latest', {
    headers: { 'Accept': 'application/vnd.github+json' },
    signal: controller ? controller.signal : undefined
  }).then(function (r) {
    if (timer) { window.clearTimeout(timer); }
    if (!r.ok) {
      var err = new Error('status');
      err.status = r.status;
      throw err;
    }
    return r.json();
  }).then(function (j) {
    if (j && typeof j.tag_name === 'string' && /^[0-9A-Za-z.+_-]{1,40}$/.test(j.tag_name)) {
      meta.textContent = 'Latest release ' + j.tag_name + ' \u00b7 MIT license';
    }
  }).catch(function (err) {
    note.hidden = false;
    note.textContent = (err && err.status === 404)
      ? 'No public release is available yet. The download links start working when the first release is published.'
      : 'Could not check for the latest release. The links on this page always point to the newest published release.';
  });
}());
