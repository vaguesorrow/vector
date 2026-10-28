# Pin npm packages by running ./bin/importmap

pin "application"
pin "quill", to: "quill.js"
pin "marked", to: "marked.js"
pin "article_editor"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
