import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "required", "selectOptions", "regexOptions", "formulaOptions", "backfillOptions"]

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
    const isComputed = type === "computed"

    this.containerTarget.classList.remove("hidden")
    this.requiredTarget.classList.toggle("hidden", type === "boolean" || isComputed)

    if (this.hasSelectOptionsTarget) {
      this.selectOptionsTarget.classList.toggle("hidden", type !== "select")
    }

    if (this.hasRegexOptionsTarget) {
      this.regexOptionsTarget.classList.toggle("hidden", isComputed || (type !== "text" && type !== "number" && type !== "decimal"))
    }

    if (this.hasFormulaOptionsTarget) {
      this.formulaOptionsTarget.classList.toggle("hidden", !isComputed)
    }

    if (this.hasBackfillOptionsTarget) {
      this.backfillOptionsTarget.classList.toggle("hidden", isComputed)
    }

    this.dispatch("typeChanged", { detail: { type } })
  }
}
