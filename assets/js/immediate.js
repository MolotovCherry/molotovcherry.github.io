---
layout: js_minifier
---

window.cherryblog = window.cherryblog || {};

cherryblog.changeTheme = function(theme) {
  let link = document.getElementById("theme");
  link.href = "/assets/css/" + theme + "-mode.css";
};

cherryblog.changeCommentsTheme = function(theme) {
  let theme = mode == "dark" ? "photon-dark" : "github-light";
  
  let msg = {
    type: "set-theme",
    theme: theme
  };
  
  document.querySelector("iframe").contentWindow.postMessage(msg, "https://utteranc.es");
};

cherryblog.getTheme() {
  let mode = localStorage.getItem("theme");
  // dark is default
  if (mode === null) {
    mode = "dark";
    localStorage.setItem("theme", "dark");
  }
  
  return mode;
}

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
