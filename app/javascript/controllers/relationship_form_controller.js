import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "inverseName", "targetTableId", "kind", "directionContainer", "symmetric", "inverseNameContainer"]
  static values = {
    sourceTable: String,
    sourceTableSingular: String,
    sourceTableId: Number
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

    const isSelfRef = parseInt(tableId) === this.sourceTableIdValue

    this.updateDirectionVisibility(isSelfRef, kind)

    const isSymmetric = this.isSymmetric(isSelfRef, kind)

    let autoName, autoInverse

    if (kind === "one_to_one") {
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

    if (isSymmetric) {
      this.inverseNameTarget.value = this.nameTarget.value
    } else {
      const inverseField = this.inverseNameTarget
      if (!inverseField.value || inverseField.value === this.lastAutoInverse) {
        inverseField.value = autoInverse
      }
    }
    this.lastAutoInverse = autoInverse

    if (this.hasInverseNameContainerTarget) {
      this.inverseNameContainerTarget.classList.toggle("hidden", isSymmetric)
      this.inverseNameTarget.required = !isSymmetric
    }
  }

  updateDirectionVisibility(isSelfRef, kind) {
    if (!this.hasDirectionContainerTarget) return

    const showDirection = isSelfRef && kind === "many_to_many"
    this.directionContainerTarget.classList.toggle("hidden", !showDirection)

    if (isSelfRef && kind === "one_to_one") {
      if (this.hasSymmetricTarget) {
        this.symmetricTarget.value = "1"
      }
    }

    if (!showDirection && this.hasSymmetricTarget) {
      if (kind !== "one_to_one" || !isSelfRef) {
        this.symmetricTarget.value = "0"
      }
    }
  }

  isSymmetric(isSelfRef, kind) {
    if (!isSelfRef) return false
    if (kind === "one_to_one") return true
    if (kind === "many_to_many" && this.hasSymmetricTarget && this.symmetricTarget.value === "1") return true
    return false
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
