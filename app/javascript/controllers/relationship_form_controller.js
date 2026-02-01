import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "inverseName", "targetTableId", "kind"]
  static values = {
    sourceTable: String,
    sourceTableSingular: String,
    sourceTableId: String
  }

  connect() {
    this.lastAutoName = null
    this.lastAutoInverse = null
  }

  updateDefaults() {
    const tableId = this.targetTableIdTarget.value
    if (!tableId) return

    const option = this.element.querySelector(`[data-action="dropdown#select"][data-value="${tableId}"]`)
    if (!option) return

    const tablePlural = option.dataset.label
    const tableSingular = option.dataset.singular ?? tablePlural

    this.updateKindLabels(tablePlural, tableSingular)

    const kind = this.kindTarget.value
    if (!kind) return

    let autoName, autoInverse
    const isSelfReferential = tableId === this.sourceTableIdValue

    if (isSelfReferential) {
      if (kind === "one_to_one") {
        autoName = "Partner"
        autoInverse = "Partner"
      } else if (kind === "one_to_many") {
        autoName = "Children"
        autoInverse = "Parent"
      } else if (kind === "many_to_one") {
        autoName = "Parent"
        autoInverse = "Children"
      } else {
        autoName = "Related"
        autoInverse = "Related"
      }
    } else if (kind === "one_to_one") {
      autoName = tableSingular
      autoInverse = this.sourceTableSingularValue
    } else if (kind === "one_to_many") {
      autoName = tablePlural
      autoInverse = this.sourceTableSingularValue
    } else if (kind === "many_to_one") {
      autoName = tableSingular
      autoInverse = this.sourceTableValue
    } else {
      autoName = tablePlural
      autoInverse = this.sourceTableValue
    }

    const nameField = this.nameTarget
    if (!nameField.value || nameField.value === this.lastAutoName) {
      nameField.value = autoName
    }
    this.lastAutoName = autoName

    const inverseField = this.inverseNameTarget
    if (!inverseField.value || inverseField.value === this.lastAutoInverse) {
      inverseField.value = autoInverse
    }
    this.lastAutoInverse = autoInverse
  }

  updateKindLabels(targetPlural, targetSingular) {
    const sourcePlural = this.sourceTableValue
    const sourceSingular = this.sourceTableSingularValue

    const labels = {
      one_to_one: `One ${sourceSingular} to one ${targetSingular}`,
      one_to_many: `One ${sourceSingular} to many ${targetPlural}`,
      many_to_one: `Many ${sourcePlural} to one ${targetSingular}`,
      many_to_many: `Many ${sourcePlural} to many ${targetPlural}`
    }

    const dropdown = this.kindTarget.closest("[data-controller='dropdown']")
    if (!dropdown) return

    Object.entries(labels).forEach(([value, label]) => {
      const btn = dropdown.querySelector(`[data-value="${value}"]`)
      if (btn) {
        btn.dataset.label = label
        btn.querySelector("span").textContent = label
      }
    })

    if (this.kindTarget.value && labels[this.kindTarget.value]) {
      const button = dropdown.querySelector("[data-dropdown-target='button']")
      if (button) button.value = labels[this.kindTarget.value]
    }
  }
}
