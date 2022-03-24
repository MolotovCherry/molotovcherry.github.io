function init() {
    collapse_code_blocks();
}

function collapse_code_blocks() {
    // top element
    var code_blocks = [...document.querySelectorAll("pre.highlight")].map(x => x.parentElement.parentElement);
    
    
    
    for (block in code_blocks) {
        var elem = document.createElement("button");
        elem.classList.add("collapsible");
        
        var language;
        var language_upper;
        block.classList.forEach(
            function(cls) {
                if (cls.startsWith("language-")) {
                    language = cls.substring(cls.indexOf('-') + 1);
                    language_upper = language.split("");
                    language_upper[0] = language[0].toUpperCase();
                    language_upper = language_upper.join("");
                }
            }
        );
        
        var icon = document.createElement("i");
        icon.classList.add("devicon-" + language + "-plain");
        elem.appendChild(icon);
        
        var text = document.createTextNode(" " + language_upper);
        elem.appendChild(text);
        
        block.parentNode.insertBefore(elem, block);
    }
    
    /*var i;

    for (i = 0; i < coll.length; i++) {
      coll[i].addEventListener("click", function() {
        this.classList.toggle("active");
        var content = this.nextElementSibling;
        if (content.style.display === "block") {
          content.style.display = "none";
        } else {
          content.style.display = "block";
        }
      });
    }*/
}
