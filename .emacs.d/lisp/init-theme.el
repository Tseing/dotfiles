;;; init-theme --- Settings for theme -*- lexical-binding: t -*-

;;; Commentary:
;;; Code:


(use-package doom-themes
  :demand t
  :init
  (load-theme 'doom-one t)
  :config
  (doom-themes-org-config))

(use-package nerd-icons
  :custom
  (nerd-icons-font-family "FiraCode Nerd Font"))

(use-package doom-modeline
  :init
  (doom-modeline-mode 1)
  :config
  (set-face-attribute 'mode-line nil
                      :family "FiraCode Nerd Font"
                      :height 100)
  (set-face-attribute 'mode-line-active nil
                      :family "FiraCode Nerd Font"
                      :height 100)
  (set-face-attribute 'mode-line-inactive nil
                      :family "FiraCode Nerd Font"
                      :height 100))

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

(provide 'init-theme)

;;; init-theme.el ends here
