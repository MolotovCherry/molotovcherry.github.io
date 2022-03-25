---
layout: js_minifier
---

var setTheme = function() {
  // set up click handler for theme switching
  let mode = getCookie("theme");

  let link = document.getElementById("theme");
  link.href = "/assets/css/" + mode + "-mode.css";
}

function collapseCodeBlocks() {
    // top element
    var code_blocks = document.getElementsByTagName("pre");
    
    var len = code_blocks.length;
    for (var x = 0; x < len; x++) {
        // need the top level parent
        var block = code_blocks[x].parentElement.parentElement;
        
        var elem = document.createElement("button");
        elem.classList.add("collapsible");
        
        var classNames = block.className.split(' ');
        
        var language;
        var language_upper;
        classNames.forEach(name => {
            if (name.startsWith("language-")) {
                language = name.substring(name.indexOf('-') + 1);
                language_upper = language.split("");
                language_upper[0] = language[0].toUpperCase();
                language_upper = language_upper.join("");
            }
        });
        
        var icon = document.createElement("i");
        icon.classList.add("devicon-" + language + "-plain");
        icon.classList.add("lang-icon");
        elem.appendChild(icon);
        
        var div = document.createElement("div");
        var text = document.createTextNode(" " + language_upper);
        div.classList.add("lang-label");
        div.appendChild(text);
        elem.appendChild(div);
        
        var container = document.createElement("div");
        container.classList.add("collapse-container");
        
        var parent = block.parentNode;
        var referenceNode = block.nextElementSibling;
        
        container.appendChild(elem);
        container.appendChild(block);
        
        parent.insertBefore(container, referenceNode);
        
        // now add event listener to button
        elem.addEventListener("click", event => {
          event.currentTarget.classList.toggle("active");
          var content = event.currentTarget.nextElementSibling;
          
          if (content.style.maxHeight) {
            content.style.maxHeight = null;
          } else {
            content.style.maxHeight = content.scrollHeight + "px";
          }
        });
    }
}

(function (){
  collapseCodeBlocks();
  
  // set theme
  setTheme();
  
  // set click handler for switcher
  document.getElementById("theme-switcher").addEventListener('click', event => {
    let theme = getCookie("theme");
    if (!!theme) {
      theme = "dark";
    } else {
      if (theme == "dark") {
        theme = "light";
      } else {
        theme = "dark";
      }
    }
    
    setCookie("theme", theme, null);
    setTheme();
  });
})();
