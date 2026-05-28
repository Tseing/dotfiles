;;; init-org.el --- Config for org-mode and PDF -*- lexical-binding: t -*-

;;; Commentary:
;;; Code:
(defun my/eaf-open-pdf-file ()
  "Open current PDF file with EAF PDF Viewer."
  (interactive)
  (when buffer-file-name
    (let ((file buffer-file-name))
      (kill-buffer)
      (require 'eaf)
      (require 'eaf-pdf-viewer)
      (eaf-open file "pdf-viewer"))))

(add-to-list 'auto-mode-alist
             '("\\.pdf\\'" . my/eaf-open-pdf-file))

(use-package eaf
  :commands (eaf-open)
  :straight
  (eaf :type git :host github
       :repo "emacs-eaf/emacs-application-framework"
       :files ("*.el" "*.py" "core" "app" "extension" "*.json")
       :includes (eaf-pdf-viewer eaf-org eaf-interleave))
  :init
  (setq eaf-python-command
        (expand-file-name
         "straight/repos/emacs-application-framework/.venv/bin/python"
         straight-base-dir))
  :config
  (setq eaf-enable-debug t))

(use-package eaf-pdf-viewer
  :defer 0
  :after eaf
  :straight nil
  :config
  (eaf-bind-key my/eaf-pdf-narrow-consult "/" eaf-pdf-viewer-keybinding))

(defun my/eaf-pdf-narrow-consult (&optional obj)
  (interactive)
  (require 'consult)
  (unless obj (setq obj "line"))
  (let* ((eaf-buffer-id eaf--buffer-id)
         (current-page-file-name
          (eaf-pdf-narrow--begin eaf-buffer-id))
         (current-page (car (split-string current-page-file-name)))
         (cache-file-name
          (substring current-page-file-name
                     (1+ (length current-page))))
         candidates initial-index)
    (if (not (file-exists-p cache-file-name))
        (progn
          (message "Building %s ..." cache-file-name)
          (eaf-pdf-rebuild-full-text-cache))
      (setq initial-index (format "%s:" current-page))
      (cond
       ((string= obj "line")
        (setq candidates
              (eaf-pdf-narrow--read-cache-file cache-file-name)))
       ((string= obj "toc")
        (let ((toc-index
               (eaf-call-sync "execute_function"
                              eaf-buffer-id
                              "get_toc_for_search")))
          (setq candidates (car toc-index))
          (setq initial-index (cadr toc-index)))))
      (unwind-protect
          (let ((selection
                 (consult--read
                  candidates
                  :prompt "Narrow Search: "
                  :require-match t
                  :lookup #'consult--lookup-member
                  :state
                  (lambda (action cand)
                    (when cand
                      (let ((index (cl-position cand candidates
                                                :test #'equal)))
                        (eaf-pdf-narrow--update
                         eaf-buffer-id
                         ""
                         cand
                         index
                         candidates)))))))
            (when selection
              (eaf-pdf-narrow--done eaf-buffer-id)))
        (when quit-flag
          (eaf-pdf-narrow--quit eaf-buffer-id))))))

(use-package eaf-interleave
  :defer 0
  :after eaf
  :straight nil
  :config
  (setq eaf-interleave-org-notes-dir-list
        '("~/Documents/org/reading/" ".")))

(use-package eaf-org
  :defer 0
  :after eaf
  :straight nil
  :config
  (setq eaf-org-override-pdf-links-open t
        eaf-org-override-pdf-links-store t))

(use-package org
  :straight nil
  :config
  (setq org-return-follows-link t)

  (with-eval-after-load 'evil
    (evil-define-key '(normal) org-mode-map
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
      (kbd "C-M-l") #'org-shiftright)))

(provide 'init-org)
;;; init-org.el ends here
