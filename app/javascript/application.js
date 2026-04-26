// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

const initializeAutoResizeFields = () => {
  const textareas = document.querySelectorAll(".auto-resize");

  textareas.forEach((textarea) => {
    if (textarea.dataset.autoResizeInitialized === "true") {
      textarea.style.height = "auto";
      textarea.style.height = textarea.scrollHeight + "px";
      return;
    }

    const resize = () => {
      textarea.style.height = "auto";
      textarea.style.height = textarea.scrollHeight + "px";
    };

    textarea.addEventListener("input", resize);
    textarea.dataset.autoResizeInitialized = "true";

    resize();
  });
};

const copyText = async (text) => {
  if (navigator.clipboard?.writeText) {
    try {
      await navigator.clipboard.writeText(text);
      return;
    } catch (error) {
      // Fall back for browsers or contexts where the async clipboard API is unavailable.
    }
  }

  const temporaryInput = document.createElement("textarea");
  temporaryInput.value = text;
  temporaryInput.setAttribute("readonly", "");
  temporaryInput.style.position = "absolute";
  temporaryInput.style.left = "-9999px";
  document.body.appendChild(temporaryInput);
  temporaryInput.select();
  const copied = document.execCommand("copy");
  document.body.removeChild(temporaryInput);

  if (!copied) {
    throw new Error("Copy command failed");
  }
};

const initializeCopyButtons = () => {
  const buttons = document.querySelectorAll("[data-copy-button]");

  buttons.forEach((button) => {
    if (button.dataset.copyInitialized === "true") return;

    button.addEventListener("click", async () => {
      const text = button.dataset.copyText;
      if (!text) return;

      try {
        await copyText(text);
      } catch (error) {
        console.error("Copy failed", error);
      }
    });

    button.dataset.copyInitialized = "true";
  });
};

const initializeStatusArchiveForms = () => {
  const triggers = document.querySelectorAll("[data-status-archive-trigger]");
  const selectButtons = document.querySelectorAll("[data-status-select]");
  const cancelButtons = document.querySelectorAll("[data-status-cancel]");
  const dialogs = document.querySelectorAll("dialog[id^='status-dialog-']");

  triggers.forEach((trigger) => {
    if (trigger.dataset.statusArchiveInitialized === "true") return;

    trigger.addEventListener("click", () => {
      const dialog = document.getElementById(trigger.dataset.dialogId);

      if (!dialog?.showModal) return;

      dialog.dataset.activeTriggerId = trigger.id || "";
      dialog.showModal();
    });

    trigger.dataset.statusArchiveInitialized = "true";
  });

  selectButtons.forEach((button) => {
    if (button.dataset.statusSelectInitialized === "true") return;

    button.addEventListener("click", () => {
      const dialog = document.getElementById(button.dataset.dialogId);
      if (!dialog) return;

      const trigger = dialog.dataset.activeTriggerId ? document.getElementById(dialog.dataset.activeTriggerId) : null;
      const form = trigger?.closest("form");
      const statusField = form?.querySelector("[data-status-archive-target]");

      if (!trigger || !form || !statusField) return;

      statusField.value = button.dataset.statusSelect;
      dialog.close("submitted");
      form.requestSubmit();
    });

    button.dataset.statusSelectInitialized = "true";
  });

  cancelButtons.forEach((button) => {
    if (button.dataset.statusCancelInitialized === "true") return;

    button.addEventListener("click", () => {
      const dialog = document.getElementById(button.dataset.dialogId);
      if (!dialog) return;

      dialog.close();
    });

    button.dataset.statusCancelInitialized = "true";
  });

  dialogs.forEach((dialog) => {
    if (dialog.dataset.statusDialogInitialized === "true") return;

    dialog.addEventListener("close", () => {
      delete dialog.dataset.activeTriggerId;
    });

    dialog.dataset.statusDialogInitialized = "true";
  });
};

const initializePage = () => {
  initializeAutoResizeFields();
  initializeCopyButtons();
  initializeStatusArchiveForms();
};

document.addEventListener("turbo:load", () => {
  initializePage();

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
