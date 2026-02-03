import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "existingOptions", "createOptions"]

  actionChanged(event) {
    const row = event.target.closest("[data-import-mapping-target='row']")
    const existingOptions = row.querySelector("[data-import-mapping-target='existingOptions']")
    const createOptions = row.querySelector("[data-import-mapping-target='createOptions']")
    const value = event.target.value

    if (existingOptions) {
      existingOptions.classList.toggle("hidden", value !== "existing")
    }
    if (createOptions) {
      createOptions.classList.toggle("hidden", value !== "create")
    }
  }
}
