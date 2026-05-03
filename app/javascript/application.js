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

const initializeImagePreviews = () => {
  const inputs = document.querySelectorAll("[data-image-preview-input]");

  inputs.forEach((input) => {
    if (input.dataset.imagePreviewInitialized === "true") return;

    const previewId = input.dataset.imagePreviewTarget;
    if (!previewId) return;

    const image = document.querySelector(`[data-image-preview-image][data-image-preview-for="${previewId}"]`);
    const placeholder = document.querySelector(`[data-image-preview-placeholder][data-image-preview-for="${previewId}"]`);

    if (!image || !placeholder) return;

    const updatePreview = (src) => {
      if (src) {
        image.src = src;
        image.style.display = "block";
        placeholder.style.display = "none";
      } else {
        image.removeAttribute("src");
        image.style.display = "none";
        placeholder.style.display = "flex";
      }
    };

    input.addEventListener("change", () => {
      const [file] = input.files || [];

      if (!file || !file.type.startsWith("image/")) {
        updatePreview("");
        return;
      }

      const reader = new FileReader();
      reader.addEventListener("load", () => updatePreview(reader.result));
      reader.readAsDataURL(file);
    });

    input.dataset.imagePreviewInitialized = "true";
  });
};

const setAiAnalyzeButtonState = (button, loading) => {
  if (!button) return;

  const label = button.querySelector("[data-ai-analyze-label]");
  const spinner = button.querySelector("[data-ai-analyze-spinner]");
  const defaultText = button.dataset.aiAnalyzeDefaultText || "AI解析";
  const loadingText = button.dataset.aiAnalyzeLoadingText || "解析中...";

  button.disabled = loading;
  button.setAttribute("aria-busy", loading ? "true" : "false");
  button.classList.toggle("opacity-70", loading);
  button.classList.toggle("cursor-not-allowed", loading);

  if (label) {
    label.textContent = loading ? loadingText : defaultText;
  }

  if (spinner) {
    spinner.classList.toggle("hidden", !loading);
  }
};

const initializeAiAnalyzeSubmitState = () => {
  if (document.documentElement.dataset.aiAnalyzeSubmitInitialized === "true") return;

  document.addEventListener("turbo:submit-start", (event) => {
    const submitter = event.detail.formSubmission?.submitter;

    if (!(submitter instanceof HTMLElement)) return;
    if (!submitter.matches("[data-ai-analyze-submit]")) return;

    setAiAnalyzeButtonState(submitter, true);
  });

  document.addEventListener("turbo:submit-end", (event) => {
    const submitter = event.detail.formSubmission?.submitter;

    if (!(submitter instanceof HTMLElement)) return;
    if (!submitter.matches("[data-ai-analyze-submit]")) return;
    if (event.detail.success) return;

    setAiAnalyzeButtonState(submitter, false);
  });

  document.documentElement.dataset.aiAnalyzeSubmitInitialized = "true";
};

const initializePage = () => {
  initializeAutoResizeFields();
  initializeCopyButtons();
  initializeStatusArchiveForms();
  initializeImagePreviews();
  initializeAiAnalyzeSubmitState();
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
