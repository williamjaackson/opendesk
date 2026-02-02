import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "box", "fields", "modeInput", "fixedSection", "columnSection", "fallbackType", "fixedType"]
  static values = { selectOptionsUrl: String }

  connect() {
    if (this.inputTarget.value !== "1") {
      this.modeInputTarget.value = ""
    }
    this.disableHiddenTypeInputs(this.fallbackTypeTargets)
    this.disableHiddenTypeInputs(this.fixedTypeTargets)
    this.observeOptionsTextarea()
  }

  disconnect() {
    if (this.optionsObserver) {
      this.optionsObserver.abort()
    }
  }

  observeOptionsTextarea() {
    const textarea = document.querySelector("textarea[name='custom_column[options_text]']")
    if (!textarea || !this.hasSelectOptionsUrlValue) return

    this.optionsObserver = new AbortController()
    let timer
    textarea.addEventListener("input", () => {
      clearTimeout(timer)
      timer = setTimeout(() => {
        if (this.currentType === "select") this.reloadSelectFrames()
      }, 300)
    }, { signal: this.optionsObserver.signal })
  }

  disableHiddenTypeInputs(targets) {
    targets.forEach(el => {
      if (el.classList.contains("hidden")) {
        el.querySelectorAll("input, select, textarea").forEach(input => {
          input.disabled = true
        })
      }
    })
  }

  toggle() {
    this.inputTarget.value = this.inputTarget.value === "1" ? "0" : "1"
    this.render()
  }

  keydown(event) {
    if (event.key === " " || event.key === "Enter") {
      event.preventDefault()
      this.toggle()
    }
  }

  modeChanged(event) {
    const mode = event.target.value

    this.fixedSectionTarget.classList.toggle("hidden", mode !== "fixed")
    this.columnSectionTarget.classList.toggle("hidden", mode !== "column")
  }

  render() {
    const checked = this.inputTarget.value === "1"

    const colour = getComputedStyle(document.documentElement).getPropertyValue("--theme-colour").trim()
    this.boxTarget.style.backgroundColor = checked ? colour : ""
    this.boxTarget.style.borderColor = checked ? colour : ""
    this.boxTarget.classList.toggle("bg-white", !checked)
    this.boxTarget.classList.toggle("border-gray-300", !checked)
    this.boxTarget.querySelector("[data-checkmark]").classList.toggle("invisible", !checked)
    this.boxTarget.closest("[role='checkbox']").setAttribute("aria-checked", checked)

    this.fieldsTarget.classList.toggle("hidden", !checked)

    if (checked) {
      if (!this.modeInputTarget.value) {
        this.modeInputTarget.value = "fixed"
        this.fixedSectionTarget.classList.remove("hidden")
        this.columnSectionTarget.classList.add("hidden")
      }
    } else {
      this.modeInputTarget.value = ""
      this.fixedSectionTarget.classList.add("hidden")
      this.columnSectionTarget.classList.add("hidden")
    }
  }

  updateFallbackType(event) {
    const type = event.detail.type
    this.currentType = type
    this.showTypeTargets(this.fallbackTypeTargets, type)
    this.showTypeTargets(this.fixedTypeTargets, type)

    if (type === "select") {
      this.reloadSelectFrames()
    }
  }

  showTypeTargets(targets, type) {
    targets.forEach(el => {
      const match = el.dataset.type === type
      el.classList.toggle("hidden", !match)
      el.querySelectorAll("input, select, textarea").forEach(input => {
        input.disabled = !match
        if (!match) input.value = ""
      })

      if (match && type === "boolean") {
        const checkbox = el.querySelector("[data-checkbox-target='input']")
        if (checkbox && checkbox.value === "") checkbox.value = "0"
      }
    })
  }

  frameLoaded() {
    this.disableHiddenTypeInputs(this.fallbackTypeTargets)
    this.disableHiddenTypeInputs(this.fixedTypeTargets)
  }

  reloadSelectFrames() {
    if (!this.hasSelectOptionsUrlValue) return

    const textarea = document.querySelector("textarea[name='custom_column[options_text]']")
    const optionsText = textarea ? textarea.value : ""

    const allSelectDivs = [...this.fixedTypeTargets, ...this.fallbackTypeTargets]
      .filter(el => el.dataset.type === "select")

    allSelectDivs.forEach(el => {
      const frame = el.querySelector("turbo-frame")
      if (!frame) return

      const input = el.querySelector("[data-dropdown-target='input']")

      const url = new URL(this.selectOptionsUrlValue, window.location.origin)
      url.searchParams.set("options_text", optionsText)
      url.searchParams.set("field_name", input ? input.name : "")
      url.searchParams.set("field_id", frame.id.replace("_frame", ""))
      url.searchParams.set("frame_id", frame.id)
      if (input && input.value) url.searchParams.set("value", input.value)

      frame.src = url.toString()
    })
  }
}
