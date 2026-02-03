import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "message"]
  static values = { message: String }

  show(event) {
    event.preventDefault()
    this.triggerElement = event.currentTarget
    this.messageTarget.textContent = this.messageValue
    this.dialogTarget.showModal()
  }

  cancel() {
    this.dialogTarget.close()
  }

  confirm() {
    this.dialogTarget.close()

    // Find the form to submit - could be the trigger itself or its parent form
    const form = this.triggerElement.closest("form") || this.triggerElement.form
    if (form) {
      form.requestSubmit()
    }
  }

  backdropClick(event) {
    // Close if clicking the backdrop (the dialog element itself, not its contents)
    if (event.target === this.dialogTarget) {
      this.cancel()
    }
  }
}
