;;; init-ui.el -- Settings for ui -*- lexical-binding: t -*-

;;; Commentary:
;;; Code:

(use-package emacs
  :straight nil
  :init
  (set-face-attribute 'default nil
              :font "Maple Mono"
              :height 160)
  (set-fontset-font t 'han
            (font-spec :family "Noto Sans CJK SC"))
  (setq font-lock-maximum-decoration t))


(use-package emacs
  :straight nil
  :config
  (setq-default indent-tabs-mode nil
                tab-width 4
                standard-indent 4)
  (setq display-line-numbers-type 'relative)
  (global-display-line-numbers-mode t)
  (global-hl-line-mode 1))

(use-package whitespace
  :straight nil
  :hook (prog-mode . whitespace-mode)
  :init
  (setq whitespace-style '(face tabs tab-mark trailing spaces space-mark))
  (setq whitespace-display-mappings
        '((tab-mark 9 [187 9] [92 9])        ; [TAB] -> >>
        ;;  (space-mark 32 [183] [46])         ; [space] -> .
          (fullwidth-space 12288 [9633]))))

(use-package emacs
  :straight nil
  :config
  (with-eval-after-load 'lsp-bridge
    ;; Inlay hints
    (when (facep 'lsp-bridge-inlay-hint-face)
      (set-face-attribute 'lsp-bridge-inlay-hint-face nil
                          :foreground "#5c6370"
                          :height 0.95))

    ;; decorator
    (when (facep 'lsp-bridge-semantic-tokens-decorator-face)
      (set-face-attribute 'lsp-bridge-semantic-tokens-decorator-face nil
                          :foreground "#a8a8a8"))

    ;; keyword: italic
    (when (facep 'lsp-bridge-semantic-tokens-keyword-face)
      (set-face-attribute 'lsp-bridge-semantic-tokens-keyword-face nil
                          :slant 'italic))

    (set-face-attribute 'font-lock-keyword-face nil
                        :foreground "#c678dd"
                        :slant 'italic)

    (set-face-attribute 'font-lock-variable-name-face nil
                        :foreground "#e06c75")

    (set-face-attribute 'font-lock-variable-use-face nil
                        :foreground "#e06c75")

    (set-face-attribute 'font-lock-function-call-face nil
                        :foreground "#61afef"
                        :weight 'regular
                        :slant 'normal)

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

    (set-face-attribute 'font-lock-function-call-face nil
                        :foreground "#31e9d9")

    (set-face-attribute 'font-lock-builtin-face nil
                        :foreground "#31e9d9")

    (set-face-attribute 'font-lock-property-use-face nil
                        :foreground "#56b6c2")
    ;; function token
    ;; (when (facep 'lsp-bridge-semantic-tokens-function-face)
    ;;   (set-face-attribute 'lsp-bridge-semantic-tokens-function-face nil
    ;;                       :foreground "#31e9d9"
    ;;                       :weight 'bold))

    ;; comment
    (set-face-attribute 'font-lock-comment-face nil
                        :slant 'italic)

    ;; class.declaration: bold
    (when (facep 'lsp-bridge-semantic-tokens-class-face)
      (set-face-attribute 'lsp-bridge-semantic-tokens-class-face nil
                          :weight 'bold))

    ;; struct / enum / interface: bold
    (dolist (face '(lsp-bridge-semantic-tokens-struct-face
                    ;; lsp-bridge-semantic-tokens-enum-face
                    ;; font-lock-type-face
                    lsp-bridge-semantic-retokens-interface-face))
      (when (facep face)
        (set-face-attribute face nil
                            :weight 'bold)))))
(use-package diff-mode
  :straight nil
  :config
  (setq diff-refine nil))

(use-package doom-themes
  :demand t
  :init
  (load-theme 'doom-one t)
  :config
  (doom-themes-org-config))

(use-package nerd-icons
  :custom
  (nerd-icons-font-family "CaskaydiaMonoNerdFontPropo"))

(use-package doom-modeline
  :init
  (column-number-mode 1)
  (doom-modeline-mode 1)
  :config
  (set-face-attribute 'mode-line nil
                      :family "CaskaydiaMonoNerdFontPropo"
                      :height 120)
  (set-face-attribute 'mode-line-active nil
                      :family "CaskaydiaMonoNerdFontPropo"
                      :height 120)
  (set-face-attribute 'mode-line-inactive nil
                      :family "CaskaydiaMonoNerdFontPropo"
                      :height 120))

(use-package breadcrumb
  :defer 1
  :custom
  (breadcrumb-imenu-max-length 1000)
  :init
  (defun my-breadcrumb-imenu-only ()
    "Show only imenu breadcrumbs in header line."
    (setq-local header-line-format
                '((:eval (breadcrumb-imenu-crumbs)))))
  :hook
  ((prog-mode . my-breadcrumb-imenu-only)))

(use-package dashboard
  :init
  (setq dashboard-startupify-list '(dashboard-insert-banner
                                        ; dashboard-insert-navigator
                                    dashboard-insert-init-info
                                    dashboard-insert-items)
        dashboard-startup-banner 'logo-braille
        dashboard-center-content t
        dashboard-items '((projects . 5)
                          (recents . 5))
        dashboard-projects-backend 'project-el
        dashboard-icon-type 'nerd-icons
        dashboard-set-file-icons t
        initial-buffer-choice #'dashboard-open)
  :config
  (dashboard-setup-startup-hook))

(use-package nerd-icons-dired
  :hook
  (dired-mode . nerd-icons-dired-mode))

(with-eval-after-load 'acm-icon
  (defun my/nerd-icons-by-name (name &rest args)
    "Return nerd-icons icon by full icon NAME."
    (apply
     (cond
      ((string-prefix-p "nf-cod-" name) #'nerd-icons-codicon)
      ((string-prefix-p "nf-md-" name) #'nerd-icons-mdicon)
      ((string-prefix-p "nf-fa-" name) #'nerd-icons-faicon)
      ((string-prefix-p "nf-fae-" name) #'nerd-icons-faicon)
      ((string-prefix-p "nf-oct-" name) #'nerd-icons-octicon)
      ((string-prefix-p "nf-dev-" name) #'nerd-icons-devicon)
      ((string-prefix-p "nf-seti-" name) #'nerd-icons-sucicon)
      ((string-prefix-p "nf-custom-" name) #'nerd-icons-sucicon)
      ((string-prefix-p "nf-weather-" name) #'nerd-icons-wicon)
      ((string-prefix-p "nf-iec-" name) #'nerd-icons-ipsicon)
      ((string-prefix-p "nf-linux-" name) #'nerd-icons-flicon)
      ((string-prefix-p "nf-pom-" name) #'nerd-icons-pomicon)
      (t #'nerd-icons-codicon))
     name
     args))

  (defun my/acm-icon-build-around (orig-fun icon face background)
    "Use nerd-icons when ICON is marked as a nerd icon."
    (if (and (consp icon)
             (eq (car icon) :nerd))
        (concat
         " "
         (my/nerd-icons-by-name (cadr icon) :face face)
         " ")
      (funcall orig-fun icon face background)))

  (advice-add 'acm-icon-build :around #'my/acm-icon-build-around)

  (defun my/acm-icon (icon-name face)
    "Build ACM icon data from nerd-icons ICON-NAME with FACE."
    (list (list :nerd icon-name) face nil))

  (setq acm-icon-alist
        `(("function"  . ,(my/acm-icon "nf-md-function_variant" 'font-lock-constant-face))
          ("method"    . ,(my/acm-icon "nf-cod-symbol_method" 'font-lock-function-constant-face))
          ("keyword"   . ,(my/acm-icon "nf-cod-key" 'font-lock-constant-face))
          ("module"    . ,(my/acm-icon "nf-md-package_variant_closed" 'font-lock-constant-face))
          ("package"   . ,(my/acm-icon "nf-cod-package" 'font-lock-constant-face))
          ("namespace" . ,(my/acm-icon "nf-cod-symbol_namespace" 'font-lock-constant-face))
          ("snippet"   . ,(my/acm-icon "nf-md-bash" 'font-lock-constant-face))
          ("text"      . ,(my/acm-icon "nf-cod-symbol_parameter" 'font-lock-constant-face))
          ("variable"  . ,(my/acm-icon "nf-md-variable" 'font-lock-constant-face))
          ("class"     . ,(my/acm-icon "nf-md-alphabetical_variant" 'font-lock-constant-face))
          ("interface" . ,(my/acm-icon "nf-cod-symbol_interface" 'font-lock-constant-face))
          ("field"     . ,(my/acm-icon "nf-cod-symbol_field" 'font-lock-constant-face))
          ("property"  . ,(my/acm-icon "nf-cod-symbol_property" 'font-lock-constant-face))
          ("enum"      . ,(my/acm-icon "nf-cod-symbol_enum" 'font-lock-constant-face))
          ("constant"  . ,(my/acm-icon "nf-cod-symbol_constant" 'font-lock-constant-face))
          ("file"      . ,(my/acm-icon "nf-oct-file" 'font-lock-constant-face))
          ("folder"    . ,(my/acm-icon "nf-oct-file_directory" 'font-lock-constant-face))
          (t           . ,(my/acm-icon "nf-cod-symbol_misc" 'font-lock-constant-face)))))

(use-package colorful-mode
  :defer 2
  :custom
  (colorful-use-prefix t)
  (colorful-prefix-string "■")
  (colorful-only-strings 'only-prog)
  (css-fontify-colors nil)
  :config
  (global-colorful-mode 1))

(provide 'init-ui)

;;; init-ui.el ends here
