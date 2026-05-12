;;; init-theme --- Settings for theme -*- lexical-binding: t -*-

;;; Commentary:
;;; Code:


(use-package doom-themes
  :demand t
  :init
  (load-theme 'doom-one t)
  :config
  (doom-themes-org-config))

(use-package nerd-icons
  :custom
  (nerd-icons-font-family "FiraCode Nerd Font"))

(use-package doom-modeline
  :init
  (doom-modeline-mode 1)
  :config
  (set-face-attribute 'mode-line nil
                      :family "FiraCode Nerd Font"
                      :height 120)
  (set-face-attribute 'mode-line-active nil
                      :family "FiraCode Nerd Font"
                      :height 120)
  (set-face-attribute 'mode-line-inactive nil
                      :family "FiraCode Nerd Font"
                      :height 120))

(use-package dashboard
  :init
  (setq dashboard-startupify-list '(dashboard-insert-banner
                                        ; dashboard-insert-navigator
                                    dashboard-insert-init-info
                                    dashboard-insert-items)
        dashboard-startup-banner 'logo-braille
        dashboard-center-content t
        dashboard-items '((projects . 5)
                          (recents . 5))
        dashboard-projects-backend 'project-el
        dashboard-icon-type 'nerd-icons
        dashboard-set-file-icons t
        initial-buffer-choice #'dashboard-open)
  :config
  (dashboard-setup-startup-hook))

(use-package nerd-icons-dired
  :hook
  (dired-mode . nerd-icons-dired-mode))

(with-eval-after-load 'acm-icon
  (defun my/nerd-icons-by-name (name &rest args)
    "Return nerd-icons icon by full icon NAME."
    (apply
     (cond
      ((string-prefix-p "nf-cod-" name) #'nerd-icons-codicon)
      ((string-prefix-p "nf-md-" name) #'nerd-icons-mdicon)
      ((string-prefix-p "nf-fa-" name) #'nerd-icons-faicon)
      ((string-prefix-p "nf-fae-" name) #'nerd-icons-faicon)
      ((string-prefix-p "nf-oct-" name) #'nerd-icons-octicon)
      ((string-prefix-p "nf-dev-" name) #'nerd-icons-devicon)
      ((string-prefix-p "nf-seti-" name) #'nerd-icons-sucicon)
      ((string-prefix-p "nf-custom-" name) #'nerd-icons-sucicon)
      ((string-prefix-p "nf-weather-" name) #'nerd-icons-wicon)
      ((string-prefix-p "nf-iec-" name) #'nerd-icons-ipsicon)
      ((string-prefix-p "nf-linux-" name) #'nerd-icons-flicon)
      ((string-prefix-p "nf-pom-" name) #'nerd-icons-pomicon)
      (t #'nerd-icons-codicon))
     name
     args))

  (defun my/acm-icon-build-around (orig-fun icon face background)
    "Use nerd-icons when ICON is marked as a nerd icon."
    (if (and (consp icon)
             (eq (car icon) :nerd))
        (concat
         " "
         (my/nerd-icons-by-name (cadr icon) :face face)
         " ")
      (funcall orig-fun icon face background)))

  (advice-add 'acm-icon-build :around #'my/acm-icon-build-around)

  (defun my/acm-icon (icon-name face)
    "Build ACM icon data from nerd-icons ICON-NAME with FACE."
    (list (list :nerd icon-name) face nil))

  (setq acm-icon-alist
        `(("function"  . ,(my/acm-icon "nf-md-function_variant" 'font-lock-constant-face))
          ("method"    . ,(my/acm-icon "nf-cod-symbol_method" 'font-lock-function-constant-face))
          ("keyword"   . ,(my/acm-icon "nf-cod-key" 'font-lock-constant-face))
          ("module"    . ,(my/acm-icon "nf-md-package_variant_closed" 'font-lock-constant-face))
          ("package"   . ,(my/acm-icon "nf-cod-package" 'font-lock-constant-face))
          ("namespace" . ,(my/acm-icon "nf-cod-symbol_namespace" 'font-lock-constant-face))
          ("snippet"   . ,(my/acm-icon "nf-md-bash" 'font-lock-constant-face))
          ("text"      . ,(my/acm-icon "nf-cod-symbol_parameter" 'font-lock-constant-face))
          ("variable"  . ,(my/acm-icon "nf-md-variable" 'font-lock-constant-face))
          ("class"     . ,(my/acm-icon "nf-md-alphabetical_variant" 'font-lock-constant-face))
          ("interface" . ,(my/acm-icon "nf-cod-symbol_interface" 'font-lock-constant-face))
          ("field"     . ,(my/acm-icon "nf-cod-symbol_field" 'font-lock-constant-face))
          ("property"  . ,(my/acm-icon "nf-cod-symbol_property" 'font-lock-constant-face))
          ("enum"      . ,(my/acm-icon "nf-cod-symbol_enum" 'font-lock-constant-face))
          ("constant"  . ,(my/acm-icon "nf-cod-symbol_constant" 'font-lock-constant-face))
          ("file"      . ,(my/acm-icon "nf-oct-file" 'font-lock-constant-face))
          ("folder"    . ,(my/acm-icon "nf-oct-file_directory" 'font-lock-constant-face))
          (t           . ,(my/acm-icon "nf-cod-symbol_misc" 'font-lock-constant-face)))))

(provide 'init-theme)

;;; init-theme.el ends here
