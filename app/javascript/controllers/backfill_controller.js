import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fixedSection", "columnSection"]

  modeChanged(event) {
    const mode = event.target.value

    this.fixedSectionTarget.classList.toggle("hidden", mode !== "fixed")
    this.columnSectionTarget.classList.toggle("hidden", mode !== "column")
  }
}
