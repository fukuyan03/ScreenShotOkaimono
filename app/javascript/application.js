// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("DOMContentLoaded", () => {
  const textareas = document.querySelectorAll(".auto-resize");

  textareas.forEach((textarea) => {
    const resize = () => {
      textarea.style.height = "auto";
      textarea.style.height = textarea.scrollHeight + "px";
    };

    textarea.addEventListener("input", resize);

    resize();
  });

  const sliders = document.querySelectorAll("[data-step-slider]");

  sliders.forEach((slider) => {
    const track = slider.querySelector("[data-step-track]");
    const dots = Array.from(slider.querySelectorAll("[data-step-dot]"));
    const prevButton = slider.querySelector("[data-step-prev]");
    const nextButton = slider.querySelector("[data-step-next]");

    if (!track || dots.length === 0) return;

    const slides = Array.from(track.children);

    const updateDots = () => {
      const index = Math.round(track.scrollLeft / track.clientWidth);

      dots.forEach((dot, dotIndex) => {
        const active = dotIndex === index;
        dot.classList.toggle("w-8", active);
        dot.classList.toggle("bg-red-500", active);
        dot.classList.toggle("w-2.5", !active);
        dot.classList.toggle("bg-white/25", !active);
      });
    };

    const scrollToIndex = (index) => {
      track.scrollTo({
        left: track.clientWidth * index,
        behavior: "smooth"
      });
    };

    dots.forEach((dot, index) => {
      dot.addEventListener("click", () => scrollToIndex(index));
    });

    prevButton?.addEventListener("click", () => {
      const index = Math.round(track.scrollLeft / track.clientWidth);
      scrollToIndex(Math.max(index - 1, 0));
    });

    nextButton?.addEventListener("click", () => {
      const index = Math.round(track.scrollLeft / track.clientWidth);
      scrollToIndex(Math.min(index + 1, slides.length - 1));
    });

    track.addEventListener("scroll", updateDots, { passive: true });
    window.addEventListener("resize", updateDots);
    updateDots();
  });
});
