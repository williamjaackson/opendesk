import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "input", "label"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    this.clickOutsideHandler = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    document.addEventListener("click", this.clickOutsideHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutsideHandler)
  }

  toggle() {
    this.openValue = !this.openValue
  }

  close() {
    this.openValue = false
  }

  select(event) {
    const value = event.currentTarget.dataset.value
    const label = event.currentTarget.dataset.label

    this.inputTarget.value = value
    this.labelTarget.textContent = label
    this.close()

    this.menuTarget.querySelectorAll("[data-value]").forEach((option) => {
      const check = option.querySelector("[data-check]")
      if (check) check.classList.toggle("invisible", option.dataset.value !== value)
    })
  }

  openValueChanged() {
    this.menuTarget.classList.toggle("hidden", !this.openValue)
  }
}
