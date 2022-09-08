// Drag and drop inspiration from https://www.petercollingridge.co.uk/tutorials/svg/interactive/dragging/

const debounce = (func, timeout = 200) => {
  let timer;
  return function(...args) {
    clearTimeout(timer);
    timer = setTimeout(() => func.apply(this, args), timeout);
  }
}

export const SvgCanvas = {
  mousePosition: {x: 0, y: 0},
  originalTouches: null,
  selectedElement: null,

  mounted() {
    this.extractMousePosition = this.extractMousePosition.bind(this);

    this.onResize = this.onResize.bind(this);
    this.onResize();
    window.addEventListener("resize", this.onResize);

    const withMouse = this.withMousePositionCallback.bind(this);
    this.el.addEventListener("mousedown", withMouse(this.onDragStart));
    this.el.addEventListener("touchstart", withMouse(this.onDragStart));

    const onDragDesktop = debounce(this.onDragDesktop.bind(this), 5);
    this.el.addEventListener("mousemove", withMouse(onDragDesktop));

    const onDragMobile = debounce(this.onDragMobile.bind(this), 5);
    this.el.addEventListener("touchmove", withMouse(onDragMobile));

    this.el.addEventListener("mouseup", withMouse(this.onDragEnd));
    this.el.addEventListener("mouseleave", withMouse(this.onDragEnd));
    this.el.addEventListener("touchend", withMouse(this.onDragEnd));
    this.el.addEventListener("touchleave", withMouse(this.onDragEnd));
    this.el.addEventListener("touchcancel", withMouse(this.onDragEnd));

    const onZoomDesktop = debounce(this.onZoomDesktop.bind(this), 10);
    this.el.addEventListener("mousewheel", withMouse(onZoomDesktop));
    this.el.addEventListener("DOMMouseScroll", withMouse(onZoomDesktop));

    this.handleEvent("move-to-foreground", this.handleMoveToForeground.bind(this));
    this.handleEvent("select-item", this.handleSelectItem.bind(this));
  },

  clearState() {
    this.selectedElement = null;
    this.originalTouches = null;
  },

  destroyed() {
    window.removeEventListener("resize", this.onResize);
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

  getSelectedElementOffset() {
    const parentBoundaries = this.el.getBoundingClientRect();
    const boundaries = this.selectedElement.getBoundingClientRect();
    const offset = {
      x: this.mousePosition.x - (boundaries.x - parentBoundaries.x),
      y: this.mousePosition.y - (boundaries.y - parentBoundaries.y)
    };
    const itemSize = {
      height: parseFloat(this.selectedElement.getAttributeNS(null, "height")),
      width: parseFloat(this.selectedElement.getAttributeNS(null, "width"))
    };
    return {
      x: offset.x * itemSize.width / boundaries.width,
      y: offset.y * itemSize.height / boundaries.height,
    };
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
      this.pushEvent("select", {
        id: this.selectedElement.id,
        mouse: this.mousePosition,
        offset: this.getSelectedElementOffset(),
        position: this.getSelectedElementPosition()
      });
    }
  },

  onDragDesktop(e) {
    const buttonIsPressed = e.buttons !== 0;
    if (this.selectedElement && buttonIsPressed) {
      e.preventDefault();
      this.sendDragEvent(e);
    } else {
      this.clearState();
    }
  },

  onDragEnd(e) {
    if (this.selectedElement) {
      this.pushEvent(
        "dragend",
        {
          mouse: this.mousePosition
        }
      );
    }
    this.clearState();
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
      this.handleSelectItem({id: e.target.id});
      this.setMobileTouches(e);
    }
  },

  onResize() {
    this.pushEvent("resize", {height: this.el.clientHeight, width: this.el.clientWidth});
  },

  onZoomDesktop(e) {
    const delta = Math.max(
      -1,
      Math.min(1, e.wheelDelta || -e.detail)
    );
    this.pushEvent("zoom-desktop", {mouse: this.mousePosition, delta});
  },

  reconnected() {
    this.onResize();
  },

  sendDragEvent(e) {
    this.pushEvent(
      this.selectedElement.dataset["drag"],
      {
        mouse: this.mousePosition
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

  withMousePositionCallback(fn) {
    const handler = fn.bind(this);

    const resultFn = function(e) {
      this.mousePosition = this.extractMousePosition(e);
      handler(e);
    }

    return resultFn.bind(this);
  },

  zoomMobile(touches) {
    if (this.originalTouches) {
      this.pushEvent("zoom-mobile", {original: this.originalTouches, current: touches});
    }
  },
}
