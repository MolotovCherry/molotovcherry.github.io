function init() {
    collapse_code_blocks();
}

function collapse_code_blocks() {
    // top element
    var code_blocks = [...document.querySelectorAll("pre.highlight")].map(x => x.parentElement.parentElement);
    
    var buttons = [];
    for (block of code_blocks) {
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
        
        block.parentNode.insertBefore(elem, block);
        buttons.push(elem);
    }

    for (button of buttons) {
      button.addEventListener("click", event => {
        event.currentTarget.classList.toggle("active");
        var content = event.currentTarget.nextElementSibling;
        
        if (content.style.maxHeight) {
          content.style.maxHeight = null;
          
          // wait until animation is finished before going none
          setTimeout(() => {
            content.style.display = "none";
          }, 200);
        } else {
          content.style.display = "block";
          content.style.maxHeight = content.scrollHeight + "px";
        }
      });
    }
}
