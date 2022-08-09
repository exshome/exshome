// Drag and drop inspiration from https://www.petercollingridge.co.uk/tutorials/svg/interactive/dragging/

const debounce = (func, timeout = 200) => {
  let timer;
  return function(...args) {
    clearTimeout(timer);
    timer = setTimeout(() => func.apply(this, args), timeout);
  }
}

export const Automation = {
  selectedElement: null,
  offset: {x: 0, y: 0},

  mounted() {
    this.sendElementSize = this.sendElementSize.bind(this);
    this.sendElementSize();
    window.addEventListener("resize", this.sendElementSize);

    this.el.addEventListener("mousedown", this.startDrag.bind(this));
    this.el.addEventListener("touchstart", this.startDrag.bind(this));
    const drag = debounce(this.drag.bind(this), 5);
    this.el.addEventListener("mousemove", drag);
    this.el.addEventListener("touchmove", drag);
    this.el.addEventListener("mouseup", this.endDrag.bind(this));
    this.el.addEventListener("mouseleave", this.endDrag.bind(this));
    this.el.addEventListener("touchend", this.endDrag.bind(this));
    this.el.addEventListener("touchleave", this.endDrag.bind(this));
    this.el.addEventListener("touchcancel", this.endDrag.bind(this));
  },

  destroyed() {
    window.removeEventListener("resize", this.sendElementSize);
  },

  remounted() {
    this.sendElementSize();
  },

  sendElementSize() {
    this.pushEvent("resize", {height: this.el.clientHeight, width: this.el.clientWidth});
  },

  startDrag(e) {
    if (e.target.dataset["drag"]) {
      e.preventDefault();
      this.selectedElement = e.target;
      const offset = this.getMousePosition(e);
      const position = {
        x: parseFloat(this.selectedElement.getAttributeNS(null, "x")),
        y: parseFloat(this.selectedElement.getAttributeNS(null, "y"))
      }
      offset.x -= position.x;
      offset.y -= position.y;
      this.offset = offset;
      this.pushEvent("select", {id: e.target.id, position});
    }
  },

  drag(e) {
    if (this.selectedElement) {
      e.preventDefault();
      const coord = this.getMousePosition(e);
      this.pushEvent(
        this.selectedElement.dataset["drag"],
        {
          id: this.selectedElement.id,
          x: coord.x - this.offset.x,
          y: coord.y - this.offset.y
        }
      );
    }
  },

  endDrag(e) {
    this.selectedElement = null;
    this.pushEvent("dragend", {});
  },

  getMousePosition(e) {
    if (e.touches) {
      e = e.touches[0];
    }
    return {
      x: e.clientX,
      y: e.clientY
    }
  }
}
