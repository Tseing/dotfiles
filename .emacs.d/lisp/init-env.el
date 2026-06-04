;;; init-env --- load env from shell -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:
(use-package exec-path-from-shell
  :if (or (daemonp) (memq window-system '(x pgtk ns)))
  :demand t
  :custom
  (exec-path-from-shell-arguments nil)
  :config
  (exec-path-from-shell-initialize))

(provide 'init-env)
;;; init-env.el ends here
