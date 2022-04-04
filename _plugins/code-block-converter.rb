require 'nokogiri'

module Jekyll
  class CodeBlockConverter < Converter
    safe true
    priority :low

    def matches(ext)
      ext == ".md"
    end

    def output_ext(ext)
      ".html"
    end

    def convert(content)
      data = Nokogiri::HTML.parse(content)
      blocks = data.css("div.highlighter-rouge")
      
      for block in blocks
        language = block['class'].split(' ')[0]
        language.slice!('language-')
        
        i = "<i class=\"lang-icon devicon-#{language}-plain\"></i>"
        label = "<div class=\"lang-label\"> #{language.capitalize()}</div>"
        
        button = "<button class=\"collapsible\" onclick=\"toggleBlock(this)\">#{i}#{label}</button>"
        
        block.wrap("<div class=\"collapse-container\">#{button}</div>")
      end
      
      body = data.at("body")

      script = Nokogiri::HTML.fragment %q(
<script>
function toggleBlock(event) {
  event.classList.toggle("active");
  let content = event.nextElementSibling;

  if (content.style.maxHeight) {
    content.style.maxHeight = null;
  } else {
    content.style.maxHeight = content.scrollHeight + "px";
  }
}
</script>
)

      if blocks.size > 0
        body.add_child script
      end
      
      data.to_s
    end
  end
end