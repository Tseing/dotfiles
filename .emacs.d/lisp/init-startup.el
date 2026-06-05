;;; init-startup --- settings for startup -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:

(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)

(setq inhibit-startup-screen t)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024))))

(setq undo-limit (* 80 1024 1024)
      undo-strong-limit (* 120 1024 1024)
      undo-outer-limit (* 360 1024 1024))

(unless (file-directory-p (expand-file-name "cache/" user-emacs-directory))
  (make-directory (expand-file-name "cache/" user-emacs-directory) t))

(setq backup-directory-alist
      `(("." . ,(expand-file-name "cache/" user-emacs-directory))))
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "cache/" user-emacs-directory) t)))
(setq org-preview-latex-image-directory
      (expand-file-name "ltximg/" (expand-file-name "cache/" user-emacs-directory)))
(provide 'init-startup)
;;; init-startup.el ends here
