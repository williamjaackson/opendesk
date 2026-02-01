import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = {
    url: String,
    direction: { type: String, default: "vertical" },
    handle: String,
    fallback: { type: Boolean, default: false },
    reload: { type: Boolean, default: false }
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      direction: this.directionValue,
      draggable: "[data-sortable-id]",
      handle: this.hasHandleValue ? this.handleValue : undefined,
      forceFallback: this.fallbackValue,
      disabled: !this.editMode,
      setData: (dataTransfer, dragEl) => {
        dataTransfer.setData("application/x-sortable-id", dragEl.dataset.sortableId)
      },
      onStart: this.onStart.bind(this),
      onEnd: this.onEnd.bind(this)
    })

    this.observer = new MutationObserver(() => {
      this.sortable.option("disabled", !this.editMode)
    })
    this.observer.observe(document.body, { attributes: true, attributeFilter: ["data-edit-mode"] })
  }

  disconnect() {
    this.observer.disconnect()
    this.sortable.destroy()
  }

  get editMode() {
    return document.body.hasAttribute("data-edit-mode")
  }

  onStart(evt) {
    if (evt.item.tagName !== "TR") return

    const cells = evt.item.querySelectorAll("td")
    const widths = Array.from(cells).map((cell) => cell.offsetWidth)
    const rowWidth = evt.item.offsetWidth

    const ghost = document.querySelector(".sortable-fallback")
    if (!ghost) return

    ghost.style.width = `${rowWidth}px`
    ghost.style.backgroundColor = "white"
    ghost.style.borderRadius = "0.5rem"
    ghost.style.boxShadow = "0 1px 3px 0 rgb(0 0 0 / 0.1)"
    ghost.querySelectorAll("td").forEach((cell, i) => {
      cell.style.width = `${widths[i]}px`
    })
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
    }).then(() => {
      if (this.reloadValue) Turbo.visit(window.location.href)
    })
  }
}
