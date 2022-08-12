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
  originalTouches: null,
  offset: {x: 0, y: 0},

  mounted() {
    this.sendElementSize = this.sendElementSize.bind(this);
    this.sendElementSize();
    window.addEventListener("resize", this.sendElementSize);

    this.el.addEventListener("mousedown", this.startDrag.bind(this));
    this.el.addEventListener("touchstart", this.startDrag.bind(this));

    const dragDesktop = debounce(this.dragDesktop.bind(this), 5);
    this.el.addEventListener("mousemove", dragDesktop);

    const dragMobile = debounce(this.dragMobile.bind(this), 5);
    this.el.addEventListener("touchmove", dragMobile);

    this.el.addEventListener("mouseup", this.endDrag.bind(this));
    this.el.addEventListener("mouseleave", this.endDrag.bind(this));
    this.el.addEventListener("touchend", this.endDrag.bind(this));
    this.el.addEventListener("touchleave", this.endDrag.bind(this));
    this.el.addEventListener("touchcancel", this.endDrag.bind(this));

    const zoomDesktop = debounce(this.zoomDesktop.bind(this), 10);
    this.el.addEventListener("mousewheel", zoomDesktop);
    this.el.addEventListener("DOMMouseScroll", zoomDesktop);
  },

  destroyed() {
    window.removeEventListener("resize", this.sendElementSize);
  },

  reconnected() {
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

      if (e.touches && e.touches.length > 1) {
        this.originalTouches = {
          position,
          touches: [e.touches[0], e.touches[1]].map(this.getMousePosition)
        };
      }
    }
  },

  dragDesktop(e) {
    if (this.selectedElement) {
      e.preventDefault();
      this.sendDragEvent(e);
    }
  },

  dragMobile(e) {
    if (e.touches.length > 1) {
      e.preventDefault();
      const touches = [e.touches[0], e.touches[1]].map(this.getMousePosition);
      this.zoomMobile(touches);
      return;
    }
    if (this.selectedElement) {
      e.preventDefault();
      this.sendDragEvent(e.touches[0]);
    }
  },

  sendDragEvent(e) {
    const coord = this.getMousePosition(e);
    this.pushEvent(
      this.selectedElement.dataset["drag"],
      {
        id: this.selectedElement.id,
        x: coord.x - this.offset.x,
        y: coord.y - this.offset.y
      }
    );
  },

  endDrag(e) {
    this.selectedElement = null;
    this.originalTouches = null;
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
  },

  zoomDesktop(e) {
    const position = this.getMousePosition(e);
    const delta = Math.max(
      -1,
      Math.min(1, e.wheelDelta || -e.detail)
    );
    this.pushEvent("zoom-desktop", {position, delta});
  },

  zoomMobile(touches) {
    if (this.originalTouches) {
      this.pushEvent("zoom-mobile", {original: this.originalTouches, current: touches});
    }
  },
}
