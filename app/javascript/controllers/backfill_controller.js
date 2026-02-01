import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "box", "fields", "modeInput", "fixedSection", "columnSection", "fallbackType", "fixedType"]

  connect() {
    if (this.inputTarget.value !== "1") {
      this.modeInputTarget.value = ""
    }
    this.disableHiddenTypeInputs(this.fallbackTypeTargets)
    this.disableHiddenTypeInputs(this.fixedTypeTargets)
  }

  disableHiddenTypeInputs(targets) {
    targets.forEach(el => {
      if (el.classList.contains("hidden")) {
        el.querySelectorAll("input, select, textarea").forEach(input => {
          input.disabled = true
        })
      }
    })
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

  updateFallbackType(event) {
    const type = event.detail.type
    this.showTypeTargets(this.fallbackTypeTargets, type)
    this.showTypeTargets(this.fixedTypeTargets, type)
  }

  showTypeTargets(targets, type) {
    targets.forEach(el => {
      const match = el.dataset.type === type
      el.classList.toggle("hidden", !match)
      el.querySelectorAll("input, select, textarea").forEach(input => {
        input.disabled = !match
        if (!match) input.value = ""
      })
    })
  }
}
