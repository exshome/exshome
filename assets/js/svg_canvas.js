// Drag and drop inspiration from https://www.petercollingridge.co.uk/tutorials/svg/interactive/dragging/

const debounce = (func, timeout = 200) => {
  let timer;
  return function(...args) {
    clearTimeout(timer);
    timer = setTimeout(() => func.apply(this, args), timeout);
  }
}

export const SvgCanvas = {
  pointerPosition: {x: 0, y: 0},
  originalTouches: null,
  selectedElement: null,

  mounted() {
    this.extractPointerPosition = this.extractPointerPosition.bind(this);

    this.onResize = this.onResize.bind(this);
    this.onResize();
    window.addEventListener("resize", this.onResize);

    const withPointer = this.withPointerPositionCallback.bind(this);
    this.el.addEventListener("mousedown", withPointer(this.onDragStart));
    this.el.addEventListener("touchstart", withPointer(this.onDragStart));

    const onDragDesktop = debounce(this.onDragDesktop.bind(this), 5);
    this.el.addEventListener("mousemove", withPointer(onDragDesktop));

    const onDragMobile = debounce(this.onDragMobile.bind(this), 5);
    this.el.addEventListener("touchmove", withPointer(onDragMobile));

    this.el.addEventListener("mouseup", withPointer(this.onDragEnd));
    this.el.addEventListener("mouseleave", withPointer(this.onDragEnd));
    this.el.addEventListener("touchend", withPointer(this.onDragEnd));
    this.el.addEventListener("pointerup", withPointer(this.onDragEnd));
    this.el.addEventListener("pointerleave", withPointer(this.onDragEnd));
    this.el.addEventListener("touchleave", withPointer(this.onDragEnd));
    this.el.addEventListener("touchcancel", withPointer(this.onDragEnd));

    const onScrollDesktop = debounce(this.onScrollDesktop.bind(this), 10);
    this.el.addEventListener("mousewheel", withPointer(onScrollDesktop));
    this.el.addEventListener("DOMMouseScroll", withPointer(onScrollDesktop));

    this.handleEvent("select-item", this.handleSelectItem.bind(this));
  },

  clearSelectedElement() {
    this.selectedElement = null;
  },

  clearTouches() {
    this.originalTouches = null;
  },

  destroyed() {
    window.removeEventListener("resize", this.onResize);
  },

  extractPointerPosition(e) {
    if (e.touches && e.touches.length > 0) {
      e = e.touches[0];
    }

    if (!e.clientX || !e.clientY) {
      return null;
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
      x: this.pointerPosition.x - (boundaries.x - parentBoundaries.x),
      y: this.pointerPosition.y - (boundaries.y - parentBoundaries.y)
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

  handleSelectItem({component}) {
    if (this.selectedElement) {
      this.onDragEnd();
    }

    const selectedElement = this.el.querySelector(`[data-component=${component}]`);
    if (selectedElement) {
      this.selectedElement = selectedElement;
      this.pushEvent("select", {
        component: this.selectedElement.dataset.component,
        pointer: this.pointerPosition,
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
      this.clearSelectedElement();
    }
  },

  onDragEnd() {
    if (this.selectedElement) {
      this.pushEvent(
        "dragend",
        {
          pointer: this.pointerPosition
        }
      );
    }
    this.clearSelectedElement();
  },

  onDragMobile(e) {
    if (e.touches.length > 1) {
      if (this.selectedElement) {
        this.clearSelectedElement();
      }
      e.preventDefault();
      const touches = [e.touches[0], e.touches[1]].map(this.extractPointerPosition);
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
      this.handleSelectItem({component: e.target.dataset.component});
      this.setMobileTouches(e);
    }
  },

  onResize() {
    this.pushEvent("resize", {height: this.el.clientHeight, width: this.el.clientWidth});
  },

  onScrollDesktop(e) {
    e.preventDefault();
    if (e.ctrlKey) {
      const delta = Math.max(
        -1,
        Math.min(1, e.wheelDelta || -e.detail)
      );
      this.pushEvent("zoom-desktop", {pointer: this.pointerPosition, delta});
    }
  },

  reconnected() {
    this.onResize();
  },

  sendDragEvent(e) {
    this.pushEvent(
      this.selectedElement.dataset["drag"],
      {
        pointer: this.pointerPosition
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
        touches: [e.touches[0], e.touches[1]].map(this.extractPointerPosition)
      };
    }
  },

  withPointerPositionCallback(fn) {
    const handler = fn.bind(this);

    const resultFn = function(e) {
      const pointerPosition = this.extractPointerPosition(e);
      if (pointerPosition) {
        this.pointerPosition = pointerPosition;
      }
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
