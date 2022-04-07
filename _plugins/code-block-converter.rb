require 'nokogiri'

require "octokit"
require 'rouge'

$icon_languages = %w[
  aarch64 adonisjs aftereffects amazonwebservices anaconda android androidstudio angularjs ansible
  apache apachekafka appcelerator apple appwrite arduino argocd atom azure babel backbonejs bamboo bash behance bitbucket
  blender bootstrap bower bulma c cakephp canva centos ceylon chrome circleci clojure clojurescript cmake codecov
  codeigniter codepen coffeescript composer confluence couchdb cplusplus crystal csharp css css3 cucumber d3js dart
  debian denojs devicon digitalocean discordjs django docker doctrine dot-net dotnetcore dropwizard drupal electron
  eleventy elixir elm embeddedc ember erlang eslint express facebook fastapi feathersjs fedora figma filezilla firebase
  firefox flask flutter foundation fsharp gatling gatsby gcc gentoo gimp git github gitlab gitter go godot google
  googlecloud gradle grafana grails graphql groovy grunt gulp handlebars haskell haxe heroku html html5 hugo ie10 ifttt
  illustrator inkscape intellij ionic jamstack jasmine java javascript jeet jenkins jest jetbrains jira jquery julia
  jupyter k3s kaggle karma knockout kotlin krakenjs kubernetes labview laravel latex less linkedin linux lua magento
  markdown materialui matlab maya meteor microsoftsqlserver minitab mocha modx mongodb moodle msdos mysql neo4j nestjs
  networkx nextjs nginx nixos nodejs nodewebkit npm nuget numpy nuxtjs objectivec ocaml openal opencv opengl opensuse
  opera oracle packer pandas perl phalcon phoenix photoshop php phpstorm podman polygon postgresql premierepro processing
  prometheus protractor putty pycharm pytest python pytorch qt r rails raspberrypi react rect redhat redis redux rocksdb
  rspec rstudio ruby rubymine rust safari salesforce sass scala sdl selenium sequelize shopware shotgrid sketch slack
  socketio solidity sourcetree spring spss sqlalchemy sqlite ssh storybook stylus subversion svelte swift symfony
  tailwindcss tensorflow terraform thealgorithms threejs tomcat tortoisegit towergit travis trello twitter typescript
  typo3 ubuntu unity unix unrealengine uwsgi vagrant vim visualstudio vscode vuejs vuestorefront vuetify webflow weblate
  webpack webstorm windows8 woocommerce wordpress xamarin xcode xd yarn yii yunohost zend zig
]

# counts how many gist tags are in one file, so we can output the js only one time in a post
# 1 == last iter through post (at the bottom)
# max == first iter through
$counter = 0
$max = 0

# used to append a toggle script for the blocks
$add_toggle = false
$toggle_block = %q(
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

$load_gist = %Q(
<script src="/assets/js/highlight.min.js"></script>
<script>
icon_languages = #{$icon_languages};

function getGist(gistid, filenames, callback) {
  var xmlhttp = new XMLHttpRequest();

  xmlhttp.onreadystatechange = () => {
    if (xmlhttp.readyState == XMLHttpRequest.DONE) {
      if (xmlhttp.status == 200) {
        let gistdata = JSON.parse(xmlhttp.responseText);

        var objects = [];
        if (!filenames) {
          for (file in gistdata.files) {
            var o = gistdata.files[file];
            objects.push(o);
          }
        } else {
          for (file in filenames) {
            file = filenames[file];
            if (gistdata.files.hasOwnProperty(file)) {
              var o = gistdata.files[file];
              objects.push(o);
            } else {
              console.error('Gist ' + file + ' not found');
            }
          }
        }

        if (objects.length > 0) {
          objects.reverse().forEach((obj) => {
            callback(gistdata, obj);
          });
        }
      }
      else {
        console.error('GitHub gist API returned ' + xmlhttp.status);
      }
    }
  };

  xmlhttp.open('GET', 'https://api.github.com/gists/' + gistid, true);
  xmlhttp.send();
}

let template = document.createElement('template');
template.innerHTML = `
<div class="collapse-container">
  <button class="collapsible" onclick="toggleBlock(this)">
    <i class="lang-icon"></i>
    <div class="lang-label label-gist"></div>
  </button>

  <div class="highlighter-rouge">
    <div class="highlight">
      <pre class="highlight"><code></code></pre>
    </div>
  </div>
</div>
`;

function createGist(gistid, filenames, context) {
  getGist(gistid, filenames, (gistdata, gist) => {
    let lang_down = gist.language.toLowerCase();

    let element = template.content.cloneNode(true).firstChild;

    let icon = element.getElementsByTagName('i')[0];
    if (icon_languages.includes(lang_down)) {
      icon.classList.add('devicon-' + lang_down + '-plain');
    } else {
      icon.classList.add('devicon-devicon-plain');
    }

    let div_highlighter = element.getElementsByClassName('highlighter-rouge')[0];
    div_highlighter.classList.add('language-' + lang_down);

    let code = element.getElementsByTagName('code')[0];
    code.classList.add('language-' + lang_down);

    let code_text = document.createTextNode(gist.content);
    code.appendChild(code_text);

    hljs.highlightElement(code);

    let label = element.getElementsByClassName('lang-label')[0];
    label.innerHTML = ' ' + gist.language + ' Gist | <a href="' + gistdata.html_url + '" target="_blank">' + gist.filename +'</a> hosted with <span style="color: red;">❤</span> by <a href="https://github.com" target="_blank">GitHub</a> | <a href="'+ gist.raw_url +'" target="_blank">View raw</a>';

    context.parentNode.insertBefore(element, context.nextSibling);
  });
}
</script>
)


module Jekyll
  class CodeBlockConverter < Converter
    safe true
    priority :low

    def matches(ext)
      ext == '.md'
    end

    def output_ext(ext)
      '.html'
    end

    def convert(content)
      data = Nokogiri::HTML.parse(content)
      # do not redo block collapsing on noscript elements from gist tag
      blocks = data.css(':not(.noscript) > div.highlighter-rouge')

      for block in blocks
        # add the toggle block script
        $add_toggle = true

        language = block['class'].split(' ')[0]
        language.slice!('language-')

        i_lang = $icon_languages.include?(language) ? language : 'devicon'
        label = "<div class=\"lang-label\"> #{language.capitalize}</div>"
        i = "<i class=\"lang-icon devicon-#{i_lang}-plain\"></i>"

        button = "<button class=\"collapsible\" onclick=\"toggleBlock(this)\">#{i}#{label}</button>"

        block.wrap("<div class=\"collapse-container\">#{button}</div>")
      end

      data.to_s
    end
  end
end

#
# Gist tag for Jekyll with collapsing of course
#

module Jekyll
  class GistTag < Liquid::Tag

    def self.client
      @client ||= Octokit::Client.new :access_token => ENV["GITHUB_TOKEN"]
    end

    def determine_arguments(input)
      args = input.split(' ')

      if args.size == 0
        raise ArgumentError, <<~ERROR
          Syntax error in tag 'gist' while parsing the following markup:

           '{% gist %}'

          Valid syntax:
            {% gist user/1234567 %}
            {% gist user/1234567 foo.js %}
            {% gist 28949e1d5ee2273f9fd3 %}
            {% gist 28949e1d5ee2273f9fd3 best.md %}

          Multiple space separated filenames are allowed

        ERROR
      end

      [args.map { |e| "'#{e.strip}'" }, args.map { |e| e.strip }]
    end

    def initialize(tag_name, text, tokens)
      super

      $counter += 1
      # this will get stuck at the max
      $max = $counter
    end

    def render(context)
      @arguments = determine_arguments(@markup.strip)
      @encoding = context.registers[:site].config["encoding"] || "utf-8"
      @settings = context.registers[:site].config["gist"]

      content = ""
      # inject helper js for gists
      # runs only once on first iter through file
      if $counter == $max
        $add_toggle = true
        content += $load_gist
      end

      filenames = @arguments[0].size >= 2 ? "[#{@arguments[0][1..-1].join(',')}]" : 'null'
      content += "<script>createGist(#{@arguments[0][0]}, #{filenames}, document.currentScript);</script>"
      content += noscript_tag(@arguments[1][0], @arguments[1][1..-1])

      $counter -= 1

      content
    end

    def noscript_tag(gist_id, filenames)
      return if @settings && @settings['noscript'] == false

      unless ENV['GITHUB_TOKEN']
        raise 'Please define GITHUB_TOKEN'
      end

      gist = GistTag.client.gist gist_id
      files = if filenames.empty?
         gist.files
      else
        gist.files.select { |name, _data| filenames.include?(name.to_s) }
      end

      content = ''
      files.each do |name, data|
        name = name.to_s
        lang_down = data.language.downcase
        i_lang = $icon_languages.include?(lang_down) ? lang_down : 'devicon'

        code = data.content
        code = code.force_encoding(@encoding)

        formatter = Rouge::Formatters::HTML.new
        lexer = Rouge::Lexer.find(lang_down)
        code = formatter.format(lexer.lex(code))

        content += %(
<noscript>
  <div class="collapse-container noscript">
    <button class="collapsible">
      <i class="lang-icon devicon-#{i_lang}-plain"></i>
      <div class="lang-label label-gist"> #{data.language} Gist | <a href="#{gist.html_url}" target="_blank">#{data.filename}</a> hosted with <span style="color: red;">❤</span> by <a href="https://github.com" target="_blank">GitHub</a> | <a href="#{data.raw_url}" target="_blank">View raw</a></div>
    </button>

    <div class="language-#{lang_down} highlighter-rouge">
      <div class="highlight">
        <pre class="highlight"><code>#{code}</code></pre>
      </div>
    </div>
  </div>
</noscript>
)
      end

      content
    end
  end
end


Jekyll::Hooks.register :posts, :post_convert do |post|
  if $add_toggle
    data = Nokogiri::HTML.parse(post.content)

    body = data.at('body')

    script = Nokogiri::HTML.fragment $toggle_block

    body.add_child script

    post.content = data.to_s

    # reset it for the next new file
    $add_toggle = false
  end
end

Liquid::Template.register_tag('gist', Jekyll::GistTag)
