import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "filename"]

  select() {
    this.inputTarget.click()
  }

  changed() {
    const file = this.inputTarget.files[0]
    if (file) {
      this.filenameTarget.textContent = file.name
      this.filenameTarget.classList.remove("text-gray-400")
      this.filenameTarget.classList.add("text-gray-700")
    } else {
      this.filenameTarget.textContent = "No file selected"
      this.filenameTarget.classList.remove("text-gray-700")
      this.filenameTarget.classList.add("text-gray-400")
    }
  }
}
