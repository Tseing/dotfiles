;;; cspell-mode.el --- CSpell mode -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:

(require 'cl-lib)
(require 'json)
(require 'subr-x)

(defgroup cspell-mode nil
  "CSpell integration for Emacs."
  :group 'convenience
  :prefix "cspell-")

(defcustom cspell-executable "cspell"
  "CSpell executable used to locate the bundled CSpell libraries."
  :type 'string)

(defcustom cspell-node-executable "node"
  "Node executable used to run the CSpell helper."
  :type 'string)

(defcustom cspell-idle-delay 0.8
  "Idle delay before checking the current buffer."
  :type 'number)

(defcustom cspell-large-file-threshold 50000
  "Use visible-region checking when the buffer exceeds this size.
The value is measured in characters. Nil disables the guard."
  :type '(choice (const :tag "Disabled" nil)
                 integer))

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

(defface cspell-error-face
  '((t (:underline (:style wave :color "YellowGreen"))))
  "Face used for misspelled words.")

(defvar-local cspell--timer nil)
(defvar-local cspell--check-id 0)
(defvar-local cspell--request-id nil)
(defvar-local cspell--request-region nil)
(defvar-local cspell--overlays nil)
(defvar-local cspell--ignored-words nil)

(defvar cspell--session-process nil)
(defvar cspell--session-stdout-buffer nil)
(defvar cspell--session-stderr-buffer nil)
(defvar cspell--session-output "")
(defvar cspell--request-seq 0)
(defvar cspell--pending-requests (make-hash-table :test #'eql))

(defvar cspell-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "M-$") #'cspell-correct)
    (define-key map (kbd "C-c $ b") #'cspell-check-buffer)
    (define-key map (kbd "C-c $ i") #'cspell-ignore-word-at-point)
    map)
  "Keymap for `cspell-mode'.")

(defconst cspell--directory
  (file-name-directory
   (or load-file-name
       buffer-file-name))
  "Directory where cspell-mode.el is located.")

(defun cspell--project-root ()
  "Return root directory for CSpell."
  (file-name-as-directory
   (expand-file-name
    (or cspell-root
        (when-let* ((project (and (fboundp 'project-current)
                                  (project-current nil))))
          (if (fboundp 'project-root)
              (project-root project)
            (car (project-roots project))))
        default-directory))))

(defun cspell--buffer-file-name ()
  "Return a plausible file name for CSpell."
  (or buffer-file-name
      (expand-file-name
       (concat "buffer."
               (or (and buffer-file-name
                        (file-name-extension buffer-file-name))
                   "txt"))
       (cspell--project-root))))

(defun cspell--helper-script ()
  "Return the helper script path."
  (expand-file-name "cspell-mode-helper.mjs" cspell--directory))

(defun cspell--cspell-command ()
  "Return the resolved CSpell executable path."
  (or (executable-find cspell-executable)
      (and (file-executable-p cspell-executable)
           cspell-executable)))

(defun cspell--point-to-utf16-offset (pos)
  "Return the UTF-16 offset from `point-min' to POS."
  (let ((units 0))
    (save-excursion
      (goto-char (point-min))
      (while (< (point) pos)
        (let ((char (char-after)))
          (setq units (+ units (if (and char (> char #xffff)) 2 1)))
          (forward-char 1))))
    units))

(defun cspell--visible-region ()
  "Return the visible region for the current buffer."
  (let ((windows (get-buffer-window-list (current-buffer) nil t)))
    (if (not windows)
        (cons (point-min) (point-max))
      (let ((beg (apply #'min (mapcar #'window-start windows)))
            (end (apply #'max (mapcar #'window-end windows))))
        (save-excursion
          (goto-char beg)
          (setq beg (line-beginning-position))
          (goto-char end)
          (setq end (line-end-position)))
        (cons beg end)))))

(defun cspell--check-region ()
  "Return the region to check for automatic refresh."
  (if (and cspell-large-file-threshold
           (> (buffer-size) cspell-large-file-threshold))
      (cspell--visible-region)
    (cons (point-min) (point-max))))

(defun cspell--post-command ()
  "Schedule a check after point or window movement changes the target region."
  (when cspell-mode
    (let ((region (cspell--check-region)))
      (unless (equal region cspell--request-region)
        (cspell--schedule)))))

(defun cspell--make-request (beg end)
  "Return `(REQUEST-ID . JSON-PAYLOAD)' for region BEG END."
  (let ((request-id (cl-incf cspell--request-seq)))
    (cons
     request-id
     (json-encode
      `((requestId . ,request-id)
        (cspellCommand . ,(cspell--cspell-command))
        (uri . ,(cspell--buffer-file-name))
        (text . ,(buffer-substring-no-properties beg end))
        (baseOffset . ,(cspell--point-to-utf16-offset beg))
        (languageId . ,(symbol-name major-mode))
        (locale . nil)
        (configFile . ,(when cspell-config
                         (expand-file-name cspell-config)))
        (root . ,(cspell--project-root)))))))

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
  (member-ignore-case word cspell--ignored-words))

(defun cspell--utf16-offset-to-point (offset)
  "Return the buffer position for UTF-16 OFFSET."
  (let ((units 0)
        (pos (point-min)))
    (while (and (< units offset)
                (< pos (point-max)))
      (let ((char (char-after pos)))
        (setq units (+ units (if (and char (> char #xffff)) 2 1)))
        (setq pos (1+ pos))))
    pos))

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

(defun cspell--apply-issues (issues beg end)
  "Apply helper ISSUES to the current buffer between BEG and END."
  (cspell--delete-overlays beg end)
  (dolist (issue issues)
    (let* ((word (plist-get issue :text))
           (offset (plist-get issue :offset))
           (length (plist-get issue :length))
           (issue-type (plist-get issue :issueType))
           (suggestions (plist-get issue :suggestions))
           (beg (cspell--utf16-offset-to-point offset))
           (end (cspell--utf16-offset-to-point (+ offset length))))
      (when (< beg end)
        (cspell--make-overlay beg end word issue-type suggestions)))))

(defun cspell--parse-helper-output (output)
  "Parse helper OUTPUT into a plist."
  (json-parse-string output :object-type 'plist :array-type 'list))

(defun cspell--send-cancel (request-id)
  "Send a cancel message for REQUEST-ID."
  (when (and request-id
             (process-live-p cspell--session-process))
    (process-send-string
     cspell--session-process
     (concat (json-encode `((type . "cancel")
                            (requestId . ,request-id)))
             "\n"))))

(defun cspell--stderr-string ()
  "Return helper stderr output."
  (when (buffer-live-p cspell--session-stderr-buffer)
    (with-current-buffer cspell--session-stderr-buffer
      (buffer-string))))

(defun cspell--handle-response (response)
  "Handle helper RESPONSE."
  (let* ((request-id (plist-get response :requestId))
         (canceled (plist-get response :canceled))
         (runtime-errors (plist-get response :errors))
         (pending (and request-id
                       (gethash request-id cspell--pending-requests))))
    (when request-id
      (remhash request-id cspell--pending-requests))
    (if (or canceled (not pending))
        (when runtime-errors
          (message "CSpell helper reported issues: %s"
                   (string-join runtime-errors "; ")))
      (let ((buffer (plist-get pending :buffer))
            (check-id (plist-get pending :check-id))
            (beg (plist-get pending :beg))
            (end (plist-get pending :end)))
        (when (buffer-live-p buffer)
          (with-current-buffer buffer
            (when (and cspell-mode
                       (= check-id cspell--check-id)
                       (equal request-id cspell--request-id))
              (save-excursion
                (cspell--apply-issues (plist-get response :issues) beg end))
              (when runtime-errors
                (message "CSpell helper reported issues: %s"
                         (string-join runtime-errors "; "))))))))))

(defun cspell--process-filter (_proc chunk)
  "Process helper stdout CHUNK."
  (setq cspell--session-output (concat cspell--session-output chunk))
  (while (string-match "\n" cspell--session-output)
    (let ((line (substring cspell--session-output 0 (match-beginning 0))))
      (setq cspell--session-output
            (substring cspell--session-output (match-end 0)))
      (unless (string-empty-p line)
        (condition-case err
            (cspell--handle-response (cspell--parse-helper-output line))
          (error
           (message "CSpell helper parse failed: %s%s"
                    (error-message-string err)
                    (if-let* ((errors (cspell--stderr-string))
                              ((not (string-empty-p errors))))
                        (format " (%s)" (string-trim errors))
                      ""))))))))

(defun cspell--process-sentinel (_proc _event)
  "Handle helper process exit."
  (clrhash cspell--pending-requests)
  (setq cspell--session-process nil
        cspell--session-output "")
  (when (buffer-live-p cspell--session-stdout-buffer)
    (kill-buffer cspell--session-stdout-buffer))
  (when (buffer-live-p cspell--session-stderr-buffer)
    (kill-buffer cspell--session-stderr-buffer))
  (setq cspell--session-stdout-buffer nil
        cspell--session-stderr-buffer nil))

(defun cspell--ensure-session ()
  "Ensure the persistent helper process is running."
  (unless (process-live-p cspell--session-process)
    (setq cspell--session-output ""
          cspell--session-stdout-buffer (generate-new-buffer " *cspell-session*")
          cspell--session-stderr-buffer (generate-new-buffer " *cspell-session-error*")
          cspell--session-process
          (make-process
           :name "cspell-session"
           :buffer cspell--session-stdout-buffer
           :command (list cspell-node-executable
                          (cspell--helper-script))
           :connection-type 'pipe
           :coding 'utf-8-unix
           :noquery t
           :filter #'cspell--process-filter
           :sentinel #'cspell--process-sentinel
           :stderr cspell--session-stderr-buffer)))
  cspell--session-process)

(defun cspell--start-check (beg end)
  "Start an async CSpell check for region BEG END."
  (when (and cspell-mode
             (cspell--cspell-command)
             (executable-find cspell-node-executable)
             (< beg end))
    (cl-incf cspell--check-id)
    (let* ((buffer (current-buffer))
           (default-directory (cspell--project-root))
           (request (cspell--make-request beg end))
           (request-id (car request))
           (payload (cdr request))
           (proc (cspell--ensure-session)))
      (cspell--send-cancel cspell--request-id)
      (setq cspell--request-id request-id)
      (setq cspell--request-region (cons beg end))
      (puthash request-id
               (list :buffer buffer
                     :check-id cspell--check-id
                     :beg beg
                     :end end)
               cspell--pending-requests)
      (process-send-string proc (concat payload "\n")))))

(defun cspell--schedule ()
  "Schedule a guarded check."
  (when cspell--timer
    (cancel-timer cspell--timer))
  (setq cspell--timer
        (run-with-idle-timer
         cspell-idle-delay nil
         (lambda (buffer)
           (when (buffer-live-p buffer)
             (with-current-buffer buffer
               (when cspell-mode
                 (pcase-let ((`(,beg . ,end) (cspell--check-region)))
                   (cspell--start-check beg end))))))
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
  "Run the CSpell helper on current buffer and show raw output."
  (interactive)
  (let* ((default-directory (cspell--project-root))
         (buf (get-buffer-create "*cspell-debug*"))
         (cmd (list cspell-node-executable
                    (cspell--helper-script)
                    "--once"))
         (request (cdr (cspell--make-request (point-min) (point-max)))))
    (with-current-buffer buf
      (erase-buffer)
      (insert (format "Directory: %s\nCommand: %S\n\n"
                      default-directory cmd)))
    (with-temp-buffer
      (insert request)
      (let ((exit-code
             (apply #'call-process-region
                    (point-min) (point-max)
                    (car cmd)
                    nil buf nil
                    (cdr cmd))))
        (pop-to-buffer buf)
        (goto-char (point-min))
        (message "cspell helper exited with %s" exit-code)))))

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
(defun cspell-next ()
  "Jump to next CSpell error."
  (interactive)
  (if-let* ((ov (cspell--next-overlay nil)))
      (goto-char (overlay-start ov))
    (message "No CSpell errors")))

;;;###autoload
(defun cspell-previous ()
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
    (cspell-next))
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
        (unless (executable-find cspell-node-executable)
          (message "Cannot find Node executable: %s" cspell-node-executable))
        (add-hook 'after-change-functions #'cspell--after-change nil t)
        (add-hook 'post-command-hook #'cspell--post-command nil t)
        (add-hook 'eldoc-documentation-functions #'cspell-eldoc-function nil t)
        (cspell--schedule))
    (remove-hook 'after-change-functions #'cspell--after-change t)
    (remove-hook 'post-command-hook #'cspell--post-command t)
    (remove-hook 'eldoc-documentation-functions #'cspell-eldoc-function t)
    (when cspell--timer
      (cancel-timer cspell--timer)
      (setq cspell--timer nil))
    (setq cspell--request-region nil)
    (cspell--delete-overlays)))

;;;###autoload
(define-globalized-minor-mode global-cspell-mode
  cspell-mode
  (lambda ()
    (when (cspell--enable-p)
      (cspell-mode 1))))

(provide 'cspell-mode)

;;; cspell-mode.el ends here
