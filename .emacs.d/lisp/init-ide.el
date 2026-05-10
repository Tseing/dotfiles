;;; init-ide.el ---  Settings for lsp

;;; Commentary:
;;; Code:

(use-package treesit
  :ensure nil
  :config
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

(use-package lsp-bridge
  :ensure nil
  :hook
  ((python-ts-mode . lsp-bridge-mode)
   (rust-ts-mode . lsp-bridge-mode))
  :bind
  (("M-]" . lsp-bridge-find-def)
   ("M-[" . lsp-bridge-find-def-return))
  :init
  (setq lsp-bridge-enable-semantic-tokens t
        lsp-bridge-enable-inlay-hint t
        lsp-bridge-enable-document-highlight t
        lsp-bridge-enable-diagnostics t
        lsp-bridge-python-lsp-server "basedpyright")
  :config
  (add-hook 'python-ts-mode-hook #'lsp-bridge-semantic-tokens-mode))



(with-eval-after-load 'acm
  ;; Keep TAB for indentation; use C-<tab> to accept completion candidate.
  (define-key acm-mode-map (kbd "<tab>") nil)
  (define-key acm-mode-map (kbd "TAB") nil)
  (define-key acm-mode-map (kbd "C-<tab>") #'acm-complete))

(defun my/python-flycheck-setup ()
  "Use pylint & mypy."
  (setq-local flycheck-checker 'python-pylint)
  (flycheck-mode 1))


(use-package flycheck
  :hook
  ((emacs-lisp-mode . flycheck-mode)
   (python-mode . my/python-flycheck-setup)
   (python-ts-mode . my/python-flycheck-setup))
  :bind
  (("M-n" . flycheck-next-error)
   ("M-p" . flycheck-previous-error))
  :config
  (flycheck-add-next-checker 'python-pylint 'python-mypy))

(provide 'init-ide)
;;; init-ide.el ends here
