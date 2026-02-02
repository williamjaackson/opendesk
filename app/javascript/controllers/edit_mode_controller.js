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
      document.body.toggleAttribute("data-edit-mode")

      const isOn = document.body.hasAttribute("data-edit-mode")
      document.querySelectorAll('[data-controller="edit-mode"] input[type="checkbox"]')
        .forEach(cb => cb.checked = isOn)

      if (needsRedirect) Turbo.visit("/")
    })
  }
}
