(function () {
  'use strict';
  try {
    var t = window.localStorage.getItem('tstamp-theme');
    if (t === 'light' || t === 'dark') { document.documentElement.setAttribute('data-theme', t); }
  } catch (e) { /* storage unavailable: follow the system setting */ }
}());
