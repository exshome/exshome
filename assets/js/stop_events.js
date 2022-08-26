export const StopEvents = {
  mounted() {
    const preventEvent = function(e) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    }
    this.el.dataset.stopEvents.split(/[,\s]+/g).forEach((event) => {
      this.el.addEventListener(event, preventEvent);
    });
  },
}
