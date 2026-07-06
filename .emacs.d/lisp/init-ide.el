;;; init-ide.el --- Settings for lsp -*- lexical-binding: t -*-

;;; Commentary:
;;; Code:

(use-package treesit
  :straight nil
  :init
  (setq treesit-language-source-alist
        '((python "https://github.com/tree-sitter/tree-sitter-python" "v0.23.2")
          (rust "https://github.com/tree-sitter/tree-sitter-rust" "v0.23.2")
          (c "https://github.com/tree-sitter/tree-sitter-c" "v0.23.2")
          (cpp "https://github.com/tree-sitter/tree-sitter-cpp" "v0.23.2")
          (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.2" "typescript/src")
          (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.2" "tsx/src")
          (vue "https://github.com/ikatyang/tree-sitter-vue")
          (yaml "https://github.com/tree-sitter-grammars/tree-sitter-yaml" "v0.7.0" "src")
          (json "https://github.com/tree-sitter/tree-sitter-json")
          (qmljs "https://github.com/yuja/tree-sitter-qmljs"))
        treesit-font-lock-level 4))

(use-package python-ts-mode
  :straight nil
  :mode ("\\.py\\'" . python-ts-mode)
  :init
  (setq python-indent-offset 4)
  (add-to-list 'major-mode-remap-alist
               '(python-mode . python-ts-mode)))

(use-package rust-ts-mode
  :straight nil
  :mode ("\\.rs\\'" . rust-ts-mode)
  :init
  (setq rust-ts-mode-indent-offset 4))

(use-package c-ts-mode
  :straight nil
  :mode
  (("\\.c\\'" . c-ts-mode)
   ("\\.h\\'" . c-ts-mode)
   ("\\.cc\\'" . c++-ts-mode)
   ("\\.cpp\\'" . c++-ts-mode)
   ("\\.cxx\\'" . c++-ts-mode)
   ("\\.hpp\\'" . c++-ts-mode)
   ("\\.hh\\'" . c++-ts-mode)
   ("\\.hxx\\'" . c++-ts-mode))
  :init
  (setq c-ts-mode-indent-offset 4
        c-ts-mode-enable-doxygen t)
  (add-to-list 'major-mode-remap-alist
               '(c-mode . c-ts-mode))
  (add-to-list 'major-mode-remap-alist
               '(c++-mode . c++-ts-mode)))

(use-package fsharp-ts-mode
  :straight (:type git :host github :repo "bbatsov/fsharp-ts-mode")
  :mode
  (("\\.fs\\'" . fsharp-ts-mode)
   ("\\.fsi\\'" . fsharp-ts-mode)
   ("\\.fsx\\'" . fsharp-ts-mode)
   ("\\.fsproj\\'" . nxml-mode))
  :config
  (setq fsharp-ts-indent-offset 4))

(use-package web-mode
  :mode
  (("\\.html\\'" . web-mode)
   ("\\.html\\.j2\\'" . web-mode)
   ("\\.html\\.jinja\\'" . web-mode)
   ("\\.html\\.jinja2\\'" . web-mode)
   ("\\.j2\\'" . web-mode))
  :config
  (setq web-mode-engines-alist
        '(("jinja" . "\\.html\\.j2\\'")
          ("jinja" . "\\.html\\.jinja\\'")
          ("jinja" . "\\.html\\.jinja2\\'")
          ("jinja" . "\\.j2\\'")))

  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2)

  (with-eval-after-load 'evil
    (evil-define-key 'normal web-mode-map
      (kbd "<tab>") #'web-mode-fold-or-unfold)))

(use-package typescript-ts-mode
  :straight nil
  :mode
  (("\\.ts\\'" . typescript-ts-mode)
   ("\\.tsx\\'" . tsx-ts-mode)))

(use-package vue-ts-mode
  :straight (:type git :host github :repo "8uff3r/vue-ts-mode")
  :mode "\\.vue\\'")

(use-package markdown-mode
  :mode "\\.md\\'"
  :config
  (setq markdown-list-item-bullets '("•")))

(use-package yaml-ts-mode
  :straight nil
  :mode ("\\.ya?ml\\'" . yaml-ts-mode))

(use-package json-ts-mode
  :straight nil
  :mode
  (("\\.json\\'" . json-ts-mode)
   ("\\.jsonc\\'" . json-ts-mode)))

(use-package nxml-mode
  :straight nil
  :mode "\\.xml\\'")

(use-package qml-ts-mode
  :straight (:type git :host github :repo "xhcoding/qml-ts-mode")
  :mode "\\.qml\\'"
  ;; :init
  ;; (setq qml-ts-mode-indent-offset 2)
  )

(use-package yasnippet
  :config
  (yas-global-mode 1))


(defun my/lsp-bridge-diagnostic-severity->flycheck (severity)
  (pcase severity
    (1 'error)
    (2 'warning)
    (3 'info)
    (4 'info)
    (_ 'warning)))


(defun my/flycheck-lsp-bridge-start (checker callback)
  (let ((errors
         (mapcar
          (lambda (diag)
            (let* ((range (plist-get diag :range))
                   (start (plist-get range :start))
                   (line (1+ (plist-get start :line)))
                   (column (1+ (plist-get start :character)))
                   (severity (plist-get diag :severity))
                   (message (plist-get diag :message))
                   (source (plist-get diag :source)))
              (flycheck-error-new-at
               line
               column
               (my/lsp-bridge-diagnostic-severity->flycheck severity)
               (if source
                   (format "[%s] %s" source message)
                 message)
               :checker checker
               :buffer (current-buffer)
               :filename buffer-file-name)))
          lsp-bridge-diagnostic-records)))
    (funcall callback 'finished errors)))

(defun my/lsp-bridge-flycheck-refresh ()
  (when (and (bound-and-true-p flycheck-mode)
             (memq flycheck-checker '(lsp-bridge
                                      lsp-bridge-python-mypy
                                      lsp-bridge-python-pylint-mypy)))
    (flycheck-buffer)))

(defun my/lsp-bridge-flycheck-setup ()
  "Set up Flycheck for common language."
  (setq-local flycheck-checker 'lsp-bridge)
  (flycheck-mode 1))

;;; Python toolchain selection
(defun my/python-set-formatter (formatters)
  "Set Python FORMATTERS for the current buffer with Apheleia."
  (require 'apheleia)
  (setq-local apheleia-mode-alist
              (cons `(python-ts-mode . ,formatters)
                    (assq-delete-all 'python-ts-mode apheleia-mode-alist))))

(defun my/python-restart-lsp-bridge ()
  "Restart lsp-bridge in the current Python buffer."
  (when (derived-mode-p 'python-ts-mode 'python-mode)
    (when (bound-and-true-p lsp-bridge-mode)
      (lsp-bridge-mode -1))
    (lsp-bridge-mode 1)

    (when (bound-and-true-p flycheck-mode)
      (flycheck-buffer))))

(defun my/python-use-new-stack ()
  "Use basedpyright + ruff + mypy in the current Python buffer."
  (interactive)
  (setq-local lsp-bridge-python-multi-lsp-server "basedpyright_ruff")
  (setq-local lsp-bridge-python-lsp-server "basedpyright")
  (my/python-set-formatter '(ruff-isort ruff))
  (setq-local flycheck-checker 'lsp-bridge-python-mypy)
  (my/python-restart-lsp-bridge)
  (message "Python stack: basedpyright + ruff + mypy"))

(defun my/python-use-old-stack ()
  "Use pyright + pylint + mypy + isort + black in the current Python buffer."
  (interactive)
  (setq-local lsp-bridge-python-multi-lsp-server nil)
  (setq-local lsp-bridge-python-lsp-server "basedpyright")
  (my/python-set-formatter '(isort black))
  (setq-local flycheck-checker 'lsp-bridge-python-pylint-mypy)
  (my/python-restart-lsp-bridge)
  (message "Python stack: basedpyright + pylint + mypy + isort + black"))

(add-to-list 'safe-local-eval-forms
             '(my/python-use-old-stack))

(add-to-list 'safe-local-eval-forms
             '(my/python-use-new-stack))

(defun my/python-flycheck-setup ()
  "Set up Flycheck for Python."
  (setq-local flycheck-checker 'lsp-bridge-python-mypy)
  (flycheck-mode 1))

(use-package flycheck
  :hook
  ((emacs-lisp-mode . flycheck-mode)
   (python-ts-mode . my/python-flycheck-setup)
   (rust-ts-mode . my/lsp-bridge-flycheck-setup)
   (c-ts-mode . my/lsp-bridge-flycheck-setup)
   (c++-ts-mode . my/lsp-bridge-flycheck-setup)
   (fsharp-ts-mode . my/lsp-bridge-flycheck-setup)
   (typescript-ts-mode . my/lsp-bridge-flycheck-setup)
   (tsx-ts-mode . my/lsp-bridge-flycheck-setup)
   (vue-ts-mode . my/lsp-bridge-flycheck-setup)
   (qml-ts-mode . my/lsp-bridge-flycheck-setup))
  :bind
  (("M-n" . flycheck-next-error)
   ("M-p" . flycheck-previous-error))
  :config
  (flycheck-define-generic-checker 'lsp-bridge
    "Flycheck frontend for lsp-bridge diagnostics."
    :start #'my/flycheck-lsp-bridge-start
    :modes '(rust-ts-mode
             c-ts-mode
             c++-ts-mode
             fsharp-ts-mode
             typescript-ts-mode
             tsx-ts-mode
             vue-ts-mode
             qml-ts-mode))

  (flycheck-define-generic-checker 'lsp-bridge-python-mypy
    "Flycheck frontend for lsp-bridge Python diagnostics, followed by mypy."
    :start #'my/flycheck-lsp-bridge-start
    :modes '(python-ts-mode))

  (flycheck-define-generic-checker 'lsp-bridge-python-pylint-mypy
    "Flycheck frontend for lsp-bridge Python diagnostics, followed by pylint and mypy."
    :start #'my/flycheck-lsp-bridge-start
    :modes '(python-ts-mode))

  (add-to-list 'flycheck-checkers 'lsp-bridge)
  (add-to-list 'flycheck-checkers 'lsp-bridge-python-mypy)
  (add-to-list 'flycheck-checkers 'lsp-bridge-python-pylint-mypy)

  ;; lsp-bridge-python-mypy -> python-mypy
  (flycheck-add-next-checker 'lsp-bridge-python-mypy
                             '(t . python-mypy))

  ;; lsp-bridge-python-pylint-mypy -> python-pylint -> python-mypy
  (flycheck-add-next-checker 'lsp-bridge-python-pylint-mypy
                             '(t . python-pylint))
  (flycheck-add-next-checker 'python-pylint
                             '(t . python-mypy)))

(require 'cl-lib)
(defun my/lsp-bridge-set-multiserver-for-extension (extension server)
  "Set lsp-bridge multiserver SERVER for single EXTENSION."
  (setq lsp-bridge-multi-lang-server-extension-list
        (cl-remove-if
         (lambda (entry)
           (member extension (car entry)))
         lsp-bridge-multi-lang-server-extension-list))
  (add-to-list 'lsp-bridge-multi-lang-server-extension-list
               (cons (list extension) server)))

(use-package lsp-bridge
  :straight '(lsp-bridge :type git :url git@github.com:manateelazycat/lsp-bridge.git
                         :files (:defaults "*.el" "*.py" "acm" "core" "langserver" "multiserver" "resources")
                         :build (:not compile))
  :hook
  ((python-ts-mode . lsp-bridge-mode)
   (rust-ts-mode . lsp-bridge-mode)
   (c-ts-mode . lsp-bridge-mode)
   (c++-ts-mode . lsp-bridge-mode)
   (fsharp-ts-mode . lsp-bridge-mode)
   (typescript-ts-mode . lsp-bridge-mode)
   (tsx-ts-mode . lsp-bridge-mode)
   (vue-ts-mode . lsp-bridge-mode)
   (qml-ts-mode . lsp-bridge-mode))
  :init
  (setq lsp-bridge-enable-diagnostics t
        lsp-bridge-diagnostic-enable-overlays nil
        lsp-bridge-diagnostic-fetch-idle t
        lsp-bridge-enable-semantic-tokens t
        lsp-bridge-enable-inlay-hint t
        lsp-bridge-enable-document-highlight t

        lsp-bridge-user-langserver-dir
        (expand-file-name "langserver/" user-emacs-directory)
        lsp-bridge-user-multiserver-dir
        (expand-file-name "multiserver/" user-emacs-directory)
        ;; Default Python stack: basedpyright
        lsp-bridge-python-multi-lsp-server "basedpyright_ruff"
        lsp-bridge-python-lsp-server "basedpyright"
        lsp-bridge-c-lsp-server "clangd")
  :config
  (add-hook 'lsp-bridge-diagnostic-update-hook
            #'my/lsp-bridge-flycheck-refresh)

  (add-to-list 'lsp-bridge-completion-in-string-file-types "tsx")
  (add-to-list 'lsp-bridge-completion-in-string-file-types "vue")

  ;; langserver defined here
  (add-to-list 'lsp-bridge-single-lang-server-mode-list
               '((fsharp-mode fsharp-ts-mode) . "fsautocomplete"))

  ;; multiserver defined here
  (my/lsp-bridge-set-multiserver-for-extension
   "tsx"
   "typescriptreact_eslint_tailwindcss")
  (my/lsp-bridge-set-multiserver-for-extension
   "vue"
   "volar_vtsls_tailwindcss")

  (with-eval-after-load 'evil
    (define-key evil-normal-state-map (kbd "SPC r n") #'lsp-bridge-rename)
    (define-key evil-normal-state-map (kbd "SPC r a") #'lsp-bridge-code-action)
    (define-key evil-normal-state-map (kbd "g d") #'lsp-bridge-find-def)
    (define-key evil-normal-state-map (kbd "g i") #'lsp-bridge-find-impl)
    (define-key evil-normal-state-map (kbd "g r") #'lsp-bridge-find-references)
    (define-key evil-normal-state-map (kbd "g b") #'lsp-bridge-find-def-return)
    (define-key evil-normal-state-map (kbd "K") #'lsp-bridge-popup-documentation)
    (define-key evil-normal-state-map (kbd "M-j") #'lsp-bridge-popup-documentation-scroll-up)
    (define-key evil-normal-state-map (kbd "M-k") #'lsp-bridge-popup-documentation-scroll-down)))

(with-eval-after-load 'acm
  (with-eval-after-load 'evil
    (evil-define-key 'insert acm-mode-map
      (kbd "C-j") #'acm-select-next
      (kbd "C-k") #'acm-select-prev
      (kbd "C-g") #'acm-hide
      (kbd "<tab>") #'acm-complete
      (kbd "TAB") #'acm-complete
      (kbd "<return>") #'acm-complete
      (kbd "RET") #'acm-complete
      (kbd "M-j") #'acm-doc-scroll-up
      (kbd "M-k") #'acm-doc-scroll-down)))

(use-package apheleia
  :commands apheleia-format-buffer
  :init
  (with-eval-after-load 'evil
    (define-key evil-normal-state-map (kbd "SPC f") #'apheleia-format-buffer))
  :config
  (setf (alist-get 'python-ts-mode apheleia-mode-alist)
        '(ruff-isort ruff))

  (setf (alist-get 'rust-ts-mode apheleia-mode-alist)
        'rustfmt)

  (dolist (mode '(c-ts-mode c++-ts-mode))
    (setf (alist-get mode apheleia-mode-alist) 'clang-format))

  (dolist (mode '(typescript-ts-mode tsx-ts-mode vue-ts-mode json-ts-mode yaml-ts-mode))
    (setf (alist-get mode apheleia-mode-alist) 'prettier))

  (setf (alist-get 'fantomas apheleia-formatters)
        '("dotnet" "fantomas" inplace))
  (setf (alist-get 'fsharp-ts-mode apheleia-mode-alist)
        'fantomas)

  (setf (alist-get 'qmlformat apheleia-formatters)
        '("qmlformat" filepath))
  (setf (alist-get 'qml-ts-mode apheleia-mode-alist)
        'qmlformat))

(provide 'init-ide)
;;; init-ide.el ends here
