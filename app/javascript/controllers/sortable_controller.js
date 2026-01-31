import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = {
    url: String,
    direction: { type: String, default: "vertical" },
    handle: String,
    fallback: { type: Boolean, default: false }
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      direction: this.directionValue,
      draggable: "[data-sortable-id]",
      handle: this.hasHandleValue ? this.handleValue : undefined,
      forceFallback: this.fallbackValue,
      onEnd: this.onEnd.bind(this)
    })
  }

  disconnect() {
    this.sortable.destroy()
  }

  onEnd() {
    const ids = [...this.element.querySelectorAll("[data-sortable-id]")].map(
      (el) => el.dataset.sortableId
    )

    const primaryBadges = this.element.querySelectorAll("[data-primary-badge]")
    if (primaryBadges.length > 0) {
      primaryBadges.forEach((badge) => badge.remove())
      const firstItem = this.element.querySelector("[data-sortable-id]")
      if (firstItem) {
        const nameCell = firstItem.querySelector("[data-field-name]")
        if (nameCell) {
          const badge = document.createElement("span")
          badge.setAttribute("data-primary-badge", "")
          badge.className = "ml-2 inline-flex items-center rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600"
          badge.textContent = "Primary"
          nameCell.appendChild(badge)
        }
      }
    }

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({ ids })
    })
  }
}
