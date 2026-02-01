import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dollars", "cents", "input"]

  connect() {
    const value = this.inputTarget.value
    if (value && value.includes(".")) {
      const [dollars, cents] = value.split(".")
      this.dollarsTarget.value = this.formatWithCommas(dollars)
      this.centsTarget.value = cents
    }
    this.resize()
  }

  update() {
    const rawDollars = this.dollarsTarget.value.replace(/[^\d]/g, "")
    const cents = this.centsTarget.value.replace(/\D/g, "").slice(0, 2)

    this.dollarsTarget.value = rawDollars ? this.formatWithCommas(rawDollars) : ""
    this.centsTarget.value = cents

    if (rawDollars === "" && cents === "") {
      this.inputTarget.value = ""
    } else {
      this.inputTarget.value = `${rawDollars || "0"}.${cents.padEnd(2, "0")}`
    }
    this.resize()
  }

  dollarsKeydown(event) {
    if (event.key === ".") {
      event.preventDefault()
      this.centsTarget.focus()
      this.centsTarget.select()
    }
  }

  centsKeydown(event) {
    if (event.key === "Backspace" && this.centsTarget.selectionStart === 0 && this.centsTarget.selectionEnd === 0) {
      event.preventDefault()
      const val = this.dollarsTarget.value
      this.dollarsTarget.value = val.slice(0, -1)
      this.dollarsTarget.focus()
      const len = this.dollarsTarget.value.length
      this.dollarsTarget.setSelectionRange(len, len)
      this.update()
    }
  }

  padCents() {
    const cents = this.centsTarget.value.replace(/\D/g, "").slice(0, 2)
    if (cents.length === 1) {
      this.centsTarget.value = cents + "0"
      this.update()
    }
  }

  formatWithCommas(value) {
    return value.replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  }

  resize() {
    const len = this.dollarsTarget.value.length || 1
    this.dollarsTarget.style.width = `${len + 0.5}ch`
  }
}
