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
    this.extractMousePosition = this.extractMousePosition.bind(this);

    this.onResize = this.onResize.bind(this);
    this.onResize();
    window.addEventListener("resize", this.onResize);

    this.el.addEventListener("mousedown", this.onDragStart.bind(this));
    this.el.addEventListener("touchstart", this.onDragStart.bind(this));

    const onDragDesktop = debounce(this.onDragDesktop.bind(this), 5);
    this.el.addEventListener("mousemove", onDragDesktop);

    const onDragMobile = debounce(this.onDragMobile.bind(this), 5);
    this.el.addEventListener("touchmove", onDragMobile);

    this.el.addEventListener("mouseup", this.onDragEnd.bind(this));
    this.el.addEventListener("mouseleave", this.onDragEnd.bind(this));
    this.el.addEventListener("touchend", this.onDragEnd.bind(this));
    this.el.addEventListener("touchleave", this.onDragEnd.bind(this));
    this.el.addEventListener("touchcancel", this.onDragEnd.bind(this));

    const onZoomDesktop = debounce(this.onZoomDesktop.bind(this), 10);
    this.el.addEventListener("mousewheel", onZoomDesktop);
    this.el.addEventListener("DOMMouseScroll", onZoomDesktop);

    this.handleEvent("move-to-foreground", this.handleMoveToForeground.bind(this));
    this.handleEvent("select-item", this.handleSelectItem.bind(this));
  },

  destroyed() {
    window.removeEventListener("resize", this.onResize);
  },

  reconnected() {
    this.onResize();
  },

  extractMousePosition(e) {
    if (e.touches) {
      e = e.touches[0];
    }
    const boundingRect = this.el.getBoundingClientRect()
    return {
      x: e.clientX - boundingRect.left,
      y: e.clientY - boundingRect.top
    }
  },

  getSelectedElementPosition() {
    return {
      x: parseFloat(this.selectedElement.getAttributeNS(null, "x")),
      y: parseFloat(this.selectedElement.getAttributeNS(null, "y"))
    }
  },

  handleMoveToForeground({id, parent}) {
    const component = this.el.getElementById(id);
    const parentComponent = this.el.getElementById(parent);
    if (component && parent) {
      parentComponent.appendChild(component);
    }
  },

  handleSelectItem({id}) {
    const selectedElement = this.el.getElementById(id);
    if (selectedElement) {
      this.selectedElement = selectedElement;
    }
  },

  onDragDesktop(e) {
    const buttonIsPressed = e.buttons !== 0;
    if (this.selectedElement && buttonIsPressed) {
      e.preventDefault();
      this.sendDragEvent(e);
    }
  },

  onDragEnd(e) {
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

  onDragMobile(e) {
    if (e.touches.length > 1) {
      e.preventDefault();
      const touches = [e.touches[0], e.touches[1]].map(this.extractMousePosition);
      this.zoomMobile(touches);
      return;
    }
    if (this.selectedElement) {
      e.preventDefault();
      this.sendDragEvent(e.touches[0]);
    }
  },

  onDragStart(e) {
    if (e.target.dataset["drag"]) {
      e.preventDefault();
      this.selectedElement = e.target;
      const offset = this.extractMousePosition(e);
      const position = this.getSelectedElementPosition();
      offset.x -= position.x;
      offset.y -= position.y;
      this.offset = offset;
      this.pushEvent("select", {id: e.target.id, position});
      this.setMobileTouches(e);
    }
  },

  onResize() {
    this.pushEvent("resize", {height: this.el.clientHeight, width: this.el.clientWidth});
  },

  onZoomDesktop(e) {
    const position = this.extractMousePosition(e);
    const delta = Math.max(
      -1,
      Math.min(1, e.wheelDelta || -e.detail)
    );
    this.pushEvent("zoom-desktop", {position, delta});
  },

  sendDragEvent(e) {
    const coord = this.extractMousePosition(e);
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

  setMobileTouches(e) {
    if (e.touches && e.touches.length > 1) {
      const position = {
        x: parseFloat(this.el.dataset.viewboxX),
        y: parseFloat(this.el.dataset.viewboxY)
      }
      this.originalTouches = {
        position,
        touches: [e.touches[0], e.touches[1]].map(this.extractMousePosition)
      };
    }
  },

  zoomMobile(touches) {
    if (this.originalTouches) {
      this.pushEvent("zoom-mobile", {original: this.originalTouches, current: touches});
    }
  },
}
