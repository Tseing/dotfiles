;;; init.el --- Settings for emacs -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(add-to-list 'load-path
     (expand-file-name "lisp" user-emacs-directory))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(require 'init-startup)
(require 'init-elpa)
(require 'init-evil)
(require 'init-ui)
(require 'init-packages)
(require 'init-ide)
(require 'init-agent)

(when (file-exists-p custom-file)
  (load-file custom-file))

;;; init.el ends here
