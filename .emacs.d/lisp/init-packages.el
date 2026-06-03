;;; init-packages --- settings for packages

;;; Commentary:
;;; Code:
(use-package project
  :straight nil
  :config
  (setq project-switch-commands
        '((project-dired "Dired" ?d)
          (project-find-file "Find file" ?f)
          (project-find-regexp "Find regexp" ?g)
          (project-eshell "Eshell" ?e)))

  (with-eval-after-load 'evil
    (define-key evil-normal-state-map (kbd "SPC p p") #'project-switch-project)
    (define-key evil-normal-state-map (kbd "SPC p f") #'project-find-file)
    (define-key evil-normal-state-map (kbd "SPC p d") #'project-dired)
    (define-key evil-normal-state-map (kbd "SPC p b") #'project-switch-to-buffer)
    (define-key evil-normal-state-map (kbd "SPC p k") #'project-kill-buffers)))

(use-package magit
  :bind
  (("C-x g" . magit-status))
  :config
  (magit-auto-revert-mode 1))

(use-package magit-todos
  :after magit
  :config
  (magit-todos-mode 1))

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :config
  (setq hl-todo-keyword-faces
        '(("TODO"  . (:foreground "#FFFFFF" :background "#FFB000" :weight bold))
          ("FIXME" . (:foreground "#FFFFFF" :background "#FF5C8A" :weight bold))
          ("DEBUG" . (:foreground "#FFFFFF" :background "#7C5CFF" :weight bold)))))

(use-package diff-hl
  :hook
  ((prog-mode text-mode conf-mode) . diff-hl-mode)
  (dired-mode . diff-hl-dired-mode)
  :config
  (diff-hl-flydiff-mode 1)
  (diff-hl-margin-mode 1)
  (add-hook 'magit-pre-refresh-hook #'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)

  (with-eval-after-load 'evil
    (define-key evil-normal-state-map (kbd "]c") #'diff-hl-next-hunk)
    (define-key evil-normal-state-map (kbd "[c") #'diff-hl-previous-hunk)
    (define-key evil-normal-state-map (kbd "SPC g h") #'diff-hl-diff-goto-hunk)))

(use-package benchmark-init
  :init
  (benchmark-init/activate)
  :hook
  (after-init . benchmark-init/deactivate))
(use-package crux
  :bind
  ("C-k" . crux-smart-kill-line))

(use-package hungry-delete
  :bind
  (("C-c DEL" . hungry-delete-backward)
   ("C-c d" . hungry-delete-forward)))

(use-package drag-stuff
  :bind
  (("<M-up>" . drag-stuff-up)
   ("<M-down>" . drag-stuff-down)))

(use-package ibuffer
  :straight nil
  :bind
  ("C-x C-b" . ibuffer))

(use-package autorevert
  :straight nil
  :config
  (setq auto-revert-verbose nil
        global-auto-revert-non-file-buffers t
        auto-revert-interval 1)
  (global-auto-revert-mode 1))
;; (use-package ivy
;;   :demand t
;;   :config
;;   (ivy-mode 1)
;;   (setq ivy-use-virtual-buffers t
;; 	ivy-initial-inputs-alist nil
;; 	ivy-count-format "%d/%d "
;; 	enable-recursive-minibuffers t
;; 	ivy-re-builders-alist '((t . ivy--regex-ignore-order))))

;; (use-package counsel
;;   :after ivy
;;   :bind
;;   (("M-x" . counsel-M-x)
;;    ("C-x C-f" . counsel-find-file)
;;    ("C-c f" . counsel-recentf)
;;    ("C-c g" . counsel-git)))

;; (use-package swiper
;;   :after ivy
;;   :bind
;;   (("C-s" . swiper)
;;    ("C-r" . swiper-isearch-backward))
;;   :config
;;   (setq swiper-action-recenter t
;; 	swiper-include-line-number-in-search t))

(use-package recentf
  :straight nil
  :init
  (recentf-mode 1)
  :custom
  (recentf-max-saved-items 200))

(use-package vertico
  :init
  (vertico-mode 1)

  :config
  (setq vertico-count 15
        vertico-resize t
        vertico-cycle t))

(use-package savehist
  :init
  (savehist-mode 1))

(use-package marginalia
  :after vertico
  :init
  (marginalia-mode 1))

(use-package orderless
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides
        '((file (styles partial-completion)))))

(use-package consult
  :defer 2
  :bind
  (("C-x b" . consult-buffer)
   ("M-g i" . consult-imenu))

  :config
  (setq enable-recursive-minibuffers t)
  (setq consult-line-numbers-widen t)

  (with-eval-after-load 'evil
    (define-key evil-normal-state-map (kbd "SPC p s") #'consult-ripgrep)))

(use-package company
  :hook
  ((emacs-lisp-mode . company-mode)
   (lisp-interaction-mode . company-mode)
   (sh-mode . company-mode)
   (conf-mode . company-mode)
   (text-mode . company-mode)
   (org-mode . company-mode)
   (markdown-mode . company-mode))
  :config
  (setq company-dabbrev-code-everywhere t
        company-dabbrev-code-modes t
        company-dabbrev-code-other-buffers 'all
        company-dabbrev-downcase nil
        company-dabbrev-ignore-case t
        company-dabbrev-other-buffers 'all
        company-require-match nil
        company-minimum-prefix-length 2
        company-show-numbers t
        company-tooltip-limit 20
        company-idle-delay 0.1
        company-echo-delay 0
        company-tooltip-offset-display 'scrollbar
        company-begin-commands '(self-insert-command))
  (push '(company-semantic :with company-yasnippet) company-backends))

(use-package jinx
  :defer 2
  :hook (emacs-startup . global-jinx-mode)
  :config
  (setf (alist-get 'prog-mode jinx-include-faces)
        '(font-lock-comment-face
          font-lock-doc-face
          font-lock-string-face
          font-lock-function-name-face
          font-lock-variable-name-face
          font-lock-type-face))
  ;; exclude Chinese
  (add-to-list 'jinx-exclude-regexps '(t "\\cc"))

  (with-eval-after-load 'evil
    (define-key evil-normal-state-map (kbd "]s") #'jinx-next)
    (define-key evil-normal-state-map (kbd "[s") #'jinx-previous)
    (define-key evil-normal-state-map (kbd "z=") #'jinx-correct)
    ))

(use-package paredit
  :hook ((prog-mode inferior-emacs-lisp-mode) . paredit-mode)
  :config
  (defconst my/lisp-like-modes
    '(emacs-lisp-mode lisp-mode lisp-interaction-mode
                      scheme-mode clojure-mode ielm-mode inferior-emacs-lisp-mode))

  (defun my/lisp-like-mode-p ()
    (apply #'derived-mode-p my/lisp-like-modes))

  (defun my/paredit-space-for-delimiter-p (_endp _delimiter)
    (my/lisp-like-mode-p))

  (setq paredit-space-for-delimiter-predicates
        '(my/paredit-space-for-delimiter-p))
  (defun my/paredit-keys-for-non-lisp ()
    (unless (my/lisp-like-mode-p)
      (define-key paredit-mode-map (kbd "RET") nil)
      (define-key paredit-mode-map (kbd "DEL") nil)
      (define-key paredit-mode-map (kbd "C-j") nil)))

  (add-hook 'paredit-mode-hook #'my/paredit-keys-for-non-lisp))

(use-package envrc
  :hook (after-init . envrc-global-mode))

(use-package which-key
  :demand t
  :config (which-key-mode))

(use-package restart-emacs)

(provide 'init-packages)

;;; init-packages.el ends here
