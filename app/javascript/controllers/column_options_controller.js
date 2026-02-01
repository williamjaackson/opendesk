import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "required"]

  connect() {
    const input = this.element.querySelector("input[name*='column_type']")
    if (input && input.value) {
      this.showOptions(input.value)
    }
  }

  typeChanged(event) {
    this.showOptions(event.target.value)
  }

  showOptions(type) {
    this.containerTarget.classList.remove("hidden")
    this.requiredTarget.classList.toggle("hidden", type === "boolean")
  }
}
