(function () {
  'use strict';

  // Mobile menu toggle
  function initMobileMenu() {
    var menuToggle = document.getElementById('menu-toggle');
    var mobileMenu = document.getElementById('mobile-menu');
    var overlay = document.getElementById('mobile-menu-overlay');

    if (!menuToggle || !mobileMenu || !overlay) return;

    function closeMenu() {
      menuToggle.classList.remove('active');
      menuToggle.setAttribute('aria-expanded', 'false');
      mobileMenu.classList.remove('active');
      overlay.classList.remove('active');
      document.body.classList.remove('menu-open');
    }

    function toggleMenu() {
      if (mobileMenu.classList.contains('active')) {
        closeMenu();
      } else {
        menuToggle.classList.add('active');
        menuToggle.setAttribute('aria-expanded', 'true');
        mobileMenu.classList.add('active');
        overlay.classList.add('active');
        document.body.classList.add('menu-open');
      }
    }

    menuToggle.addEventListener('click', toggleMenu);
    overlay.addEventListener('click', closeMenu);

    mobileMenu.addEventListener('click', function (e) {
      if (e.target.tagName === 'A') {
        closeMenu();
      }
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && mobileMenu.classList.contains('active')) {
        closeMenu();
      }
    });
  }

  // Scroll spy — highlight current section in sidebar TOC
  function initScrollSpy() {
    var tocLinks = document.querySelectorAll('#toc a[href^="#"]');
    var mobileLinks = document.querySelectorAll('.mobile-toc a[href^="#"]');
    var sections = document.querySelectorAll('#content section[id]');

    if (sections.length === 0) return;

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            tocLinks.forEach(function (link) { link.classList.remove('active'); });
            mobileLinks.forEach(function (link) { link.classList.remove('active'); });

            var selector = 'a[href="#' + entry.target.id + '"]';
            var activeDesktop = document.querySelector('#toc ' + selector);
            var activeMobile = document.querySelector('.mobile-toc ' + selector);

            if (activeDesktop) activeDesktop.classList.add('active');
            if (activeMobile) activeMobile.classList.add('active');
          }
        });
      },
      {
        rootMargin: '-10% 0px -85% 0px',
        threshold: 0
      }
    );

    sections.forEach(function (section) { observer.observe(section); });
  }

  // Syntax highlighting
  function initHighlighting() {
    if (window.Prism) {
      Prism.highlightAll();
    }
  }

  // Handle hash navigation on load
  function handleHash() {
    if (window.location.hash) {
      var target = document.querySelector(window.location.hash);
      if (target) {
        setTimeout(function () { target.scrollIntoView(); }, 150);
      }
    }
  }

  // Initialize
  function init() {
    initMobileMenu();
    initScrollSpy();
    initHighlighting();
    handleHash();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
