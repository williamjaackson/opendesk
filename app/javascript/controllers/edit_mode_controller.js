import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const token = document.querySelector('meta[name="csrf-token"]').content
    fetch(this.element.dataset.editModeUrlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": token,
        "Accept": "text/html"
      }
    })
    document.body.toggleAttribute("data-edit-mode")
    Turbo.visit(window.location.href)
  }
}
