;;; init-agent.el --- AI / Agent tools -*- lexical-binding: t; -*-

;;; Commentary:
;; Optional AI / agent integrations.

;;; Code:

(defun my/install-codex-ide ()
  "Install codex-ide and its required transient package with straight.el."
  (interactive)
  (straight-use-package 'transient)
  (straight-use-package
   '(codex-ide :type git :host github :repo "dgillis/emacs-codex-ide"))
  (message "codex-ide installed. You can now run M-x codex-ide-menu."))

(let ((straight-use-package-by-default nil))
  (use-package transient
    :straight t
    :defer t)

  (use-package codex-ide
    :straight (:type git :host github :repo "dgillis/emacs-codex-ide")
    :commands (codex-ide codex-ide-menu)))

(provide 'init-agent)
;;; init-agent.el ends here
