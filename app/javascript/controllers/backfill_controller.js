import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "box", "fields", "modeInput", "fixedSection", "columnSection"]

  connect() {
    if (this.inputTarget.value !== "1") {
      this.modeInputTarget.value = ""
    }
  }

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

  modeChanged(event) {
    const mode = event.target.value

    this.fixedSectionTarget.classList.toggle("hidden", mode !== "fixed")
    this.columnSectionTarget.classList.toggle("hidden", mode !== "column")
  }

  render() {
    const checked = this.inputTarget.value === "1"

    this.boxTarget.classList.toggle("bg-gray-900", checked)
    this.boxTarget.classList.toggle("bg-white", !checked)
    this.boxTarget.classList.toggle("border-gray-900", checked)
    this.boxTarget.classList.toggle("border-gray-300", !checked)
    this.boxTarget.querySelector("[data-checkmark]").classList.toggle("invisible", !checked)
    this.boxTarget.closest("[role='checkbox']").setAttribute("aria-checked", checked)

    this.fieldsTarget.classList.toggle("hidden", !checked)

    if (checked) {
      if (!this.modeInputTarget.value) {
        this.modeInputTarget.value = "fixed"
        this.fixedSectionTarget.classList.remove("hidden")
        this.columnSectionTarget.classList.add("hidden")
      }
    } else {
      this.modeInputTarget.value = ""
      this.fixedSectionTarget.classList.add("hidden")
      this.columnSectionTarget.classList.add("hidden")
    }
  }
}
