import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "box", "headerCell", "dataCell"]

  toggle(event) {
    const wrapper = event.currentTarget
    const checkbox = wrapper.querySelector("[data-export-preview-target='checkbox']")
    const box = wrapper.querySelector("[data-export-preview-target='box']")
    const columnId = wrapper.dataset.columnId

    // Toggle checkbox state
    const isChecked = !checkbox.disabled
    const newChecked = !isChecked
    checkbox.value = newChecked ? columnId : ""
    checkbox.disabled = !newChecked

    // Update visual state
    box.classList.toggle("bg-gray-900", newChecked)
    box.classList.toggle("bg-white", !newChecked)
    box.classList.toggle("border-gray-900", newChecked)
    box.classList.toggle("border-gray-300", !newChecked)
    box.querySelector("[data-checkmark]").classList.toggle("invisible", !newChecked)

    // Update preview table
    this.headerCellTargets.forEach(cell => {
      if (cell.dataset.columnId === columnId) {
        cell.classList.toggle("hidden", !newChecked)
      }
    })

    this.dataCellTargets.forEach(cell => {
      if (cell.dataset.columnId === columnId) {
        cell.classList.toggle("hidden", !newChecked)
      }
    })
  }

  keydown(event) {
    if (event.key === " " || event.key === "Enter") {
      event.preventDefault()
      this.toggle(event)
    }
  }
}
