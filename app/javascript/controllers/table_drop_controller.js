import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  dragover(event) {
    if (!this.builderMode) return
    if (Array.from(event.dataTransfer.types).includes("application/x-sortable-id")) {
      event.preventDefault()
      this.element.classList.add("bg-gray-200")
    }
  }

  dragleave(event) {
    this.element.classList.remove("bg-gray-200")
  }

  drop(event) {
    if (!this.builderMode) return
    event.preventDefault()
    this.element.classList.remove("bg-gray-200")

    const tableId = event.dataTransfer.getData("application/x-sortable-id")
    if (!tableId) return

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ table_id: tableId })
    }).then(() => {
      const activeGroup = document.querySelector("[data-active-group]")
      Turbo.visit(activeGroup ? activeGroup.href : window.location.href)
    })
  }

  get builderMode() {
    return document.body.hasAttribute("data-builder-mode")
  }
}
