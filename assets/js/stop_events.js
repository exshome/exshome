export const StopEvents = {
  mounted() {
    const preventEvent = function(e) {
      e.stopPropagation();
    }
    this.el.dataset.stopEvents.split(/[,\s]+/g).forEach((event) => {
      this.el.addEventListener(event, preventEvent);
    });
  },
}
