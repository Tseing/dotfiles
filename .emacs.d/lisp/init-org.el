;;; init-org --- settings for org-mode and pdf -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:
(defvar my/org-workspace 'personal)

(defvar my/org-agenda-personal-files
  '("~/Documents/org/agenda/inbox.org"
    "~/Documents/org/agenda/todo.org"
    "~/Documents/org/agenda/tasks.org"))

(defvar my/org-agenda-work-files
  '("~/Documents/org/work/inbox.org"
    "~/Documents/org/work/todo.org"
    "~/Documents/org/work/tasks.org"))

(defvar my/org-refile-personal-targets
  '(("~/Documents/org/agenda/todo.org" :maxlevel . 2)
    ("~/Documents/org/agenda/tasks.org" :maxlevel . 2)))

(defvar my/org-refile-work-targets
  '(("~/Documents/org/work/todo.org" :maxlevel . 2)
    ("~/Documents/org/work/tasks.org" :maxlevel . 2)))

(defun my/org-agenda-personal ()
  "Switch Org workspace to personal."
  (interactive)
  (setq my/org-workspace 'personal)
  (setq org-agenda-files my/org-agenda-personal-files)
  (setq org-refile-targets my/org-refile-personal-targets)
  (message "Org workspace: personal"))

(defun my/org-agenda-work ()
  "Switch Org workspace to work."
  (interactive)
  (setq my/org-workspace 'work)
  (setq org-agenda-files my/org-agenda-work-files)
  (setq org-refile-targets my/org-refile-work-targets)
  (message "Org workspace: work"))


(with-eval-after-load 'evil
  (evil-define-key 'normal global-map
    ;; Capture
    (kbd "SPC c") #'org-capture

    ;; Agenda
    (kbd "SPC a p") #'my/org-agenda-personal
    (kbd "SPC a w") #'my/org-agenda-work
    (kbd "SPC a a") #'org-agenda-list
    (kbd "SPC a t") #'org-todo-list))

(use-package org
  :straight nil
  :commands (org-capture org-agenda org-agenda-list org-todo-list)
  :init
  (setq org-directory "~/Documents/org")
  (setq org-agenda-files my/org-agenda-personal-files)
  (setq org-refile-targets my/org-refile-personal-targets)
  :config
  (setq org-startup-indented t)
  (setq org-return-follows-link t)

  (setq org-todo-keywords
        '((sequence "TODO(t)" "SCH(s)" "NEXT(n)" "WAIT(w)" "|" "DONE(d)" "CANCELED(c)")))

  (setq org-capture-templates
        '(("p" "Personal inbox" entry
           (file "~/Documents/org/agenda/inbox.org")
           "* TODO %?\n  %U\n  %a")

          ("w" "Work inbox" entry
           (file "~/Documents/org/work/inbox.org")
           "* TODO %?\n  %U\n  %a")))

  (setq org-archive-location "archive/%s_archive::")

  (with-eval-after-load 'evil
    (evil-define-key '(normal motion) org-mode-map
      (kbd "RET") #'org-return))

  (with-eval-after-load 'evil
    (evil-define-key 'normal org-mode-map
      ;; Link
      (kbd "SPC l i") #'org-insert-link
      (kbd "SPC l o") #'org-open-at-point

      ;; Toggle
      (kbd "SPC t l") #'org-toggle-link-display
      (kbd "SPC t i") #'org-toggle-inline-images
      (kbd "SPC t t") #'org-todo

      ;; Move/promote/demote headline.
      (kbd "M-h") #'org-metaleft
      (kbd "M-j") #'org-metadown
      (kbd "M-k") #'org-metaup
      (kbd "M-l") #'org-metaright

      ;; Move/promote/demote subtree.
      (kbd "M-H") #'org-shiftmetaleft
      (kbd "M-J") #'org-shiftmetadown
      (kbd "M-K") #'org-shiftmetaup
      (kbd "M-L") #'org-shiftmetaright

      ;; Set state/priority.
      (kbd "C-M-h") #'org-shiftleft
      (kbd "C-M-j") #'org-shiftdown
      (kbd "C-M-k") #'org-shiftup
      (kbd "C-M-l") #'org-shiftright))

  (with-eval-after-load 'org-agenda
    (evil-define-key 'normal org-agenda-mode-map
      (kbd "d") #'org-agenda-day-view
      (kbd "w") #'org-agenda-week-view
      (kbd "m") #'org-agenda-month-view
      (kbd ".") #'org-agenda-goto-today
      (kbd "J") #'org-agenda-later
      (kbd "K") #'org-agenda-earlier
      (kbd "q") #'org-agenda-quit)))

(use-package org-download
  :after org
  :hook (org-mode . org-download-enable)
  :custom
  (org-download-image-dir "~/Documents/org/files/images")
  (org-download-timestamp "%Y%m%d-%H%M%S_")
  (org-download-heading-lvl nil)
  :config
  (with-eval-after-load 'evil
    (evil-define-key 'normal org-mode-map
      (kbd "P") #'org-download-clipboard)))

(use-package zathura
  :straight nil
  :defer 0
  :load-path "~/Projects/zathura.el"
  :config
  (setq zathura-outline-numbered nil)
  (zathura-mode 1)

  (with-eval-after-load 'evil
    (evil-define-key 'normal zathura-outline-mode-map
      (kbd "q") #'bury-buffer
      (kbd "<return>") #'zathura-outline-view
      (kbd "s-<return>") #'zathura-outline-jump))

  (evil-define-key 'normal org-mode-map
    (kbd "s-<return>") #'zathura-jump-link-at-point))
(provide 'init-org)
;;; init-org.el ends here
