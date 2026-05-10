;;; init-packages --- settings for packages

;;; Commentary:
;;; Code:
(use-package project
  :ensure nil)

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
  :ensure nil
  :init
  (recentf-mode 1)
  :custom
  (recentf-max-saved-items 200))

(use-package vertico
  :ensure t
  :init
  (vertico-mode 1)

  :config
  (setq vertico-count 15
        vertico-resize t
        vertico-cycle t))

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1))

(use-package marginalia
  :ensure t
  :after vertico
  :init
  (marginalia-mode 1))

(use-package orderless
  :ensure t
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides
        '((file (styles partial-completion)))))

(use-package consult
  :ensure t
  :bind
  (("M-x" . execute-extended-command)
   ("C-x C-f" . find-file)
   ("C-c f" . consult-recent-file)
   ("C-c g" . consult-git-grep)
   ("C-s" . consult-line)
   ("C-r" . consult-line)
   ("C-x b" . consult-buffer)
   ("M-g g" . consult-goto-line)
   ("M-g i" . consult-imenu)
   ("C-c s r" . consult-ripgrep)
   ("C-c s f" . consult-find))

  :config
  (setq enable-recursive-minibuffers t)
  (setq consult-line-numbers-widen t))


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

(use-package which-key
  :defer nil
  :config (which-key-mode))

(use-package restart-emacs)

(provide 'init-packages)

;;; init-packages.el ends here
