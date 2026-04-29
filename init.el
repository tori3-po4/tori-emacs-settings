;;; init.el --- Portable Emacs config -*- lexical-binding: t; -*-

;;UI系の設定
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(setq ring-bell-function 'ignore)

;; ミニバッファの高さを制限(画面の25%まで)
(setq max-mini-window-height 0.25)

;; もしくは伸縮自体を止める(長文は切れるので注意)
;; (setq resize-mini-windows nil)

;;ディスプレイサイズの変更
(when (display-graphic-p)
  (add-to-list 'default-frame-alist '(width . 110))
  (add-to-list 'default-frame-alist '(height . 42)))

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
     "DejaVu Sans Mono" ; 多くの Linux に同梱
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
                      :height 200)
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
  (doom-modeline-height 32)
  :custom-face
  (mode-line          ((t (:box (:line-width 6 :color "#7aa2f7")))))
  (mode-line-inactive ((t (:box (:line-width 6 :color "#414868")))))
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
(use-package highlight-indent-guides
  :diminish
  :hook
  ((prog-mode yaml-mode) . highlight-indent-guides-mode)
  :custom
  (highlight-indent-guides-auto-enabled t)
  (highlight-indent-guides-responsive   t)
  (highlight-indent-guides-method 'character))

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

;; 余白でモダンな見た目に
(use-package spacious-padding
  :hook
  (after-init . spacious-padding-mode)
  :custom
  (spacious-padding-widths
   '( :internal-border-width 15
      :header-line-width 4
      :mode-line-width 6
      :tab-width 4
      :right-divider-width 20
      :scroll-bar-width 8
      :fringe-width 8)))


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

;; which-key をフロート表示 (GUI 必須)
(use-package which-key-posframe
  :if (display-graphic-p)
  :after which-key
  :custom
  (which-key-posframe-poshandler 'posframe-poshandler-frame-bottom-center)
  (which-key-posframe-border-width 1)
  (which-key-posframe-parameters
   '((left-fringe . 8)
     (right-fringe . 8)))
  :custom-face
  (which-key-posframe-border ((t (:background "#bb9af7"))))
  :config
  (which-key-posframe-mode 1))

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

;; vertico をフロート表示 (GUI 必須)
(use-package vertico-posframe
  :if (display-graphic-p)
  :after vertico
  :config
  (vertico-posframe-mode 1))


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
  :custom
  (eat-kill-buffer-on-exit t))

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
                      :height 200)
  (set-face-attribute 'mode-line-inactive nil
                      :family my/main-font
                      :height 200))

(when my/icons-available-p
  ;; Nerd Font アイコン領域 (PUA) を専用フォントで描画 ('prepend で最優先)
  (set-fontset-font t '(#xE000 . #xF8FF)
                    (font-spec :family my/icon-font)
                    nil 'prepend)
  ;; PUA を半角(width=1)固定にしてアイコン重なりを防止 (O(1))
  (set-char-table-range char-width-table '(#xE000 . #xF8FF) 1))

;;; init.el ends here
