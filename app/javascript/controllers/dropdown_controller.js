import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "input", "search"]
  static values = {
    open: { type: Boolean, default: false },
    autosubmit: { type: Boolean, default: false },
    searchUrl: { type: String, default: "" }
  }

  connect() {
    this.clickOutsideHandler = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    document.addEventListener("click", this.clickOutsideHandler)
    this.focusIndex = -1
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutsideHandler)
  }

  toggle() {
    this.openValue = !this.openValue
  }

  close() {
    this.openValue = false
  }

  get visibleOptions() {
    return [...this.menuTarget.querySelectorAll("[data-value]:not(.hidden)")]
  }

  keydown(event) {
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        if (!this.openValue) {
          this.openValue = true
        } else {
          this.moveFocus(1)
        }
        break
      case "ArrowUp":
        event.preventDefault()
        if (this.openValue) this.moveFocus(-1)
        break
      case "Escape":
        event.preventDefault()
        this.close()
        this.buttonTarget.focus()
        break
      case " ":
        if (this.hasSearchTarget && event.target === this.searchTarget && this.focusIndex < 0) break
        event.preventDefault()
        if (!this.openValue) {
          this.openValue = true
        } else if (this.focusIndex >= 0) {
          const opts = this.visibleOptions
          if (opts[this.focusIndex]) opts[this.focusIndex].click()
        }
        break
      case "Enter":
        if (this.openValue) {
          const options = this.visibleOptions
          const target = this.focusIndex >= 0 ? options[this.focusIndex] : options[0]
          if (target) {
            event.preventDefault()
            target.click()
          }
        }
        break
    }
  }

  moveFocus(direction) {
    const options = this.visibleOptions
    if (options.length === 0) return

    this.focusIndex = Math.max(0, Math.min(options.length - 1, this.focusIndex + direction))
    options.forEach((opt, i) => {
      opt.classList.toggle("bg-gray-100", i === this.focusIndex)
      opt.classList.toggle("hover:bg-gray-50", i !== this.focusIndex)
    })
    options[this.focusIndex].scrollIntoView({ block: "nearest" })
  }

  resetFocus() {
    this.focusIndex = -1
    this.visibleOptions.forEach((opt) => {
      opt.classList.remove("bg-gray-100")
      opt.classList.add("hover:bg-gray-50")
    })
  }

  select(event) {
    const value = event.currentTarget.dataset.value
    const label = event.currentTarget.dataset.label

    this.inputTarget.value = value
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.buttonTarget.value = label
    this.close()
    this.buttonTarget.focus()

    this.menuTarget.querySelectorAll("[data-value]").forEach((option) => {
      const check = option.querySelector("[data-check]")
      if (check) check.classList.toggle("invisible", option.dataset.value !== value)
    })

    if (this.autosubmitValue) {
      this.element.closest("form").requestSubmit()
    }
  }

  filter() {
    // Always do client-side filtering first for instant feedback
    this.clientFilter()

    // Then fetch from server if URL is configured (for large datasets)
    if (this.searchUrlValue) {
      this.serverFilter()
    }
  }

  clientFilter() {
    const query = this.searchTarget.value.toLowerCase()
    this.menuTarget.querySelectorAll("[data-value]").forEach((option) => {
      const label = option.dataset.label.toLowerCase()
      option.classList.toggle("hidden", !label.includes(query))
    })
    this.resetFocus()
  }

  serverFilter() {
    clearTimeout(this.searchTimeout)
    const query = this.searchTarget.value
    if (!query) {
      // Reset to original options when search is cleared
      this.clientFilter()
      return
    }

    this.searchTimeout = setTimeout(() => {
      const url = new URL(this.searchUrlValue, window.location.origin)
      url.searchParams.set("q", query)

      fetch(url, {
        headers: { "Accept": "text/html" }
      })
        .then(response => response.text())
        .then(html => {
          // Only update if the query hasn't changed
          if (this.searchTarget.value === query) {
            const optionsContainer = this.menuTarget.querySelector("[data-dropdown-options]")
            if (optionsContainer) {
              optionsContainer.innerHTML = html
            }
            this.resetFocus()
          }
        })
    }, 300)
  }

  openValueChanged() {
    this.menuTarget.classList.toggle("hidden", !this.openValue)
    if (this.openValue) {
      this.resetFocus()
      if (this.hasSearchTarget) {
        setTimeout(() => this.searchTarget.focus(), 0)
      }
    } else {
      if (this.hasSearchTarget) {
        this.searchTarget.value = ""
        this.filter()
      }
    }
  }
}
