;;; init-elpa --- settings for elpa

;;; Commentary:
;;; Code:

(setq package-archives '(("melpa" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")
			 ("gnu" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
			 ("org" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/org/")))

(setq package-check-signature nil)

(require 'package)

(unless (bound-and-true-p package--initialized)
  (package-initialize))

(unless (package-installed-p 'use-package)
  (condition-case err
      (progn
        (package-refresh-contents)
        (package-install 'use-package))
    (error
     (display-warning
      'init-elpa
      (format "Unable to install use-package during startup: %s" err)
      :warning))))

(setq use-package-always-ensure t
      use-package-always-defer t
      use-package-enable-imenu-support t
      use-package-expand-minimally t
      use-package-verbose t)

(require 'use-package nil t)
(when (featurep 'use-package)
  (use-package restart-emacs))

(provide 'init-elpa)

;;; init-elpa.el ends here
