import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "full", "link"]

  connect() {
    this.expanded = false
    this.render()
  }

  toggle(event) {
    event.preventDefault()
    this.expanded = !this.expanded
    this.render()
  }

  render() {
    this.previewTarget.classList.toggle("hidden", this.expanded)
    this.fullTarget.classList.toggle("hidden", !this.expanded)
    this.linkTarget.textContent = this.expanded ? "Hide Full Description" : "View Full Description"
  }
}
