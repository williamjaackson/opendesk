import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "input", "label", "search"]
  static values = {
    open: { type: Boolean, default: false },
    autosubmit: { type: Boolean, default: false }
  }

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
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = label
      this.labelTarget.classList.remove("text-gray-400")
      this.labelTarget.classList.add("text-gray-900")
    }
    this.close()

    this.menuTarget.querySelectorAll("[data-value]").forEach((option) => {
      const check = option.querySelector("[data-check]")
      if (check) check.classList.toggle("invisible", option.dataset.value !== value)
    })

    if (this.autosubmitValue) {
      this.element.closest("form").requestSubmit()
    }
  }

  filter() {
    const query = this.searchTarget.value.toLowerCase()
    this.menuTarget.querySelectorAll("[data-value]").forEach((option) => {
      const label = option.dataset.label.toLowerCase()
      option.classList.toggle("hidden", !label.includes(query))
    })
  }

  openValueChanged() {
    this.menuTarget.classList.toggle("hidden", !this.openValue)
    if (this.openValue && this.hasSearchTarget) {
      setTimeout(() => this.searchTarget.focus(), 0)
    }
    if (!this.openValue && this.hasSearchTarget) {
      this.searchTarget.value = ""
      this.filter()
    }
  }
}
