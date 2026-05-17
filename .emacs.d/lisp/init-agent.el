;;; init-agent.el --- AI / Agent tools -*- lexical-binding: t; -*-

;;; Commentary:
;; Optional AI / agent integrations.

;;; Code:

(defconst my/codex-ide-repo-dir
  (expand-file-name "straight/repos/codex-ide" user-emacs-directory))

(defconst my/transient-repo-dir
  (expand-file-name "straight/repos/transient" user-emacs-directory))

(defun my/install-codex-ide ()
  "Install codex-ide and its required transient package with straight.el."
  (interactive)
  (straight-use-package 'transient)
  (straight-use-package
   '(codex-ide :type git :host github :repo "dgillis/emacs-codex-ide"))
  (message "codex-ide installed. You can now run M-x codex-ide-menu."))

(when (and (file-directory-p my/transient-repo-dir)
           (file-directory-p my/codex-ide-repo-dir))
  (straight-use-package 'transient)
  (straight-use-package
   '(codex-ide :type git :host github :repo "dgillis/emacs-codex-ide")))

(provide 'init-agent)
;;; init-agent.el ends here
