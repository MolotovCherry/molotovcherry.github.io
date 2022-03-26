---
layout: js_minifier
---

window.cherryblog = window.cherryblog || {};

// defaults to dark if undefined, otherwise gets preferred theme
cherryblog.prefersDark = ((window.matchMedia === undefined) ? true : window.matchMedia('(prefers-color-scheme: dark)').matches);

cherryblog.changeTheme = function(theme) {
  let link = document.getElementById("theme");
  link.href = "/assets/css/" + theme + "-mode.css";
};

cherryblog.changeCommentsTheme = function(theme) {
  let commentTheme = theme == "dark" ? "photon-dark" : "github-light";
  
  let msg = {
    type: "set-theme",
    theme: commentTheme
  };
  
  document.querySelector("iframe").contentWindow.postMessage(msg, "https://utteranc.es");
};

cherryblog.getTheme = function() {
  let mode = localStorage.getItem("theme");
  // dark is default
  if (mode === null) {
    if (cherryblog.prefersDark) {
      localStorage.setItem("theme", "dark");
    } else {
      localStorage.setItem("theme", "light");
    }
  }
  
  return mode;
};

(function (){
  let mode = cherryblog.getTheme();
  
  let tag = document.currentScript;
  let link = document.createElement('link');
  link.rel = 'stylesheet';
  // easy selecting later
  link.id = "theme";

  // set users preferred style
  link.href = "/assets/css/" + mode + "-mode.css";
  
  tag.appendChild(link);
})();
