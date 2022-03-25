---
layout: js_minifier
---

window.cherryblog = window.cherryblog || {};

cherryblog.setCookie = function(cname, cvalue, exdays) {
  if (exdays !== null) {
    const d = new Date();
    d.setTime(d.getTime() + (exdays*24*60*60*1000));
    let expires = "expires="+ d.toUTCString();
    document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";
  } else {
    document.cookie = cname + "=" + cvalue + ";path=/";
  }
};

cherryblog.getCookie = function(cname) {
  let name = cname + "=";
  let decodedCookie = decodeURIComponent(document.cookie);
  let ca = decodedCookie.split(';');
  for(let i = 0; i <ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) == ' ') {
      c = c.substring(1);
    }
    if (c.indexOf(name) == 0) {
      return c.substring(name.length, c.length);
    }
  }
  return "";
};

(function (){
  let mode = cherryblog.getCookie("theme");
  
  let tag = document.currentScript;
  let link = document.createElement('link');
  link.rel = 'stylesheet';
  // easy selecting later
  link.id = "theme";
  
  // no cookie, use dark mode by default
  if (mode === "") {
    // set users preferred style
    link.href = "/assets/css/dark-mode.css";
    cherryblog.setCookie("theme", "dark", null);
  } else {
    // set users preferred style
    link.href = "/assets/css/" + mode + "-mode.css";
  }
  
  tag.appendChild(link);
})();