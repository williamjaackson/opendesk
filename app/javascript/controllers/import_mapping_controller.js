import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "existingOptions", "createOptions", "input", "option"]

  select(event) {
    const row = event.currentTarget.closest("[data-import-mapping-target='row']")
    const value = event.currentTarget.dataset.value
    const input = row.querySelector("[data-import-mapping-target='input']")

    input.value = value

    // Update radio button visuals
    row.querySelectorAll("[data-import-mapping-target='option']").forEach(option => {
      const isSelected = option.dataset.value === value
      const dot = option.querySelector("[data-dot]")
      const ring = option.querySelector("[data-ring]")

      ring.classList.toggle("border-gray-900", isSelected)
      ring.classList.toggle("border-gray-300", !isSelected)
      dot.classList.toggle("invisible", !isSelected)
    })

    // Show/hide options
    const existingOptions = row.querySelector("[data-import-mapping-target='existingOptions']")
    const createOptions = row.querySelector("[data-import-mapping-target='createOptions']")

    if (existingOptions) {
      existingOptions.classList.toggle("hidden", value !== "existing")
    }
    if (createOptions) {
      createOptions.classList.toggle("hidden", value !== "create")
    }
  }

  keydown(event) {
    if (event.key === " " || event.key === "Enter") {
      event.preventDefault()
      this.select(event)
    }
  }
}
