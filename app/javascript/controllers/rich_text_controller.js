import { Controller } from "@hotwired/stimulus"
import Quill, { marked } from "article_editor"

export default class extends Controller {
  static targets = ["input", "format", "controls", "toolbar", "editor"]

  connect() {
    this.originalFormat = this.formatTarget.value
    this.originalBody = this.inputTarget.value
    this.quill = new Quill(this.editorTarget, {
      modules: {
        toolbar: {
          container: this.toolbarTarget,
          handlers: {
            link(value) {
              if (!value) return this.quill.format("link", false)
              const url = window.prompt("Адрес ссылки (https://…)")
              if (url && /^(https?:\/\/|mailto:)/i.test(url.trim())) {
                this.quill.format("link", url.trim())
              }
            }
          }
        },
        history: { userOnly: true }
      },
      formats: ["header", "font", "size", "bold", "italic", "underline", "strike", "list", "align", "blockquote", "link", "indent", "script"],
      placeholder: "Начни писать статью…"
    })

    const html = this.originalFormat === "html" ? this.originalBody : marked.parse(this.originalBody, { async: false })
    this.quill.setContents(this.quill.clipboard.convert({ html }), "silent")
    this.quill.history.clear()
    this.restoreToolbarLabels()
    this.quill.on("selection-change", (range) => {
      if (!range) this.restoreToolbarLabels()
    })
    this.quill.root.setAttribute("role", "textbox")
    this.quill.root.setAttribute("aria-multiline", "true")
    this.quill.root.setAttribute("aria-labelledby", `${this.inputTarget.id}_label`)
    this.quill.root.id = `${this.inputTarget.id}_editor`
    this.label = document.getElementById(`${this.inputTarget.id}_label`)
    this.label?.setAttribute("for", this.quill.root.id)
    this.controlsTarget.hidden = false
    this.inputTarget.hidden = true
    this.changed = false
    this.quill.on("text-change", () => {
      this.changed = true
      this.sync()
    })
    this.beforeCache = () => this.teardown()
    document.addEventListener("turbo:before-cache", this.beforeCache)
  }

  sync() {
    if (!this.changed) return
    this.inputTarget.value = this.quill.getText().trim() ? this.quill.getSemanticHTML() : ""
    this.formatTarget.value = "html"
  }

  undo() { this.quill.history.undo() }
  redo() { this.quill.history.redo() }

  restoreToolbarLabels() {
    this.toolbarTarget.querySelectorAll("select").forEach((select) => {
      if (select.selectedIndex < 0) {
        const option = select.querySelector("option[selected]")
        if (option) option.selected = true
      }
    })
  }

  teardown() {
    if (!this.quill) return
    this.sync()
    this.controlsTarget.hidden = true
    this.inputTarget.hidden = false
    this.label?.setAttribute("for", this.inputTarget.id)
    // Clone the toolbar to remove Quill's listeners before Turbo caches the page.
    this.toolbarTarget.replaceWith(this.toolbarTarget.cloneNode(true))
    this.editorTarget.replaceChildren()
    this.quill = null
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.beforeCache)
    this.teardown()
  }
}
