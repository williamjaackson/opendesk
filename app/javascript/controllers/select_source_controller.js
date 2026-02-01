import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sourceInput", "manualOptions", "linkedOptions", "linkedTableInput", "linkedColumnInput"]
  static values = { tables: Array }

  connect() {
    const isLinked = this.sourceInputTarget.value === "linked"
    this.manualOptionsTarget.classList.toggle("hidden", isLinked)
    this.linkedOptionsTarget.classList.toggle("hidden", !isLinked)
  }

  sourceChanged(event) {
    const isLinked = event.target.value === "linked"
    this.manualOptionsTarget.classList.toggle("hidden", isLinked)
    this.linkedOptionsTarget.classList.toggle("hidden", !isLinked)

    if (!isLinked) {
      this.resetDropdown(this.linkedTableInputTarget)
      this.resetDropdown(this.linkedColumnInputTarget)
      this.clearColumnOptions()
    }
  }

  tableChanged() {
    const tableId = parseInt(this.linkedTableInputTarget.value)
    this.populateColumns(tableId)
  }

  populateColumns(tableId) {
    this.resetDropdown(this.linkedColumnInputTarget)
    const dropdownEl = this.linkedColumnInputTarget.closest("[data-controller='dropdown']")
    const optionsContainer = dropdownEl.querySelector("[data-dropdown-target='menu'] .py-1")
    optionsContainer.innerHTML = ""

    const table = this.tablesValue.find(t => t.id === tableId)
    if (!table) return

    table.columns.forEach(col => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.tabIndex = -1
      btn.dataset.action = "dropdown#select"
      btn.dataset.value = col.id
      btn.dataset.label = col.name
      btn.className = "flex items-center justify-between w-full px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 cursor-pointer"

      const label = document.createElement("span")
      label.textContent = col.name

      const check = document.createElement("span")
      check.dataset.check = ""
      check.className = "invisible"
      check.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4 text-gray-900"><path d="M20 6 9 17l-5-5"></path></svg>'

      btn.appendChild(label)
      btn.appendChild(check)
      optionsContainer.appendChild(btn)
    })
  }

  resetDropdown(inputTarget) {
    const dropdownEl = inputTarget.closest("[data-controller='dropdown']")
    inputTarget.value = ""
    dropdownEl.querySelector("[data-dropdown-target='button']").value = ""
    dropdownEl.querySelectorAll("[data-check]").forEach(el => el.classList.add("invisible"))
  }

  clearColumnOptions() {
    const dropdownEl = this.linkedColumnInputTarget.closest("[data-controller='dropdown']")
    const optionsContainer = dropdownEl.querySelector("[data-dropdown-target='menu'] .py-1")
    if (optionsContainer) optionsContainer.innerHTML = ""
  }
}
