;;; init-org.el --- Config for org-mode and PDF -*- lexical-binding: t -*-

;;; Commentary:
;;; Code:
(use-package eaf
  :defer 2
  :straight (eaf :type git :host github
                 :repo "emacs-eaf/emacs-application-framework"
                 :files ("*.el" "*.py" "core" "app" "*.json")
                 :includes (eaf-pdf-viewer))
  :init
  (setq eaf-python-command
        (expand-file-name "~/.emacs.d/straight/repos/emacs-application-framework/.venv/bin/python3"))
  :config
  (setq eaf-enable-debug t))

(use-package eaf-pdf-viewer
  :defer 2
  :after eaf
  :straight nil)

(use-package org
  :straight nil
  :config
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
      (kbd "C-M-l") #'org-shiftright)))

(use-package org-pdftools
  :hook (org-load . org-pdftools-setup-link))

(use-package org-noter
  :after (:any org pdf-view)
  :custom (org-noter-always-create-frame nil))

(use-package org-noter-pdftools
  :after org-noter)

(provide 'init-org)
;;; init-org.el ends here
