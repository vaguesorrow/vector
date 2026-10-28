import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["question", "result"]

  check() {
    const unanswered = this.questionTargets.find(question => !question.querySelector("input:checked"))
    if (unanswered) {
      this.resultTarget.textContent = "Ответь на все вопросы, чтобы увидеть результат."
      unanswered.querySelector("input")?.focus()
      return
    }
    let correct = 0
    this.questionTargets.forEach(question => {
      const selected = question.querySelector("input:checked")
      const isCorrect = selected.dataset.correct === "true"
      if (isCorrect) correct++
      question.querySelector(".admin-preview__feedback").hidden = false
      const answer = question.querySelector('input[data-correct="true"]')?.closest("label").querySelector("span").textContent
      question.querySelector("[data-answer-result]").textContent = isCorrect ? "Верно!" : `Неверно. Правильный ответ: ${answer || "не задан"}.`
      question.querySelectorAll("input").forEach(input => {
        input.closest("label").classList.toggle("admin-preview__answer--correct", input.dataset.correct === "true")
      })
    })
    this.resultTarget.textContent = `Правильных ответов: ${correct} из ${this.questionTargets.length}. Результат предпросмотра не сохраняется.`
  }

  reset() {
    this.resultTarget.textContent = ""
    this.questionTargets.forEach(question => {
      question.querySelector(".admin-preview__feedback").hidden = true
      question.querySelectorAll(".admin-preview__answer--correct").forEach(label => label.classList.remove("admin-preview__answer--correct"))
    })
  }
}
