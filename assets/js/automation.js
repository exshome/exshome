// Drag and drop inspiration from https://www.petercollingridge.co.uk/tutorials/svg/interactive/dragging/

export const Automation = {
  selectedElement: null,
  offset: {x: 0, y: 0},

  mounted() {
    this.el.addEventListener("mousedown", this.startDrag.bind(this));
    this.el.addEventListener("touchstart", this.startDrag.bind(this));
    this.el.addEventListener("mousemove", this.drag.bind(this));
    this.el.addEventListener("touchmove", this.drag.bind(this));
    this.el.addEventListener("mouseup", this.endDrag.bind(this));
    this.el.addEventListener("mouseleave", this.endDrag.bind(this));
    this.el.addEventListener("touchend", this.endDrag.bind(this));
    this.el.addEventListener("touchleave", this.endDrag.bind(this));
    this.el.addEventListener("touchcancel", this.endDrag.bind(this));
  },

  startDrag(e) {
    if (e.target.classList.contains("draggable")) {
      e.preventDefault();
      this.pushEvent("select", {id: e.target.id});
      this.selectedElement = e.target;
      const offset = this.getMousePosition(e);
      offset.x -= parseFloat(this.selectedElement.getAttributeNS(null, "x"));
      offset.y -= parseFloat(this.selectedElement.getAttributeNS(null, "y"));
      this.offset = offset;
    }
  },

  drag(e) {
    if (this.selectedElement) {
      e.preventDefault();
      const coord = this.getMousePosition(e);
      this.pushEvent("drag", {x: coord.x - this.offset.x, y: coord.y - this.offset.y});
    }
  },

  endDrag(e) {
    this.selectedElement = null;
    this.pushEvent("deselect", {});
  },

  getMousePosition(e) {
    const CTM = this.el.getScreenCTM();
    if (e.touches) {
      e = e.touches[0];
    }
    return {
      x: ((e.clientX - CTM.e) / CTM.a),
      y: ((e.clientY - CTM.f) / CTM.d)
    }
  }
}
