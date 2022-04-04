---
layout: js_minifier
---

var parseNum = str => +str.replace(/[^.\d]/g, '');

var time, html, section, header;
cherryblog.postSetup = function () {
  html = document.documentElement;
  section = document.getElementsByTagName('section')[0];
  header = document.getElementsByTagName('header')[0];

  // remove transition disabler
  delete html.dataset.preload;

  let style = getComputedStyle(document.documentElement);
  time = parseNum(style.getPropertyValue('--transition-time'));
};

(function () {
  // set state of day/night icon
  // checked == day
  let dayNight = document.getElementById("theme-switcher");
  let theme = cherryblog.getTheme();
  dayNight.checked = theme == "light" ? true : false;

  // set click handler for switcher
  dayNight.addEventListener('click', event => {
    // set one-shot transition
    html.dataset.transition = '';
    header.dataset.transition = '';
    section.dataset.transition = '';

    cherryblog.toggleTheme();

    setTimeout(
      () => {
        // remove unneeded property
        delete html.dataset.transition;
        delete header.dataset.transition;
        delete section.dataset.transition;
      },
      time * 1000
    );
  });

  // dynamically add the themed comments h-entry is used only on posts
  let post = document.getElementsByClassName("h-entry");
  let is_post = post.length == 1;
  if (is_post) {
    let script = document.createElement('script');
    script.src = "https://utteranc.es/client.js";
    script.setAttribute("repo", "cherryleafroad/cherryleafroad.github.io");
    script.setAttribute("issue-term", "pathname");
    script.setAttribute("label", "comments");
    script.setAttribute("theme", cherryblog.getCommentsTheme(theme));
    script.setAttribute("crossorigin", "anonymous");
    script.async = true;

    post[0].appendChild(script);
  }
})();
