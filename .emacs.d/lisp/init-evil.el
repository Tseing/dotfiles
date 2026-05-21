;;; init-evil.el --- Evil mode -*- lexical-binding: t -*-

;;; Commentary:
;;; Code:

(defun my/comment-or-uncomment ()
  "Comment or uncomment current line or selected region."
  (interactive)
  (if (use-region-p)
      (comment-or-uncomment-region (region-beginning) (region-end))
    (comment-line 1)))

(defun my/evil-insert-newline-above ()
  "Insert newline above without entering insert state."
  (interactive)
  (evil-insert-newline-above)
  (forward-line))

(defun my/evil-insert-newline-below ()
  "Insert newline below without entering insert state."
  (interactive)
  (evil-insert-newline-below)
  (forward-line -1))

(use-package evil
  :demand t
  :init
  (setq evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-integration t
        ;; C-i is usually the same key event as TAB.
        evil-want-C-i-jump nil
        evil-undo-system 'undo-redo)

  :config
  (evil-mode 1)

  ;; Comment / uncomment.
  (define-key evil-normal-state-map (kbd ",/") #'my/comment-or-uncomment)
  (define-key evil-visual-state-map (kbd ",/") #'my/comment-or-uncomment)

  ;; Insert blank lines without entering insert state.
  (define-key evil-normal-state-map (kbd "[ SPC") #'my/evil-insert-newline-above)
  (define-key evil-normal-state-map (kbd "] SPC") #'my/evil-insert-newline-below)

  ;; Let modes like org-mode handle RET when needed.
  (with-eval-after-load 'evil-maps
    (define-key evil-motion-state-map (kbd "RET") nil)
    (define-key evil-insert-state-map (kbd "C-k") nil)))

(use-package evil-collection
  :after evil
  :demand t
  :config
  ;; Do not let evil-collection take over lispy.
  ;; Keep dashboard managed by evil-collection.
  (setq evil-collection-mode-list
        (remove 'lispy evil-collection-mode-list))

  (evil-collection-init)

  ;; Initial states for special modes.
  (evil-set-initial-state 'org-agenda-mode 'normal)
  (evil-set-initial-state 'Custom-mode 'emacs)
  (evil-set-initial-state 'eshell-mode 'emacs)
  (evil-set-initial-state 'makey-key-mode 'motion))

(use-package evil-surround
  :after evil
  :defer 1
  :config
  (global-evil-surround-mode 1))

(provide 'init-evil)
;;; init-evil.el ends here
