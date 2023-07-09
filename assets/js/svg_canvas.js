// Drag and drop inspiration from https://www.petercollingridge.co.uk/tutorials/svg/interactive/dragging/

export const SvgCanvas = {
  eventQueue: [],
  pointerPosition: {x: 0, y: 0},
  originalTouches: null,
  selectedElement: null,
  sending: false,

  mounted() {
    this.queueEvent = this.queueEvent.bind(this);
    this.processEventQueue = this.processEventQueue.bind(this);
    this.extractPointerPosition = this.extractPointerPosition.bind(this);

    this.onResize = this.onResize.bind(this);
    this.onResize();
    window.addEventListener("resize", this.onResize);

    const withPointer = this.withPointerPositionCallback.bind(this);
    this.el.addEventListener("mousedown", withPointer(this.onDragStart));
    this.el.addEventListener("touchstart", withPointer(this.onDragStart));

    const onDragDesktop = this.onDragDesktop.bind(this);
    this.el.addEventListener("mousemove", withPointer(onDragDesktop));

    const onDragMobile = this.onDragMobile.bind(this);
    this.el.addEventListener("touchmove", withPointer(onDragMobile));

    this.el.addEventListener("mouseup", withPointer(this.onDragEnd));
    this.el.addEventListener("mouseleave", withPointer(this.onDragEnd));
    this.el.addEventListener("touchend", withPointer(this.onDragEnd));
    this.el.addEventListener("pointerup", withPointer(this.onDragEnd));
    this.el.addEventListener("pointerleave", withPointer(this.onDragEnd));
    this.el.addEventListener("touchleave", withPointer(this.onDragEnd));
    this.el.addEventListener("touchcancel", withPointer(this.onDragEnd));

    const onScrollDesktop = this.onScrollDesktop.bind(this);
    this.el.addEventListener("mousewheel", withPointer(onScrollDesktop));
    this.el.addEventListener("DOMMouseScroll", withPointer(onScrollDesktop));

    this.handleEvent("select-item", this.handleSelectItem.bind(this));
    this.handleEvent("move-to-foreground", this.handleMoveToForeground.bind(this));
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

  handleMoveToForeground({component}) {
     const childComponent = this.el.querySelector(`[data-component=${component}]`);
     const parentComponent = childComponent?.parentElement;
     const canvasComponent = parentComponent?.parentElement;
     if (parentComponent && canvasComponent) {
       canvasComponent.appendChild(parentComponent);
     }
  },

  handleSelectItem({component}) {
    if (this.selectedElement) {
      this.onDragEnd();
    }

    this.selectedElement = this.el.querySelector(`[data-component=${component}]`)
    if (this.selectedElement) {
      this.queueEvent("select", {
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
    } else if (this.selectedElement) {
      this.onDragEnd();
    }
  },

  onDragEnd() {
    if (this.selectedElement) {
      this.queueEvent(
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
    this.queueEvent("resize", {height: this.el.clientHeight, width: this.el.clientWidth});
  },

  onScrollDesktop(e) {
    e.preventDefault();
    if (e.ctrlKey) {
      const delta = Math.max(
        -1,
        Math.min(1, e.wheelDelta || -e.detail)
      );
      this.queueEvent("zoom-desktop", {pointer: this.pointerPosition, delta});
    }
  },

  processEventQueue() {
    if (this.sending) {
      return;
    }

    const event = this.eventQueue.shift();
    if (event) {
      this.sending = true;
      this.pushEvent(event.name, event.payload, () => {
        this.sending = false;
        this.processEventQueue();
      })
    }
  },

  queueEvent(name, payload) {
    const event = {name, payload};
    while (this.eventQueue[this.eventQueue.length - 1]?.name === name) {
      this.eventQueue.pop();
    }
    this.eventQueue.push(event);
    this.processEventQueue();
  },

  reconnected() {
    this.onResize();
  },

  sendDragEvent(e) {
    this.queueEvent(
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
      this.queueEvent("zoom-mobile", {original: this.originalTouches, current: touches});
    }
  },
}
