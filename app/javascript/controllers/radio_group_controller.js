import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "option"]

  select(event) {
    const value = event.currentTarget.dataset.value
    this.inputTarget.value = value
    this.render()
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  keydown(event) {
    if (event.key === " " || event.key === "Enter") {
      event.preventDefault()
      this.select(event)
    }
  }

  render() {
    const selected = this.inputTarget.value
    const colour = getComputedStyle(document.documentElement).getPropertyValue("--theme-colour").trim()
    this.optionTargets.forEach(option => {
      const isSelected = option.dataset.value === selected
      const dot = option.querySelector("[data-dot]")
      const ring = option.querySelector("[data-ring]")
      ring.style.borderColor = isSelected ? colour : ""
      ring.classList.toggle("border-gray-300", !isSelected)
      dot.style.backgroundColor = isSelected ? colour : ""
      dot.classList.toggle("invisible", !isSelected)
    })
  }
}
