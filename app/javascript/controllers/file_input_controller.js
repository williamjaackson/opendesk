import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "filename", "submit"]

  select() {
    this.inputTarget.click()
  }

  changed() {
    const file = this.inputTarget.files[0]
    if (file) {
      this.filenameTarget.textContent = file.name
      this.filenameTarget.classList.remove("text-gray-400")
      this.filenameTarget.classList.add("text-gray-700")
      if (this.hasSubmitTarget) {
        this.submitTarget.disabled = false
        this.submitTarget.classList.remove("opacity-50", "cursor-not-allowed")
        this.submitTarget.classList.add("cursor-pointer")
      }
    } else {
      this.filenameTarget.textContent = "No file selected"
      this.filenameTarget.classList.remove("text-gray-700")
      this.filenameTarget.classList.add("text-gray-400")
      if (this.hasSubmitTarget) {
        this.submitTarget.disabled = true
        this.submitTarget.classList.add("opacity-50", "cursor-not-allowed")
        this.submitTarget.classList.remove("cursor-pointer")
      }
    }
  }
}
