;;; init-agent.el --- AI / Agent tools -*- lexical-binding: t -*-

;;; Commentary:
;; Optional AI / agent integrations.

;;; Code:

(defun my/codex-ide-ensure ()
  "Install and load codex-ide on demand."
  (straight-use-package 'transient)
  (straight-use-package
   '(codex-ide :type git :host github :repo "dgillis/emacs-codex-ide"))

  ;; Load the real package and menu implementation.
  (require 'codex-ide)
  (require 'codex-ide-transient))

;;;###autoload
(defun codex-ide-menu ()
  "Install/load codex-ide on demand, then open `codex-ide-menu'."
  (interactive)
  ;; Remove this temporary definition before loading the real one.
  (fmakunbound 'codex-ide-menu)
  (my/codex-ide-ensure)
  (call-interactively #'codex-ide-menu))

(provide 'init-agent)
;;; init-agent.el ends here
