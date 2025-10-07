import { Controller } from "@hotwired/stimulus"

// Steuert einzelne Panels über aria-controls und vermeidet "zu kleine" Höhen.
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this._onEnd = this._onEnd.bind(this)
    // start: zugeklappt vorbereiten (ohne display:none)
    this.panelTargets.forEach(p => {
      if (!p.dataset.collapseInit) {
        p.style.overflow = "hidden"
        p.style.maxHeight = "0px"
        p.setAttribute("aria-hidden", "true")
        p.dataset.state = "closed"
        p.dataset.collapseInit = "true"
      }
    })
    // Auf Größenänderungen reagieren
    this._refreshBound = this.refresh.bind(this)
    window.addEventListener("resize", this._refreshBound)
    document.addEventListener("turbo:render", this._refreshBound)
  }

  disconnect() {
    window.removeEventListener("resize", this._refreshBound)
    document.removeEventListener("turbo:render", this._refreshBound)
  }

  toggle(e) {
    const btn = e.currentTarget
    const panel = this._panelFor(btn)
    if (!panel) return
    const isOpen = panel.dataset.state === "open" || panel.dataset.state === "opening"
    isOpen ? this._close(panel, btn) : this._open(panel, btn)
  }

  _open(panel, btn) {
    panel.removeEventListener("transitionend", this._onEnd)
    panel.style.transition = "max-height .25s ease"
    panel.style.overflow = "hidden"
    panel.setAttribute("aria-hidden", "false")
    btn?.setAttribute("aria-expanded", "true")

    // Von evtl. "none" in messbaren Zustand bringen
    if (getComputedStyle(panel).maxHeight === "none") {
      panel.style.maxHeight = panel.scrollHeight + "px"
    }
    // Reflow erzwingen und dann auf Zielhöhe animieren
    panel.style.maxHeight = "0px"
    // eslint-disable-next-line no-unused-expressions
    panel.offsetHeight
    panel.style.maxHeight = panel.scrollHeight + "px"

    panel.dataset.state = "opening"
    panel.addEventListener("transitionend", this._onEnd, { once: true })
  }

  _close(panel, btn) {
    panel.removeEventListener("transitionend", this._onEnd)
    panel.style.transition = "max-height .25s ease"
    panel.style.overflow = "hidden"

    // Falls zuvor auf "none", aktuelle Höhe setzen, damit animierbar
    if (getComputedStyle(panel).maxHeight === "none") {
      panel.style.maxHeight = panel.scrollHeight + "px"
      // eslint-disable-next-line no-unused-expressions
      panel.offsetHeight
    }
    panel.style.maxHeight = "0px"
    panel.setAttribute("aria-hidden", "true")
    btn?.setAttribute("aria-expanded", "false")
    panel.dataset.state = "closed"
  }

  _onEnd(event) {
    const panel = event.currentTarget
    if (!panel) return
    // Nach dem Öffnen die Höhen-Bremse lösen, damit weiterer Inhalt sichtbar wird
    if (panel.dataset.state === "opening") {
      panel.style.maxHeight = "none"
      panel.dataset.state = "open"
    }
  }

  refresh() {
    // Offene Panels kurz anstoßen, damit sie neue Inhalte mitnehmen
    this.panelTargets.forEach(panel => {
      if (panel.dataset.state === "open") {
        panel.style.maxHeight = panel.scrollHeight + "px"
        // eslint-disable-next-line no-unused-expressions
        panel.offsetHeight
        panel.style.maxHeight = "none"
      }
    })
  }

  _panelFor(btn) {
    const id = btn.getAttribute("aria-controls")
    return id ? document.getElementById(id) : null
  }
}
