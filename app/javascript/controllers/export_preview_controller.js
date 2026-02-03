import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "headerCell", "dataCell"]

  toggle(event) {
    const columnId = event.target.value
    const isChecked = event.target.checked

    // Find all header and data cells for this column
    this.headerCellTargets.forEach(cell => {
      if (cell.dataset.columnId === columnId) {
        cell.classList.toggle("hidden", !isChecked)
      }
    })

    this.dataCellTargets.forEach(cell => {
      if (cell.dataset.columnId === columnId) {
        cell.classList.toggle("hidden", !isChecked)
      }
    })
  }
}
