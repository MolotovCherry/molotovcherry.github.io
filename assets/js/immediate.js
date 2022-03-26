---
layout: js_minifier
---

window.cherryblog = window.cherryblog || {};

// defaults to dark if undefined, otherwise gets preferred theme
cherryblog.prefersDark = ((window.matchMedia === undefined) ? true : window.matchMedia('(prefers-color-scheme: dark)').matches);

cherryblog.toggleTheme = function() {
  let theme = cherryblog.getTheme() == "dark" ? "light" : "dark";
  cherryblog.setTheme(theme);
};

cherryblog.getTheme = function() {
  let theme = localStorage.getItem("theme");
  // dark is default
  if (theme === null) {
    if (cherryblog.prefersDark) {
      localStorage.setItem("theme", "dark");
      theme = "dark";
    } else {
      localStorage.setItem("theme", "light");
      theme = "light";
    }
  }
  
  return theme;
};

cherryblog.getCommentsTheme = function(theme) {
  if (theme === undefined) {
    theme = cherryblog.getTheme();
  }
  
  return theme == "dark" ? "photon-dark" : "github-light";
};

cherryblog.setTheme = function(theme) {
  if (theme === undefined) {
    theme = cherryblog.getTheme();
  }

  localStorage.setItem("theme", theme);
  let html = document.documentElement;
  html.dataset.theme = theme;
  
  let msg = {
    type: "set-theme",
    theme: cherryblog.getCommentsTheme(theme)
  };
  
  document.querySelector("iframe").contentWindow.postMessage(msg, "https://utteranc.es");
};

(function () {
  let theme = cherryblog.getTheme();
  let html = document.documentElement;
  html.dataset.theme = theme;
})();
