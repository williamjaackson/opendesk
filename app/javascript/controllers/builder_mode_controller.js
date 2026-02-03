import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const token = document.querySelector('meta[name="csrf-token"]').content
    const needsRedirect = document.body.hasAttribute("data-builder-mode") && document.body.hasAttribute("data-requires-builder-mode")

    fetch(this.element.dataset.builderModeUrlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": token,
        "Accept": "text/html"
      }
    }).then(() => {
      document.body.toggleAttribute("data-builder-mode")

      const isOn = document.body.hasAttribute("data-builder-mode")
      document.querySelectorAll('[data-controller="builder-mode"] input[type="checkbox"]')
        .forEach(cb => cb.checked = isOn)

      if (needsRedirect) Turbo.visit("/")
    })
  }
}
