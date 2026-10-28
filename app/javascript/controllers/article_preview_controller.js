import { Controller } from "@hotwired/stimulus"
import Quill, { marked } from "article_editor"

export default class extends Controller {
  static targets = ["source", "content"]
  static values = { format: String }

  connect() {
    this.contentTarget.replaceChildren()
    this.quill = new Quill(this.contentTarget, {
      readOnly: true,
      modules: { toolbar: false },
      formats: ["header", "font", "size", "bold", "italic", "underline", "strike", "list", "align", "blockquote", "link", "indent", "script"]
    })
    const html = this.formatValue === "html" ? this.sourceTarget.value : marked.parse(this.sourceTarget.value, { async: false })
    this.quill.setContents(this.quill.clipboard.convert({ html }), "silent")
    this.quill.root.removeAttribute("contenteditable")
    this.quill.root.setAttribute("aria-label", "Текст статьи")
  }
}
