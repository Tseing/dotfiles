;;;; init-straight --- settings for packages -*- lexical-binding: t -*-

;;; Commentary:
;;; Code:

; (setq straight-vc-git-default-protocol 'ssh)
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        user-emacs-directory))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)

(require 'use-package)

(setq straight-use-package-by-default t)

(setq use-package-always-ensure nil
      use-package-always-defer t
      use-package-enable-imenu-support t
      use-package-expand-minimally t
      use-package-verbose t)

(use-package restart-emacs)

(provide 'init-straight)

;;; init-straight.el ends here
