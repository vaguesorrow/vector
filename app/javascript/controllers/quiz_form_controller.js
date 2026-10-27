import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["questions", "template"]

  add() {
    const positions = [...this.questionsTarget.querySelectorAll("[data-question-position]")].map(input => Number(input.value))
    const position = Math.max(-1, ...positions) + 1
    const key = `new_${Date.now()}_${position}`
    const fragment = this.templateTarget.content.cloneNode(true)
    fragment.querySelectorAll("[name], [id], [for]").forEach(element => {
      for (const attribute of ["name", "id", "for"]) {
        if (element.hasAttribute(attribute)) element.setAttribute(attribute, element.getAttribute(attribute).replaceAll("NEW_QUESTION", key))
      }
    })
    fragment.querySelector("[data-question-position]").value = position
    this.questionsTarget.appendChild(fragment)
  }

  remove(event) {
    const question = event.target.closest("[data-question]")
    question.querySelector("[data-question-destroy]").value = "1"
    question.hidden = true
    question.querySelectorAll("[required]").forEach(input => input.required = false)
  }

  choose(event) {
    if (!event.target.checked) return
    event.target.closest("[data-question]").querySelectorAll('input[type="checkbox"]').forEach(input => {
      if (input !== event.target) input.checked = false
    })
  }
}
