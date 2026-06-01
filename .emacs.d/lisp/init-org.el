;;; init-org --- settings for org-mode and pdf -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:
(use-package org
  :straight nil
  :config
  (setq org-return-follows-link t)

  (with-eval-after-load 'evil
    (evil-define-key 'normal org-mode-map
      (kbd "SPC l i") #'org-insert-link
      (kbd "SPC l o") #'org-open-at-point))

  (with-eval-after-load 'evil
    (evil-define-key '(normal motion) org-mode-map
      (kbd "RET") #'org-return))

  (with-eval-after-load 'evil
    (evil-define-key 'normal org-mode-map
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
      (kbd "C-M-l") #'org-shiftright

      ;; Toggle link / image
      (kbd "SPC t l") #'org-toggle-link-display
      (kbd "SPC t i") #'org-toggle-inline-images)))

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
      (kbd "<return>") #'zathura-outline-view
      (kbd "s-<return>") #'zathura-outline-jump))

  (evil-define-key 'normal org-mode-map
    (kbd "s-<return>") #'zathura-jump-link-at-point))

(provide 'init-org)
;;; init-org.el ends here
