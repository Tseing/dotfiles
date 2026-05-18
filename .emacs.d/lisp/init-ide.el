;;; init-ide.el --- Settings for lsp -*- lexical-binding: t -*-

;;; Commentary:
;;; Code:

(use-package magit
  :bind
  (("C-x g" . magit-status)))

(use-package diff-hl
  :hook
  ((prog-mode text-mode conf-mode) . diff-hl-mode)
  (dired-mode . diff-hl-dired-mode)
  :config
  (diff-hl-flydiff-mode 1)
  (diff-hl-margin-mode 1)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)

  (with-eval-after-load 'evil
    (define-key evil-normal-state-map (kbd "]c") #'diff-hl-next-hunk)
    (define-key evil-normal-state-map (kbd "[c") #'diff-hl-previous-hunk)
    (define-key evil-normal-state-map (kbd "SPC g h") #'diff-hl-diff-goto-hunk)))

(use-package treesit
  :straight nil
  :init
  (setq treesit-language-source-alist
        '((python "https://github.com/tree-sitter/tree-sitter-python" "v0.23.2")
          (rust "https://github.com/tree-sitter/tree-sitter-rust" "v0.23.2")
          (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.2" "typescript/src")
          (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.2" "tsx/src"))
        treesit-font-lock-level 4))

(use-package python
  :straight nil
  :init
  (setq python-indent-offset 4)
  :mode ("\\.py\\'" . python-ts-mode))

(use-package rust-ts-mode
  :straight nil
  :init
  (setq rust-ts-mode-indent-offset 4)
  :mode ("\\.rs\\'" . rust-ts-mode))

(use-package typescript-ts-mode
  :straight nil
  :mode
  (("\\.ts\\'" . typescript-ts-mode)
   ("\\.tsx\\'" . tsx-ts-mode)))

(use-package vue-mode
  :mode "\\.vue\\'")

(use-package markdown-mode
  :mode "\\.md\\'")

(use-package qml-mode
  :mode "\\.qml\\'")

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
   (typescript-ts-mode . my/lsp-bridge-flycheck-setup)
   (tsx-ts-mode . my/lsp-bridge-flycheck-setup)
   (vue-mode . my/lsp-bridge-flycheck-setup)
   (qml-mode . my/lsp-bridge-flycheck-setup))
  :bind
  (("M-n" . flycheck-next-error)
   ("M-p" . flycheck-previous-error))
  :config
  (flycheck-define-generic-checker 'lsp-bridge
    "Flycheck frontend for lsp-bridge diagnostics."
    :start #'my/flycheck-lsp-bridge-start
    :modes '(rust-ts-mode
             typescript-ts-mode
             tsx-ts-mode
             vue-mode
             qml-mode))

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
   (typescript-ts-mode . lsp-bridge-mode)
   (tsx-ts-mode . lsp-bridge-mode)
   (vue-mode . lsp-bridge-mode)
   (qml-mode . lsp-bridge-mode))
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
        lsp-bridge-python-lsp-server "basedpyright")
  :config
  (add-hook 'lsp-bridge-diagnostic-update-hook
            #'my/lsp-bridge-flycheck-refresh)

  (add-to-list 'lsp-bridge-completion-in-string-file-types "tsx")
  (my/lsp-bridge-set-multiserver-for-extension
    "tsx"
    "typescriptreact_eslint_tailwindcss")

  (with-eval-after-load 'evil
    (define-key evil-normal-state-map (kbd "SPC r n") #'lsp-bridge-rename)
    (define-key evil-normal-state-map (kbd "SPC r a") #'lsp-bridge-code-action)
    (define-key evil-normal-state-map (kbd "g d") #'lsp-bridge-find-def)
    (define-key evil-normal-state-map (kbd "g i") #'lsp-bridge-find-impl)
    (define-key evil-normal-state-map (kbd "g r") #'lsp-bridge-find-references)
    (define-key evil-normal-state-map (kbd "g b") #'lsp-bridge-find-def-return)
    (define-key evil-normal-state-map (kbd "K") #'lsp-bridge-popup-documentation)))

(with-eval-after-load 'acm
  (define-key acm-mode-map (kbd "<tab>") #'acm-complete)
  (define-key acm-mode-map (kbd "TAB") #'acm-complete)
  (define-key acm-mode-map (kbd "<return>") #'acm-complete)
  (define-key acm-mode-map (kbd "RET") #'acm-complete)

  (define-key acm-mode-map (kbd "C-g") #'acm-hide)

  (define-key acm-mode-map (kbd "C-j") #'acm-select-next)
  (define-key acm-mode-map (kbd "C-k") #'acm-select-prev))


(use-package apheleia
  :config
  (setf (alist-get 'python-ts-mode apheleia-mode-alist)
        '(ruff-isort ruff))

  (setf (alist-get 'rust-ts-mode apheleia-mode-alist)
        'rustfmt)

  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist)
        'prettier)

  (setf (alist-get 'tsx-ts-mode apheleia-mode-alist)
        'prettier)

  (setf (alist-get 'vue-mode apheleia-mode-alist)
        'prettier)

  (setf (alist-get 'qml-mode apheleia-mode-alist)
        'qmlformat)

  (with-eval-after-load 'evil
    (define-key evil-normal-state-map (kbd "SPC f") #'apheleia-format-buffer)))

(provide 'init-ide)
;;; init-ide.el ends here
