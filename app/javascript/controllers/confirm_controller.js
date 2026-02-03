import { Controller } from "@hotwired/stimulus"

// Global dialog element - created once and reused
let globalDialog = null
let pendingForm = null

function getOrCreateDialog() {
  // Check if dialog still exists in DOM (Turbo may have removed it)
  if (globalDialog && globalDialog.isConnected) return globalDialog

  globalDialog = document.createElement("dialog")
  globalDialog.className = "backdrop:bg-gray-900/50 bg-transparent p-0 m-auto rounded-lg"
  globalDialog.innerHTML = `
    <div class="bg-white rounded-lg shadow-xl border border-gray-200 w-96 overflow-hidden">
      <div class="px-5 py-4">
        <h3 class="text-base font-semibold text-gray-900 mb-2">Confirm action</h3>
        <p data-message class="text-sm text-gray-600"></p>
      </div>
      <div class="flex justify-end gap-2 px-5 py-3 bg-gray-50 border-t border-gray-200">
        <button type="button" data-cancel
          class="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-gray-700 rounded-md border border-gray-300 bg-white hover:bg-gray-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-500 focus-visible:ring-offset-2 transition-colors cursor-pointer select-none">
          Cancel
        </button>
        <button type="button" data-confirm
          class="inline-flex items-center gap-1.5 px-4 py-2 bg-red-600 text-white text-sm font-medium rounded-md hover:bg-red-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-600 focus-visible:ring-offset-2 transition-colors cursor-pointer select-none">
          Delete
        </button>
      </div>
    </div>
  `

  globalDialog.addEventListener("click", (e) => {
    if (e.target === globalDialog) {
      globalDialog.close()
      pendingForm = null
    }
  })

  globalDialog.querySelector("[data-cancel]").addEventListener("click", () => {
    globalDialog.close()
    pendingForm = null
  })

  globalDialog.querySelector("[data-confirm]").addEventListener("click", () => {
    globalDialog.close()
    if (pendingForm) {
      pendingForm.requestSubmit()
      pendingForm = null
    }
  })

  document.body.appendChild(globalDialog)
  return globalDialog
}

export default class extends Controller {
  static values = { message: String, buttonText: String }

  show(event) {
    event.preventDefault()

    const dialog = getOrCreateDialog()
    const form = this.element.querySelector("form") || this.element.closest("form")

    dialog.querySelector("[data-message]").textContent = this.messageValue
    dialog.querySelector("[data-confirm]").textContent = this.buttonTextValue || "Delete"

    pendingForm = form
    dialog.showModal()
  }
}
