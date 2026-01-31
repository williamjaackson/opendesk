import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "inverseName", "targetTableId", "kind"]
  static values = {
    sourceTable: String,
    sourceTableSingular: String
  }

  connect() {
    this.lastAutoName = null
    this.lastAutoInverse = null
  }

  updateDefaults() {
    const tableId = this.targetTableIdTarget.value
    const kind = this.kindTarget.value
    if (!tableId || !kind) return

    const option = this.element.querySelector(`[data-action="dropdown#select"][data-value="${tableId}"]`)
    if (!option) return

    const tablePlural = option.dataset.label
    const tableSingular = option.dataset.singular || tablePlural

    let autoName, autoInverse

    if (kind === "has_one") {
      autoName = tableSingular
      autoInverse = this.sourceTableSingularValue
    } else if (kind === "has_many") {
      autoName = tablePlural
      autoInverse = this.sourceTableSingularValue
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
}
