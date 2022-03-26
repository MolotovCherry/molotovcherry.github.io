---
layout: js_minifier
---

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
  
  // dynamically add the themed comments
  // this detects if it's a post, BUT this MAY be used on other template pages, soo..
  let post = document.getElementsByClassName("post");
  // we need to check the path is at least 4, e.g. /2022/3/04/title.
  // this prevents it from loading on e.g. archive.html
  let is_post = window.location.pathname.split('/').slice(1).length == 4 && post.length != 0;
  if (is_post) {
    let script = document.createElement('script');
    script.src = "https://utteranc.es/client.js";
    script.setAttribute("repo", "cherryleafroad/cherryleafroad.github.io");
    script.setAttribute("issue-term", "pathname");
    script.setAttribute("label", "comments");
    script.setAttribute("theme", cherryblog.getCommentTheme());
    script.setAttribute("crossorigin", "anonymous");
    script.async = true;
    
    post[0].appendChild(script);
  }

  // set state of day/night icon
  // checked == day
  let dayNight = document.getElementById("theme-switcher");
  let theme = cherryblog.getTheme();
  
  dayNight.checked = theme == "light" ? true : false;

  // set click handler for switcher
  dayNight.addEventListener('click', event => {    
    cherryblog.toggleTheme();
    cherryblog.toggleCommentsTheme();
  });
})();
