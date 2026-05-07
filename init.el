;; init.el --- Portable Emacs config -*- lexical-binding: t; -*-

;;UI系の設定
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(setq ring-bell-function 'ignore)
(setq inhibit-startup-screen t)
(setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))
;; ミニバッファの高さを制限(画面の25%まで)
(setq max-mini-window-height 0.25)
;;Shift + 矢印でバッファ移動をできるようにした
(windmove-default-keybindings)

;; ターミナルでマウスを有効化(GUI には影響なし)
(unless (display-graphic-p)
  (xterm-mouse-mode 1))

;; もしくは伸縮自体を止める(長文は切れるので注意)
;; (setq resize-mini-windows nil)

;;ディスプレイサイズの変更
(when (display-graphic-p)
  (add-to-list 'default-frame-alist '(width . 110))
  (add-to-list 'default-frame-alist '(height . 42))
  (add-to-list 'default-frame-alist '(top . 0))      ; 画面上端から50px
  (add-to-list 'default-frame-alist '(left . 0)))   ; 画面左端から100px)

;;ツールバースクロールバーの設定
(when (display-graphic-p)
  (tool-bar-mode -1)
  (scroll-bar-mode -1))


;;日本語系の設定
(set-language-environment "Japanese")
(prefer-coding-system 'utf-8)

;;utf-8の設定
(prefer-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8-unix)
(set-terminal-coding-system 'utf-8-unix)
(set-keyboard-coding-system 'utf-8-unix)
(setq locale-coding-system 'utf-8-unix)
(setq default-buffer-file-coding-system 'utf-8-unix)
(setq default-file-name-coding-system 'utf-8-unix)

;;macosのmodiferキー


;; ============================================================
;; フォント可用性の検出 (ポータブル化のための要)
;;   ・main-font:           本文用 (なければ Emacs デフォルトにフォールバック)
;;   ・icon-font:           Nerd Font の PUA グリフ描画用
;;   ・icons-available-p:   アイコン系パッケージを使えるか
;; ============================================================
(defun my/find-installed-font (candidates)
  "CANDIDATES のうち最初にインストールされているフォント名を返す。
GUI 以外、または何も見つからなければ nil。"
  (when (display-graphic-p)
    (seq-find (lambda (name)
                (find-font (font-spec :family name)))
              candidates)))

(defvar my/main-font
  (my/find-installed-font
   '("HackGen35 Console NF"
     "HackGen Console NF"
     "Hack Nerd Font"
     "JetBrains Mono"
     "Menlo"            ; macOS 標準
     "Consolas"         ; Windows 標準
:    "DejaVu Sans Mono" ; 多くの Linux に同梱
     "monospace"))
  "実際に使う本文フォント。インストール済みの先頭候補。")

(defvar my/icon-font
  (my/find-installed-font
   '("Symbols Nerd Font Mono"
     "Symbols Nerd Font"
     "HackGen35 Console NF"   ; HackGen NF 系は Nerd glyph 内蔵
     "HackGen Console NF"
     "Hack Nerd Font"
     "JetBrainsMono Nerd Font"))
  "Nerd Font のアイコン (PUA: U+E000-U+F8FF) を描画するフォント。")

(defvar my/icons-available-p
  (and (display-graphic-p) (stringp my/icon-font))
  "Nerd Font 由来のアイコン表示が安全に使える環境か。")


;;フォント (見つかったときだけ適用)
(when (and (display-graphic-p) my/main-font)
  (set-face-attribute 'default nil
                      :family my/main-font
                      :height 170)
  (set-fontset-font t 'unicode
                    (font-spec :family my/main-font)
                    nil 'append)
  (set-fontset-font t 'symbol
                    (font-spec :family my/main-font)
                    nil 'append))

;;バックアップ
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq create-lockfiles nil)


;;package.el

(require 'package)

(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
  	 ("nongnu" . "https://elpa.nongnu.org/nongnu/")
         ("melpa"  . "https://melpa.org/packages/")))

(setq package-enable-at-startup nil)
(package-initialize)

;;パッケージの更新システム
(defun my/package-refresh-contents ()
  (interactive)
  (message "Refreshing package archives...")
  (package-refresh-contents)
  (message "Refreshing package archives...done"))

(global-set-key (kbd "C-c p r") #'my/package-refresh-contents)

;; ----------------------------
;; use-package (Emacs 30 では標準搭載前提)
;; ----------------------------
(eval-when-compile
  (require 'use-package))

(setq use-package-always-ensure t)

;; ============================
;; UI（外観モダン化）
;; 参考: https://qiita.com/Ladicle/items/feb5f9dce9adf89652cf
;; ----------------------------
;; このファイルは Nerd Font の有無を自動検出し、
;; 無ければアイコン系パッケージを丸ごと無効化します。
;; アイコンが豆腐(□)になる場合は M-x nerd-icons-install-fonts を実行。
;; ============================

;; テーマ: doom-themes (doom-tokyo-night)
(use-package doom-themes
  :custom
  (doom-themes-enable-italic t)
  (doom-themes-enable-bold   t)
  :config
  (load-theme 'doom-tokyo-night t)
  (doom-themes-org-config))

;; nerd-icons elisp パッケージは常にインストール。
;;   理由: フォント自動インストール (M-x nerd-icons-install-fonts) を
;;         呼ぶためにパッケージ本体が必要なため。
;;         パッケージだけ入っていてもフォントが無ければ何も描画しないので無害。
(use-package nerd-icons
  :custom
  (nerd-icons-font-family "Symbols Nerd Font Mono"))

;; --- アイコン描画系パッケージは Nerd Font フォントがある時だけ ---
(when my/icons-available-p
  ;; vertico/marginalia の補完候補にアイコンを追加
  (use-package nerd-icons-completion
    :after marginalia
    :hook
    (marginalia-mode . nerd-icons-completion-marginalia-setup)
    :config
    (nerd-icons-completion-mode 1))

  ;; dired にもアイコン
  (use-package nerd-icons-dired
    :hook
    (dired-mode . nerd-icons-dired-mode))

  ;; corfu の候補にアイコンを付与
  (use-package nerd-icons-corfu
    :after corfu
    :config
    (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter)))

;; モードライン: doom-modeline (アイコンの ON/OFF だけ動的切替)
(use-package doom-modeline
  :custom
  (doom-modeline-buffer-file-name-style 'file-name-with-project)
  (doom-modeline-icon            my/icons-available-p)
  (doom-modeline-major-mode-icon my/icons-available-p)
  (doom-modeline-minor-modes nil)
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-bar-width 6)
  (doom-modeline-height 14)
  :custom-face
  (doom-modeline-evil-normal-state   ((t (:foreground "#9ece6a" :weight bold))))
  (doom-modeline-evil-insert-state   ((t (:foreground "#7dcfff" :weight bold))))
  (doom-modeline-evil-visual-state   ((t (:foreground "#bb9af7" :weight bold))))
  (doom-modeline-evil-replace-state  ((t (:foreground "#f7768e" :weight bold))))
  (doom-modeline-evil-motion-state   ((t (:foreground "#e0af68" :weight bold))))
  (doom-modeline-evil-operator-state ((t (:foreground "#ff9e64" :weight bold))))
  (doom-modeline-evil-emacs-state    ((t (:foreground "#ff007c" :weight bold))))
  :hook
  (after-init . doom-modeline-mode))


;; モードラインのセグメント間スペースを広げる
(with-eval-after-load 'doom-modeline
  (setq doom-modeline-spc  (propertize " " 'display '((space :width 1.4))))
  (setq doom-modeline-vspc (propertize " " 'face 'variable-pitch
                                       'display '((space :width 1.0)))))

;; 不要なモードラインを隠す
(use-package hide-mode-line
  :hook
  ((neotree-mode imenu-list-minor-mode treemacs-mode) . hide-mode-line-mode))

;; 括弧の虹色化
(use-package rainbow-delimiters
  :hook
  (prog-mode . rainbow-delimiters-mode))

;; インデントガイド
;;(use-package highlight-indent-guides
;;  :diminish
;;  :hook
;;  ((prog-mode yaml-mode) . highlight-indent-guides-mode)
;;  :custom
;;  (highlight-indent-guides-auto-enabled t)
;;  (highlight-indent-guides-responsive   t)
;;  (highlight-indent-guides-method 'character))

;; ペースト等の操作可視化
(use-package volatile-highlights
  :diminish
  :hook
  (after-init . volatile-highlights-mode)
  :custom-face
  (vhl/default-face ((t (:foreground "#FF3333" :background "#FFCDCD")))))

;; カーソル位置を一瞬光らせて見失い防止
(use-package beacon
  :diminish
  :custom
  (beacon-color "yellow")
  :hook
  (after-init . beacon-mode))

;; Git の変更行を左フリンジに表示
(use-package git-gutter
  :diminish
  :custom
  (git-gutter:modified-sign "~")
  (git-gutter:added-sign    "+")
  (git-gutter:deleted-sign  "-")
  :custom-face
  (git-gutter:modified ((t (:background "#e0af68"))))
  (git-gutter:added    ((t (:background "#9ece6a"))))
  (git-gutter:deleted  ((t (:background "#f7768e"))))
  :hook
 (after-init . global-git-gutter-mode))

;; ----------------------------
;; Git クライアント (Magit)
;;   起動: C-x g (magit-status)
;; ----------------------------
(use-package magit
  :commands (magit-status magit-dispatch magit-file-dispatch)
  :bind (("C-x g"   . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c M-g" . magit-file-dispatch))
  :custom
  (magit-diff-refine-hunk t))

;; 対応する括弧のハイライト (組み込み)
(use-package paren
  :ensure nil
  :hook
  (after-init . show-paren-mode)
  :custom
  (show-paren-style 'mixed)
  (show-paren-when-point-inside-paren t)
  (show-paren-when-point-in-periphery t)
  :custom-face
  (show-paren-match ((t (:background "#3b4261" :foreground "#e0af68")))))

;; 起動画面: dashboard (アイコンは Nerd Font のある時だけ)
(use-package dashboard
  :diminish (dashboard-mode page-break-lines-mode)
  :custom
  (dashboard-startup-banner 'logo)
  (dashboard-display-icons-p   my/icons-available-p)
  (dashboard-icon-type         (when my/icons-available-p 'nerd-icons))
  (dashboard-set-heading-icons my/icons-available-p)
  (dashboard-set-file-icons    my/icons-available-p)
  (dashboard-items '((recents   . 10)
                     (bookmarks . 5)
                     (projects  . 5)))
  :hook
  (after-init . dashboard-setup-startup-hook))



;; --- ウィンドウ分割線:GUI/TTY 両対応 ---
(setq window-divider-default-places t
      window-divider-default-right-width 2
      window-divider-default-bottom-width 2)
(when (display-graphic-p)
  (window-divider-mode 1))   ;; TTY では呼んでも無意味なので GUI 限定にしておく

(with-eval-after-load 'doom-themes
  (if (display-graphic-p)
      (progn
        (set-face-attribute 'window-divider             nil :foreground "#bb9af7")
        (set-face-attribute 'window-divider-first-pixel nil :foreground "#bb9af7")
        (set-face-attribute 'window-divider-last-pixel  nil :foreground "#bb9af7"))
    ;; TTY: 縦分割の罫線色だけ変えられる
    (set-face-attribute 'vertical-border nil :foreground "#bb9af7")))

;; --- モードラインの"枠":GUI は :box / TTY は色帯(:background) ---
;; Emacs の TTY 描画は :overline / :box を非対応 (xfaces.c の
;; tty_supports_face_attributes_p で明示的に false 扱い) のため、
;; TTY ではモードライン全体を反転色の帯にして視覚的に区切る。
(defun my/apply-modeline-border (&optional frame)
  (with-selected-frame (or frame (selected-frame))
    (if (display-graphic-p frame)
        (progn
          (set-face-attribute 'mode-line          frame
                              :box '(:line-width 2 :color "#2ac3de")
                              :overline 'unspecified :underline 'unspecified)
          (set-face-attribute 'mode-line-inactive frame
                              :box '(:line-width 2 :color "#1f5160")
                              :overline 'unspecified :underline 'unspecified))
      ;; TTY: overline 非対応端末でも違和感のない色帯方式 (落ち着いた配色)
      (set-face-attribute 'mode-line          frame
                          :box nil :overline 'unspecified :underline 'unspecified
                          :background "#3b4261" :foreground "#c0caf5")
      (set-face-attribute 'mode-line-inactive frame
                          :box nil :overline 'unspecified :underline 'unspecified
                          :background "#1f2335" :foreground "#565f89"))))

(add-hook 'after-init-hook            #'my/apply-modeline-border)
(add-hook 'after-make-frame-functions #'my/apply-modeline-border)  ;; daemon 対応

;; ----------------------------
;; 補完・ヘルプ系
;; ----------------------------
(use-package which-key
  :custom
  (which-key-idle-delay 0.4)
  (which-key-separator "  ")
  (which-key-prefix-prefix "+ ")
  (which-key-add-column-padding 2)
  :config
  (which-key-mode 1))


(use-package vertico
  :init
  (vertico-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles basic partial-completion)))))

(use-package marginalia
  :init
  (marginalia-mode 1))

(use-package consult)



;; ----------------------------
;; バッファ内補完 (nvim-cmp 相当)
;; ----------------------------
(use-package corfu
  :init
  (global-corfu-mode)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-quit-no-match 'separator)
  (tab-always-indent 'complete))

;;--------------------------------------
;;emacs内でリッチなターミナルを使えるようにする
;;--------------------------------------

(use-package eat
 :commands (eat eat-other-window)
 :hook (eat-mode . eat-char-mode) 
 :custom
 (eat-kill-buffer-on-exit t)
 (eat-enable-mouse t)
 (eat-term-name "xterm-256color"))

(use-package vterm
  :commands vterm
  :custom
  (vterm-max-scrollback 10000)
  (vterm-buffer-name-string "vterm: %s")
  (vterm-shell (or (getenv "SHELL") "/bin/zsh")))

;; ============================================================
;; LaTeX 編集環境 (vimtex 相当)
;;   ・latexmk + 何らかの TeX エンジンが揃った環境のみ有効化
;;   ・コア: AUCTeX (LaTeX-mode・コンパイル・SyncTeX・fold)
;;           RefTeX (相互参照 / 引用ナビ — AUCTeX 同梱)
;;           CDLaTeX (数式の高速入力 — vimtex の math snippets 相当)
;;           pdf-tools (Emacs 内で完結する PDF ビューア)
;;
;;   ・コンパイル: latexmk -synctex=1 のみを呼び出す。
;;                 -pdf / -pdflua / -pdfdvi のようなエンジン選択フラグは
;;                 一切渡さないため、pdf_mode (pdflatex / lualatex /
;;                 platex+dvipdfmx 等) は完全に ~/.latexmkrc 任せになる。
;;                 → auctex-latexmk は採用しない (こちらは TeX-PDF-mode から
;;                    -pdf 系フラグを生成するため latexmkrc と衝突しうる)。
;;
;;   ・PDF ビューア: GUI かつ macOS / Linux なら pdf-tools (Emacs 内表示) を
;;     最優先。初回 PDF オープン時に epdfinfo がビルドされる
;;     (依存: macOS=`brew install poppler automake`,
;;            Linux=`libpoppler-glib-dev` + 標準ビルドツール群)。
;;     TTY や非対応プラットフォームでは Skim / zathura / okular にフォールバック。
;;     forward search: AUCTeX の `C-c C-v'。
;;     inverse search: pdf-view-mode の `C-c C-g' (pdf-sync-minor-mode が
;;                     pdf-tools-install で自動有効化される)。
;; ============================================================
(defvar my/latex-available-p
  (and (executable-find "latexmk")
       (seq-some #'executable-find
                 '("pdflatex" "lualatex" "xelatex" "platex" "uplatex")))
  "LaTeX 環境 (latexmk + 何らかの TeX エンジン) が利用可能か。
nil の場合は AUCTeX 等の関連パッケージを一切ロードしない。
具体的なエンジン選択は ~/.latexmkrc に委ねる方針。")

(when my/latex-available-p
  ;; AUCTeX 本体 (パッケージ名は auctex / 機能名は latex, tex)
  (use-package latex
    :ensure auctex
    :mode ("\\.tex\\'" . LaTeX-mode)
    :hook
    ((LaTeX-mode . turn-on-reftex)
     (LaTeX-mode . LaTeX-math-mode)
     (LaTeX-mode . TeX-fold-mode)
     (LaTeX-mode . prettify-symbols-mode)
     (LaTeX-mode . visual-line-mode)
     (LaTeX-mode . TeX-source-correlate-mode))
    :custom
    (TeX-auto-save t)
    (TeX-parse-self t)
    (TeX-master nil)                       ; 複数ファイル文書: 都度問い合わせ
    (TeX-PDF-mode t)                       ; 出力を PDF として扱う (View 用・コンパイラフラグには影響しない)
    (TeX-source-correlate-method 'synctex) ; forward / inverse search の前提
    (TeX-source-correlate-start-server t)  ; inverse search 用 server を起動
    (reftex-plug-into-AUCTeX t)
    (font-latex-fontify-script 'multi-level)
    :config
    ;; latexmkrc 任せの最小限コマンド。
    ;; -pdf / -pdflua / -pdfdvi のような engine flag は付けない
    ;;   → pdf_mode (lualatex / pdflatex / platex+dvipdfmx 等) は
    ;;     ~/.latexmkrc が決定。
    ;; 渡しているのはエンジン非依存のオプションのみ:
    ;;   -verbose             詳細ログ (vimtex と揃える)
    ;;   -file-line-error     `file:line: msg' 形式で AUCTeX のジャンプ精度を上げる
    ;;   -synctex=1           forward / inverse search の保険 (latexmkrc 側にもある)
    ;;   -interaction=nonstopmode 対話プロンプトを抑止
    ;; add-to-list は先頭追加なので、AUCTeX 組み込みの LatexMk 定義 (もし
    ;; あれば) より優先される (TeX-command-master は assoc で先頭一致する)。
    (add-to-list 'TeX-command-list
                 '("LatexMk"
                   "latexmk -verbose -file-line-error -synctex=1 -interaction=nonstopmode %t"
                   TeX-run-TeX nil (latex-mode)
                   :help "Run latexmk (engine 選択は ~/.latexmkrc に委ねる)"))
    (setq-default TeX-command-default "LatexMk")
    (setq TeX-view-program-selection
          (cond
           ;; GUI かつ macOS/Linux: Emacs 内表示 (pdf-tools) を最優先
           ((and (display-graphic-p)
                 (memq system-type '(darwin gnu gnu/linux)))
            '((output-pdf "PDF Tools") (output-html "xdg-open")))
           ;; TTY 等のフォールバック (環境に応じて外部ビューア)
           ((eq system-type 'darwin)
            '((output-pdf "Skim") (output-html "open")))
           ((executable-find "zathura")
            '((output-pdf "Zathura") (output-html "xdg-open")))
           ((executable-find "okular")
            '((output-pdf "Okular") (output-html "xdg-open")))
           (t
            '((output-pdf "PDF Tools") (output-html "xdg-open")))))
    ;; コンパイル完了時に開いている PDF バッファを自動再読込
    (add-hook 'TeX-after-compilation-finished-functions
              #'TeX-revert-document-buffer))

  ;; 数式の高速入力 (vimtex の math snippets / surround 相当)
  (use-package cdlatex
    :hook (LaTeX-mode . turn-on-cdlatex))

  ;; Emacs 内で完結する PDF ビューア。
  ;; ・GUI かつ macOS / Linux のみ有効化 (Windows は epdfinfo ビルドが煩雑、
  ;;   TTY では描画不可)。
  ;; ・:magic で PDF ファイルを開いたとき自動的に pdf-view-mode に切替。
  ;; ・初回 PDF オープン時に epdfinfo (Poppler ベース) がビルドされる。
  ;;   - macOS: `brew install poppler automake`
  ;;   - Linux: `libpoppler-glib-dev`, `make`, `pkg-config` 等
  ;;   ビルド失敗時は AUCTeX の view が機能しないだけで他には影響なし。
  ;; ・pdf-tools-install が pdf-sync-minor-mode を自動有効化するため、
  ;;   PDF バッファ内で `C-c C-g' により inverse search (PDF→source) が可能。
  (when (and (display-graphic-p)
             (memq system-type '(darwin gnu gnu/linux)))
    (use-package pdf-tools
      :magic ("%PDF" . pdf-view-mode)
      :config
      (pdf-tools-install :no-query))))

;; custom.el を分離
(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;; ============================================================
;; Nerd Font の自動インストール
;;   Nerd Font が見つからない場合、初回起動時に自動でダウンロード&インストール。
;;   インストール後は Emacs を再起動するとアイコンが有効化される。
;;
;;   挙動:
;;   - マーカーファイル (~/.config/emacs/.nerd-fonts-installed) で試行を記録
;;   - 再試行したい場合はマーカーファイルを削除
;;   - 永続的に無効化するには (setq my/auto-install-nerd-fonts nil)
;;   - 自動実行は Linux / macOS のみ (Windows はディレクトリ選択が必要なため)
;; ============================================================
(defcustom my/auto-install-nerd-fonts t
  "Non-nil なら Nerd Font が見つからない時に自動インストールを試みる。"
  :type 'boolean
  :group 'my)

(defvar my/nerd-fonts-marker
  (locate-user-emacs-file ".nerd-fonts-installed")
  "Nerd Font 自動インストールの試行済みマーカーファイル。
このファイルを削除すれば次回起動時に再試行される。")

(defun my/install-nerd-fonts-if-missing ()
  "Nerd Font が見つからなければインストールする (初回のみ実行)。"
  (when (and my/auto-install-nerd-fonts
             (display-graphic-p)
             (not my/icons-available-p)
             (not (file-exists-p my/nerd-fonts-marker))
             ;; 自動 (=非対話) で完結する OS のみ
             (memq system-type '(gnu gnu/linux gnu/kfreebsd darwin)))
    ;; 永久ループ防止のためマーカーを先に作成
    (with-temp-file my/nerd-fonts-marker
      (insert (format "; Attempted at %s\n" (current-time-string)))
      (insert "; Delete this file to retry installation.\n"))
    (message "Nerd Font が見つかりません。自動インストール中... (~20MB ダウンロード)")
    (condition-case err
        (progn
          (require 'cl-lib)
          (require 'nerd-icons)
          ;; 万一プロンプトが出ても自動応答 (y)
          (cl-letf (((symbol-function 'y-or-n-p)    (lambda (&rest _) t))
                    ((symbol-function 'yes-or-no-p) (lambda (&rest _) t)))
            (nerd-icons-install-fonts t))
          (message
           "Nerd Font をインストールしました。Emacs を再起動するとアイコンが有効化されます。"))
      (error
       (message
        "Nerd Font 自動インストール失敗 (%s)。手動で M-x nerd-icons-install-fonts を実行可能。再自動試行するには %s を削除してください。"
        err my/nerd-fonts-marker)))))

(add-hook 'after-init-hook #'my/install-nerd-fonts-if-missing)

;; ============================================================
;; モードラインのフォント統一 & Nerd Font アイコン表示対策
;;   ・モードラインフォント揃え:  main-font が見つかったときだけ適用
;;   ・PUA フォント / 幅調整:    icon-font が見つかったときだけ適用
;; ============================================================
(when (and (display-graphic-p) my/main-font)
  (set-face-attribute 'mode-line nil
                      :family my/main-font
                      :height 170)
  (set-face-attribute 'mode-line-inactive nil
                      :family my/main-font
                      :height 170))

(when my/icons-available-p
  ;; Nerd Font アイコン領域 (PUA) を専用フォントで描画 ('prepend で最優先)
  (set-fontset-font t '(#xE000 . #xF8FF)
                    (font-spec :family my/icon-font)
                    nil 'prepend)
  ;; PUA を半角(width=1)固定にしてアイコン重なりを防止 (O(1))
  (set-char-table-range char-width-table '(#xE000 . #xF8FF) 1))

;;; init.el ends here
