;;; init-ui --- settings for ui

;;; Commentary:
;;; Code:

(use-package doom-themes
  :demand t
  :init
  (load-theme 'doom-one t)
  :config
  (doom-themes-org-config))

(use-package smart-mode-line
  :init
  (setq sml/no-confirm-load-theme t
	sml/theme 'respectful)
  :config
  (sml/setup))

(use-package emacs
  :ensure nil
  :init
  (set-face-attribute 'default nil
		      :font "Maple Mono"
		      :height 160)
  (set-fontset-font t 'han
		    (font-spec :family "Noto Sans CJK SC"))
  (setq font-lock-maximum-decoration t))


(use-package emacs
  :ensure nil
  :config
  (setq display-line-numbers-type 'relative)
  (global-display-line-numbers-mode t))

(use-package emacs
  :ensure nil
  :config
  (with-eval-after-load 'lsp-bridge
    ;; Inlay hints
    (when (facep 'lsp-bridge-inlay-hint-face)
      (set-face-attribute 'lsp-bridge-inlay-hint-face nil
                          :foreground "#5c6370"
                          :height 0.95))

    ;; Rust #[derive(...)] 里的 derive
    (when (facep 'lsp-bridge-semantic-tokens-decorator-face)
      (set-face-attribute 'lsp-bridge-semantic-tokens-decorator-face nil
                          :foreground "#a8a8a8"))

    ;; keyword: italic
    (when (facep 'lsp-bridge-semantic-tokens-keyword-face)
      (set-face-attribute 'lsp-bridge-semantic-tokens-keyword-face nil
                          :slant 'italic))

    (set-face-attribute 'font-lock-keyword-face nil
			:slant 'italic)

    (when (facep 'lsp-bridge-semantic-tokens-namespace-face)
      (set-face-attribute 'lsp-bridge-semantic-tokens-namespace-face nil
			  :foreground "#d19a66"
			  :slant 'normal))

    ;; function
    ;; (when (facep 'lsp-bridge-semantic-tokens-function-face)
    ;;   (set-face-attribute 'lsp-bridge-semantic-tokens-function-face nil
                          ;; :foreground "#31e9d9"))

    ;; method
    ;; (when (facep 'lsp-bridge-semantic-tokens-method-face)
    ;;   (set-face-attribute 'lsp-bridge-semantic-tokens-method-face nil
    ;;                       :foreground "#31e9d9"))

    ;; function.declaration: bold
    (set-face-attribute 'font-lock-function-name-face nil
			:foreground "#31e9d9"
                        :weight 'bold)

    ;; function token
    ;; (when (facep 'lsp-bridge-semantic-tokens-function-face)
    ;;   (set-face-attribute 'lsp-bridge-semantic-tokens-function-face nil
    ;;                       :foreground "#31e9d9"
    ;;                       :weight 'bold))

    ;; class.declaration: bold
    (when (facep 'lsp-bridge-semantic-tokens-class-face)
      (set-face-attribute 'lsp-bridge-semantic-tokens-class-face nil
                          :weight 'bold))

    ;; struct / enum / interface: bold
    (dolist (face '(lsp-bridge-semantic-tokens-struct-face
                    ;; lsp-bridge-semantic-tokens-enum-face
                    lsp-bridge-semantic-tokens-interface-face
                    font-lock-type-face))
      (when (facep face)
        (set-face-attribute face nil
                            :weight 'bold)))))


(provide 'init-ui)

;;; init-ui.el ends here
