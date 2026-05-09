;;; init-ide.el ---  Settings for lsp

;;; Commentary:
;;; Code:

(use-package treesit
  :ensure nil
  :config
  (setq treesit-language-source-alist
        '((python "https://github.com/tree-sitter/tree-sitter-python" "v0.23.2")
          (rust "https://github.com/tree-sitter/tree-sitter-rust" "v0.23.2"))))

(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-ts-mode))

(use-package rust-ts-mode
  :ensure nil
  :mode ("\\.rs\\'" . rust-ts-mode))

(use-package markdown-mode
  :ensure nil
  :mode "\\.md\\'")

(use-package yasnippet
  :config
  (yas-global-mode 1))
(add-to-list 'load-path
	     (expand-file-name "site-lisp/lsp-bridge" user-emacs-directory))

(require 'lsp-bridge)

;;; Python
(setq lsp-bridge-python-lsp-server "basedpyright")
(setq lsp-bridge-enable-inlay-hint t)

(global-lsp-bridge-mode)

(with-eval-after-load 'lsp-bridge
  (add-hook 'python-ts-mode-hook #'lsp-bridge-semantic-tokens-mode)
  (add-hook 'rust-ts-mode-hook #'lsp-bridge-semantic-tokens-mode))

(with-eval-after-load 'lsp-bridge
  (global-set-key (kbd "M-n") #'lsp-bridge-diagnostic-jump-next)
  (global-set-key (kbd "M-p") #'lsp-bridge-diagnostic-jump-prev)
  (global-set-key (kbd "C-c l d") #'lsp-bridge-diagnostic-list)
  (global-set-key (kbd "M-]") #'lsp-bridge-find-def)
  (global-set-key (kbd "M-[") #'lsp-bridge-find-def-return))

(defun my/python-flycheck-setup ()
  "Use pylint & mypy."
  (setq-local flycheck-checker 'python-pylint)
  (flycheck-mode 1))


(use-package flycheck
  :hook
  ((emacs-lisp-mode . flycheck-mode)
   (python-mode . my/python-flycheck-setup)
   (python-ts-mode . my/python-flycheck-setup))
  :config
  (flycheck-add-next-checker 'python-pylint 'python-mypy))

(provide 'init-ide)
;;; init-ide.el ends here
