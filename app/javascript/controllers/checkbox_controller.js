import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "box"]

  toggle() {
    this.inputTarget.value = this.inputTarget.value === "1" ? "0" : "1"
    this.render()
  }

  keydown(event) {
    if (event.key === " " || event.key === "Enter") {
      event.preventDefault()
      this.toggle()
    }
  }

  render() {
    const checked = this.inputTarget.value === "1"
    const colour = getComputedStyle(document.documentElement).getPropertyValue("--theme-colour").trim()
    this.boxTarget.style.backgroundColor = checked ? colour : ""
    this.boxTarget.style.borderColor = checked ? colour : ""
    this.boxTarget.classList.toggle("bg-white", !checked)
    this.boxTarget.classList.toggle("border-gray-300", !checked)
    this.boxTarget.querySelector("[data-checkmark]").classList.toggle("invisible", !checked)
  }
}
