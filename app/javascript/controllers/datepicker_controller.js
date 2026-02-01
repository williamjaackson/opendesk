import { Controller } from "@hotwired/stimulus"

const DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
const MONTHS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
]
const SHORT_MONTHS = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
]

export default class extends Controller {
  static targets = ["input", "display", "calendar"]

  connect() {
    this.viewYear = null
    this.viewMonth = null
    this.open = false
    this.boundClose = this.closeOnOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }

  toggle(event) {
    event.stopPropagation()
    this.open ? this.close() : this.show()
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
    } else if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      this.toggle(event)
    }
  }

  show() {
    const current = this.inputTarget.value
    if (current) {
      const [y, m] = current.split("-").map(Number)
      this.viewYear = y
      this.viewMonth = m - 1
    } else {
      const now = new Date()
      this.viewYear = now.getFullYear()
      this.viewMonth = now.getMonth()
    }
    this.render()
    this.calendarTarget.classList.remove("hidden")
    this.open = true
    document.addEventListener("click", this.boundClose)
  }

  close() {
    this.calendarTarget.classList.add("hidden")
    this.open = false
    document.removeEventListener("click", this.boundClose)
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  prevMonth(event) {
    event.stopPropagation()
    this.viewMonth--
    if (this.viewMonth < 0) {
      this.viewMonth = 11
      this.viewYear--
    }
    this.render()
  }

  nextMonth(event) {
    event.stopPropagation()
    this.viewMonth++
    if (this.viewMonth > 11) {
      this.viewMonth = 0
      this.viewYear++
    }
    this.render()
  }

  selectDay(event) {
    event.stopPropagation()
    const day = parseInt(event.currentTarget.dataset.day, 10)
    const iso = `${this.viewYear}-${String(this.viewMonth + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`
    this.inputTarget.value = iso
    this.displayTarget.value = `${day} ${SHORT_MONTHS[this.viewMonth]} ${this.viewYear}`
    this.close()
  }

  clear(event) {
    event.stopPropagation()
    this.inputTarget.value = ""
    this.displayTarget.value = ""
    this.close()
  }

  render() {
    const year = this.viewYear
    const month = this.viewMonth
    const today = new Date()
    const todayISO = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`
    const selectedISO = this.inputTarget.value

    const firstDay = new Date(year, month, 1).getDay()
    const startOffset = (firstDay + 6) % 7
    const daysInMonth = new Date(year, month + 1, 0).getDate()

    let html = `<div class="flex items-center justify-between px-3 py-2 border-b border-gray-200">`
    html += `<button type="button" data-action="click->datepicker#prevMonth" class="p-1 rounded hover:bg-gray-100" aria-label="Previous month">`
    html += `<svg class="h-4 w-4 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>`
    html += `</button>`
    html += `<span class="text-sm font-medium text-gray-900">${MONTHS[month]} ${year}</span>`
    html += `<button type="button" data-action="click->datepicker#nextMonth" class="p-1 rounded hover:bg-gray-100" aria-label="Next month">`
    html += `<svg class="h-4 w-4 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>`
    html += `</button>`
    html += `</div>`

    html += `<div class="grid grid-cols-7 gap-0 px-2 pt-2">`
    for (const d of DAYS) {
      html += `<div class="text-center text-xs font-medium text-gray-500 py-1">${d}</div>`
    }
    html += `</div>`

    html += `<div class="grid grid-cols-7 gap-0 px-2 pb-2">`
    for (let i = 0; i < startOffset; i++) {
      html += `<div></div>`
    }
    for (let day = 1; day <= daysInMonth; day++) {
      const iso = `${year}-${String(month + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`
      const isSelected = iso === selectedISO
      const isToday = iso === todayISO

      let classes = "flex items-center justify-center h-8 w-8 mx-auto rounded-full text-sm cursor-pointer"
      if (isSelected) {
        classes += " bg-gray-900 text-white font-medium"
      } else if (isToday) {
        classes += " border border-gray-400 text-gray-900 hover:bg-gray-100"
      } else {
        classes += " text-gray-700 hover:bg-gray-100"
      }

      html += `<button type="button" data-action="click->datepicker#selectDay" data-day="${day}" class="${classes}">${day}</button>`
    }
    html += `</div>`

    if (this.inputTarget.value) {
      html += `<div class="border-t border-gray-200 px-3 py-2">`
      html += `<button type="button" data-action="click->datepicker#clear" class="text-xs text-gray-500 hover:text-gray-700">Clear</button>`
      html += `</div>`
    }

    this.calendarTarget.innerHTML = html
  }
}
