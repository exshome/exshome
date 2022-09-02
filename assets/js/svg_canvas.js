// Drag and drop inspiration from https://www.petercollingridge.co.uk/tutorials/svg/interactive/dragging/

const debounce = (func, timeout = 200) => {
  let timer;
  return function(...args) {
    clearTimeout(timer);
    timer = setTimeout(() => func.apply(this, args), timeout);
  }
}

export const SvgCanvas = {
  selectedElement: null,
  originalTouches: null,
  offset: {x: 0, y: 0},

  mounted() {
    this.getMousePosition = this.getMousePosition.bind(this);

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

    this.handleEvent("move-to-foreground", this.moveToForeground.bind(this));
  },

  destroyed() {
    window.removeEventListener("resize", this.sendElementSize);
  },

  reconnected() {
    this.sendElementSize();
  },

  dragDesktop(e) {
    const buttonIsPressed = e.buttons !== 0;
    if (this.selectedElement && buttonIsPressed) {
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

  endDrag(e) {
    if (this.selectedElement) {
      this.pushEvent(
        "dragend",
        {
          id: this.selectedElement.id,
          position: this.getSelectedElementPosition(),
        }
      );
    }
    this.selectedElement = null;
    this.originalTouches = null;
  },

  getSelectedElementPosition() {
    return {
      x: parseFloat(this.selectedElement.getAttributeNS(null, "x")),
      y: parseFloat(this.selectedElement.getAttributeNS(null, "y"))
    }
  },

  getMousePosition(e) {
    if (e.touches) {
      e = e.touches[0];
    }
    const boundingRect = this.el.getBoundingClientRect()
    return {
      x: e.clientX - boundingRect.left,
      y: e.clientY - boundingRect.top
    }
  },

  moveToForeground({id, parent}) {
    const component = this.el.getElementById(id);
    const parentComponent = this.el.getElementById(parent);
    if (component && parent) {
      parentComponent.appendChild(component);
    }
  },

  sendDragEvent(e) {
    const coord = this.getMousePosition(e);
    this.pushEvent(
      this.selectedElement.dataset["drag"],
      {
        id: this.selectedElement.id,
        x: coord.x - this.offset.x,
        y: coord.y - this.offset.y,
        mouse: coord,
      }
    );
  },

  sendElementSize() {
    this.pushEvent("resize", {height: this.el.clientHeight, width: this.el.clientWidth});
  },

  setMobileTouches(e) {
    if (e.touches && e.touches.length > 1) {
      const position = {
        x: parseFloat(this.el.dataset.viewboxX),
        y: parseFloat(this.el.dataset.viewboxY)
      }
      this.originalTouches = {
        position,
        touches: [e.touches[0], e.touches[1]].map(this.getMousePosition)
      };
    }
  },

  startDrag(e) {
    if (e.target.dataset["drag"]) {
      e.preventDefault();
      this.selectedElement = e.target;
      const offset = this.getMousePosition(e);
      const position = this.getSelectedElementPosition();
      offset.x -= position.x;
      offset.y -= position.y;
      this.offset = offset;
      this.pushEvent("select", {id: e.target.id, position});
      this.setMobileTouches(e);
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
