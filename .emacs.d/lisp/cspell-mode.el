;;; cspell-mode.el --- CSpell mode -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:

(require 'cl-lib)
(require 'subr-x)

(defgroup cspell-mode nil
  "CSpell integration for Emacs."
  :group 'convenience
  :prefix "cspell-")

(defcustom cspell-executable "cspell"
  "CSpell executable."
  :type 'string)

(defcustom cspell-idle-delay 0.8
  "Idle delay before checking the current buffer."
  :type 'number)

(defcustom cspell-extra-args nil
  "Extra arguments passed to `cspell lint'."
  :type '(repeat string))

(defcustom cspell-config nil
  "Optional path to cspell config file.
When nil, CSpell searches configuration from the current file/project."
  :type '(choice (const :tag "Auto" nil)
                 file))

(defcustom cspell-root nil
  "Optional root directory passed to CSpell.
When nil, use `project-current' root if available, otherwise `default-directory'."
  :type '(choice (const :tag "Auto" nil)
                 directory))

(defcustom cspell-include-modes nil
  "Major modes where `global-cspell-mode' should enable `cspell-mode'.
Nil means enable in all buffers except excluded modes."
  :type '(repeat symbol))

(defcustom cspell-exclude-modes
  '(minibuffer-mode
    special-mode
    dired-mode
    help-mode
    compilation-mode
    term-mode
    vterm-mode
    eshell-mode
    shell-mode)
  "Major modes where `global-cspell-mode' should not enable `cspell-mode'."
  :type '(repeat symbol))

(defcustom cspell-ignore-regexps
  '("\\`[[:space:][:punct:]]+\\'"
    "\\`[0-9[:punct:]]+\\'")
  "Regexps for words which should not be highlighted."
  :type '(repeat regexp))

(defface cspell-error-face
  '((t (:underline (:style wave :color "YellowGreen"))))
  "Face used for misspelled words.")

(defvar-local cspell--timer nil)
(defvar-local cspell--process nil)
(defvar-local cspell--check-id 0)
(defvar-local cspell--overlays nil)
(defvar-local cspell--ignored-words nil)

(defconst cspell--line-re
  "^.*?:\\([0-9]+\\):\\([0-9]+\\) - \\(Unknown word\\|Forbidden word\\) (\\([^)\n]+\\))\\(?:.*fix: (\\([^)\n]+\\))\\)?"
  "Regexp matching common CSpell issue output.")

(defvar cspell-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "M-$") #'cspell-correct)
    (define-key map (kbd "M-n") #'cspell-next-error)
    (define-key map (kbd "M-p") #'cspell-previous-error)
    (define-key map (kbd "C-c $ b") #'cspell-check-buffer)
    (define-key map (kbd "C-c $ i") #'cspell-ignore-word-at-point)
    map)
  "Keymap for `cspell-mode'.")

(defun cspell--project-root ()
  "Return root directory for CSpell."
  (file-name-as-directory
   (or cspell-root
       (when-let* ((project (and (fboundp 'project-current)
                                 (project-current nil))))
         (if (fboundp 'project-root)
             (project-root project)
           (car (project-roots project))))
       default-directory)))

(defun cspell--buffer-file-name ()
  "Return a plausible file name for CSpell."
  (or buffer-file-name
      (expand-file-name
       (concat "buffer."
               (or (and buffer-file-name
                        (file-name-extension buffer-file-name))
                   "txt"))
       (cspell--project-root))))

(defun cspell--command (stdin-path)
  "Build CSpell command for STDIN-PATH."
  (append
   (list cspell-executable
         "lint"
         "--no-color"
         "--no-progress"
         "--no-summary"
         "--no-exit-code"
         "--show-suggestions")
   (when cspell-config
     (list "--config" (expand-file-name cspell-config)))
   cspell-extra-args
   (list (concat "stdin://" stdin-path))))

(defun cspell--delete-overlays (&optional beg end)
  "Delete CSpell overlays between BEG and END."
  (let ((beg (or beg (point-min)))
        (end (or end (point-max))))
    (setq cspell--overlays
          (cl-loop for ov in cspell--overlays
                   if (and (overlay-buffer ov)
                           (< (overlay-start ov) end)
                           (> (overlay-end ov) beg))
                   do (delete-overlay ov)
                   else collect ov))))

(defun cspell--ignored-word-p (word)
  "Return non-nil if WORD should be ignored."
  (or (member-ignore-case word cspell--ignored-words)
      (cl-some (lambda (re) (string-match-p re word))
               cspell-ignore-regexps)))

(defun cspell--line-column-to-point (base line column)
  "Return buffer position from BASE-relative LINE and COLUMN.
LINE and COLUMN are one-based as reported by CSpell."
  (save-excursion
    (goto-char base)
    (forward-line (1- line))
    (move-to-column (max 0 (1- column)))
    (point)))

(defun cspell--hint-string (word issue suggestions)
  "Build point-local hint text for WORD, ISSUE and SUGGESTIONS."
  (if suggestions
      (format "[CSpell] %s: %s; suggestions: %s"
              issue word (string-join suggestions ", "))
    (format "[CSpell] %s: %s" issue word )))

(defun cspell--make-overlay (beg end word issue suggestions)
  "Create misspelling overlay from BEG to END for WORD, ISSUE and SUGGESTIONS."
  (unless (cspell--ignored-word-p word)
    (let ((ov (make-overlay beg end nil nil t)))
      (overlay-put ov 'face 'cspell-error-face)
      (overlay-put ov 'help-echo (cspell--hint-string word issue suggestions))
      (overlay-put ov 'cspell t)
      (overlay-put ov 'cspell-word word)
      (overlay-put ov 'cspell-issue issue)
      (overlay-put ov 'cspell-suggestions suggestions)
      (overlay-put ov 'evaporate t)
      (push ov cspell--overlays)
      ov)))

(defun cspell--parse-suggestions (raw)
  "Parse CSpell suggestion RAW string."
  (when (and raw (not (string-empty-p raw)))
    (mapcar #'string-trim (split-string raw "," t "[[:space:]\n]*"))))

(defun cspell--apply-output (output base limit)
  "Parse CSpell OUTPUT and add overlays relative to BASE up to LIMIT."
  (cspell--delete-overlays base limit)
  (dolist (line (split-string output "\n" t))
    (when (string-match cspell--line-re line)
      (let* ((ln (string-to-number (match-string 1 line)))
             (col (string-to-number (match-string 2 line)))
             (issue (match-string 3 line))
             (word (match-string 4 line))
             (suggestions (cspell--parse-suggestions (match-string 5 line)))
             (beg (cspell--line-column-to-point base ln col))
             (line-end (save-excursion
                         (goto-char beg)
                         (line-end-position)))
             ;; Prefer exact search on the reported line.  This survives
             ;; small column differences caused by unicode width/byte issues.
             (real-beg (save-excursion
                         (goto-char beg)
                         (if (search-forward word line-end t)
                             (match-beginning 0)
                           beg)))
             (end (min limit (+ real-beg (length word)))))
        (when (< real-beg end)
          (cspell--make-overlay real-beg end word issue suggestions))))))

(defun cspell--sentinel (buffer check-id base limit output-buffer proc _event)
  "Process sentinel for CSpell."
  (when (memq (process-status proc) '(exit signal))
    (let ((output
           (when (buffer-live-p output-buffer)
             (with-current-buffer output-buffer
               (buffer-string)))))
      (when (buffer-live-p output-buffer)
        (kill-buffer output-buffer))
      (when (and output
                 (buffer-live-p buffer))
        (with-current-buffer buffer
          (when (and cspell-mode
                     (= check-id cspell--check-id))
            (save-excursion
              (cspell--apply-output output base limit))))))))

(defun cspell--start-check (beg end)
  "Start async CSpell check between BEG and END."
  (when (and cspell-mode
             (executable-find cspell-executable)
             (< beg end))
    (when (process-live-p cspell--process)
      (delete-process cspell--process))
    (cl-incf cspell--check-id)
    (let* ((check-id cspell--check-id)
           (buffer (current-buffer))
           (stdin-path (cspell--buffer-file-name))
           (default-directory (cspell--project-root))
           (text (buffer-substring-no-properties beg end))
           (outbuf (generate-new-buffer " *cspell-output*"))
           (proc (make-process
                  :name "cspell"
                  :buffer outbuf
                  :command (cspell--command stdin-path)
                  :connection-type 'pipe
                  :noquery t
                  :sentinel
                  (lambda (proc event)
                    (cspell--sentinel buffer check-id beg end outbuf proc event)))))
      (setq cspell--process proc)
      (process-send-string proc text)
      (process-send-eof proc))))

(defun cspell--schedule ()
  "Schedule a whole-buffer check."
  (when cspell--timer
    (cancel-timer cspell--timer))
  (setq cspell--timer
        (run-with-idle-timer
         cspell-idle-delay nil
         (lambda (buffer)
           (when (buffer-live-p buffer)
             (with-current-buffer buffer
               (when cspell-mode
                 (cspell-check-buffer)))))
         (current-buffer))))

(defun cspell--after-change (beg end _len)
  "Handle buffer change from BEG to END."
  (cspell--delete-overlays
   (save-excursion
     (goto-char beg)
     (line-beginning-position))
   (save-excursion
     (goto-char end)
     (line-end-position)))
  (cspell--schedule))

(defun cspell-debug-buffer ()
  "Run CSpell on current buffer and show raw output."
  (interactive)
  (let* ((stdin-path (cspell--buffer-file-name))
         (default-directory (cspell--project-root))
         (buf (get-buffer-create "*cspell-debug*"))
         (cmd (cspell--command stdin-path)))
    (with-current-buffer buf
      (erase-buffer)
      (insert (format "Directory: %s\nCommand: %S\n\n"
                      default-directory cmd)))
    (let ((exit-code
           (apply #'call-process-region
                  (point-min) (point-max)
                  (car cmd)
                  nil buf nil
                  (cdr cmd))))
      (pop-to-buffer buf)
      (goto-char (point-min))
      (message "cspell exited with %s" exit-code))))

;;;###autoload
(defun cspell-check-buffer ()
  "Check the entire current buffer."
  (interactive)
  (cspell--start-check (point-min) (point-max)))

(defun cspell--overlays-sorted ()
  "Return live CSpell overlays sorted by position."
  (sort (cl-remove-if-not #'overlay-buffer cspell--overlays)
        (lambda (a b)
          (< (overlay-start a) (overlay-start b)))))

(defun cspell--overlay-at-point ()
  "Return CSpell overlay at point, if any."
  (cl-find-if (lambda (ov) (overlay-get ov 'cspell))
              (overlays-at (point))))

(defun cspell-eldoc-function (&rest _ignored)
  "Return point-local CSpell documentation for Eldoc."
  (when-let* ((ov (cspell--overlay-at-point))
              (word (overlay-get ov 'cspell-word))
              (issue (overlay-get ov 'cspell-issue)))
    (cspell--hint-string word issue
                         (overlay-get ov 'cspell-suggestions))))

(defun cspell--next-overlay (&optional backward)
  "Return next CSpell overlay.
If BACKWARD is non-nil, search backward."
  (let* ((pos (point))
         (ovs (cspell--overlays-sorted)))
    (if backward
        (or (cl-loop for ov in (reverse ovs)
                     when (< (overlay-start ov) pos)
                     return ov)
            (car (last ovs)))
      (or (cl-loop for ov in ovs
                   when (> (overlay-start ov) pos)
                   return ov)
          (car ovs)))))

;;;###autoload
(defun cspell-next-error ()
  "Jump to next CSpell error."
  (interactive)
  (if-let* ((ov (cspell--next-overlay nil)))
      (goto-char (overlay-start ov))
    (message "No CSpell errors")))

;;;###autoload
(defun cspell-previous-error ()
  "Jump to previous CSpell error."
  (interactive)
  (if-let* ((ov (cspell--next-overlay t)))
      (goto-char (overlay-start ov))
    (message "No CSpell errors")))

(defun cspell--read-correction (word suggestions)
  "Read correction for WORD from SUGGESTIONS."
  (let* ((prompt (format "Replace %s with: " word))
         (choices (delete-dups (delq nil (copy-sequence suggestions))))
         (input (completing-read prompt choices nil nil nil nil
                                 (car choices))))
    (unless (string-empty-p input)
      input)))

;;;###autoload
(defun cspell-correct ()
  "Correct misspelling at point or the next misspelling."
  (interactive)
  (unless (cspell--overlay-at-point)
    (cspell-next-error))
  (if-let* ((ov (cspell--overlay-at-point)))
      (let* ((word (overlay-get ov 'cspell-word))
             (suggestions (overlay-get ov 'cspell-suggestions))
             (replacement (cspell--read-correction word suggestions)))
        (when replacement
          (let ((beg (overlay-start ov))
                (end (overlay-end ov)))
            (delete-overlay ov)
            (setq cspell--overlays (delq ov cspell--overlays))
            (goto-char beg)
            (delete-region beg end)
            (insert replacement)
            (cspell--schedule))))
    (message "No CSpell error at point")))

;;;###autoload
(defun cspell-ignore-word-at-point ()
  "Ignore the misspelled word at point for the current buffer."
  (interactive)
  (if-let* ((ov (cspell--overlay-at-point))
            (word (overlay-get ov 'cspell-word)))
      (progn
        (cl-pushnew word cspell--ignored-words :test #'equal-ignore-case)
        (dolist (candidate (copy-sequence cspell--overlays))
          (when (equal-ignore-case word (overlay-get candidate 'cspell-word))
            (delete-overlay candidate)
            (setq cspell--overlays (delq candidate cspell--overlays))))
        (message "CSpell ignored word in this buffer: %s" word))
    (message "No CSpell error at point")))

(defun cspell--enable-p ()
  "Return non-nil if `global-cspell-mode' should enable this buffer."
  (and (not (minibufferp))
       (not (member major-mode cspell-exclude-modes))
       (or (null cspell-include-modes)
           (apply #'derived-mode-p cspell-include-modes))))

;;;###autoload
(define-minor-mode cspell-mode
  "Minor mode for CSpell overlay spell checking."
  :lighter " CSpell"
  :keymap cspell-mode-map
  (if cspell-mode
      (progn
        (unless (executable-find cspell-executable)
          (message "Cannot find CSpell executable: %s" cspell-executable))
        (add-hook 'after-change-functions #'cspell--after-change nil t)
        (add-hook 'eldoc-documentation-functions #'cspell-eldoc-function nil t)
        (cspell--schedule))
    (remove-hook 'after-change-functions #'cspell--after-change t)
    (remove-hook 'eldoc-documentation-functions #'cspell-eldoc-function t)
    (when cspell--timer
      (cancel-timer cspell--timer)
      (setq cspell--timer nil))
    (when (process-live-p cspell--process)
      (delete-process cspell--process))
    (cspell--delete-overlays)))

;;;###autoload
(define-globalized-minor-mode global-cspell-mode
  cspell-mode
  (lambda ()
    (when (cspell--enable-p)
      (cspell-mode 1))))

(provide 'cspell-mode)

;;; cspell-mode.el ends here
