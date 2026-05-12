;;; init-ide.el --- Settings for lsp -*- lexical-binding: t -*-

;;; Commentary:
;;; Code:

(use-package treesit
  :ensure nil
  :init
  (setq treesit-language-source-alist
        '((python "https://github.com/tree-sitter/tree-sitter-python" "v0.23.2")
          (rust "https://github.com/tree-sitter/tree-sitter-rust" "v0.23.2"))
        treesit-font-lock-level 4))

(use-package python
  :ensure nil
  :init
  (setq python-indent-offset 4)
  :mode ("\\.py\\'" . python-ts-mode))

(use-package rust-ts-mode
  :ensure nil
  :init
  (setq rust-ts-mode-indent-offset 4)
  :mode ("\\.rs\\'" . rust-ts-mode))

(use-package markdown-mode
  :mode "\\.md\\'")

(use-package yasnippet
  :config
  (yas-global-mode 1))

(add-to-list 'load-path
             (expand-file-name "site-lisp/lsp-bridge" user-emacs-directory))


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
                                      lsp-bridge-python)))
    (flycheck-buffer)))


(defun my/lsp-bridge-flycheck-setup ()
  (setq-local flycheck-checker 'lsp-bridge)
  (flycheck-mode 1))

(defun my/python-flycheck-setup ()
  (setq-local flycheck-checker 'lsp-bridge-python)
  (flycheck-mode 1))


(use-package flycheck
  :hook
  ((emacs-lisp-mode . flycheck-mode)
   (python-ts-mode . my/python-flycheck-setup)
   (rust-ts-mode . my/lsp-bridge-flycheck-setup))
  :bind
  (("M-n" . flycheck-next-error)
   ("M-p" . flycheck-previous-error))
  :config
  (flycheck-define-generic-checker 'lsp-bridge
    "Flycheck frontend for lsp-bridge diagnostics."
    :start #'my/flycheck-lsp-bridge-start
    :modes '(rust-ts-mode))

  (flycheck-define-generic-checker 'lsp-bridge-python
    "Flycheck frontend for lsp-bridge Python diagnostics."
    :start #'my/flycheck-lsp-bridge-start
    :modes '(python-ts-mode))

  (add-to-list 'flycheck-checkers 'lsp-bridge)
  (add-to-list 'flycheck-checkers 'lsp-bridge-python)

  (flycheck-add-next-checker 'lsp-bridge-python 'python-mypy))

(use-package lsp-bridge
  :ensure nil
  :hook
  ((python-ts-mode . lsp-bridge-mode)
   (rust-ts-mode . lsp-bridge-mode))
  :bind
  (("M-]" . lsp-bridge-find-def)
   ("M-[" . lsp-bridge-find-def-return))
  :init
  (setq lsp-bridge-enable-diagnostics t
        lsp-bridge-diagnostic-enable-overlays nil
        lsp-bridge-enable-semantic-tokens t
        lsp-bridge-enable-inlay-hint t
        lsp-bridge-enable-document-highlight t
        lsp-bridge-python-multi-lsp-server "basedpyright_ruff")
  :config
  (add-hook 'lsp-bridge-diagnostic-update-hook
            #'my/lsp-bridge-flycheck-refresh)

  (add-hook 'python-ts-mode-hook #'lsp-bridge-semantic-tokens-mode)
  (add-hook 'rust-ts-mode-hook #'lsp-bridge-semantic-tokens-mode))


(with-eval-after-load 'acm
  ;; Keep TAB for indentation; use C-<tab> to accept completion candidate.
  (define-key acm-mode-map (kbd "<tab>") nil)
  (define-key acm-mode-map (kbd "TAB") nil)
  (define-key acm-mode-map (kbd "C-<tab>") #'acm-complete))


(provide 'init-ide)
;;; init-ide.el ends here
