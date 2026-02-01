import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const token = document.querySelector('meta[name="csrf-token"]').content
    const needsRedirect = document.body.hasAttribute("data-edit-mode") && document.body.hasAttribute("data-requires-edit-mode")

    fetch(this.element.dataset.editModeUrlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": token,
        "Accept": "text/html"
      }
    }).then(() => {
      if (needsRedirect) Turbo.visit("/")
    })

    document.body.toggleAttribute("data-edit-mode")
  }
}
