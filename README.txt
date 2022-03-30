【DVB driver for SKnet MonsterTV HD series】                  v0.3  2009.11.22

SKnet MonsterTV HD シリーズ (HDUS/HDP/HDP2/HDUC/HDU2 等) を Linux 上で使う
ための DVB ドライバです．
既に recfriio の対応版が出ていますが，このドライバは以下のような特徴があり
ます．
  - タイミングクリティカルな USB の制御は kernel 空間で処理
  - ASIE5606(B) のローカル暗号 (XOR/DES) はドライバ内で処理
    ARIB B25 (B-CAS) の処理はユーザ空間アプリで
  - 標準的な DVB-T 対応アプリを使用可
    ただし視聴のためには ARIB B25 対応のアプリが必要
  - ２チューナー版 (HDP2/HDU2) や複数デバイスの同時使用可
  - リモコンを input device として使用可
  - ASV5211 のファームダウンロード機能を包含

[できないこと]
  - 内蔵 B-CAS カードの使用
    (アクセス方法の詳細不明のため．方法が判明すれば将来的には CA ドライバと
    して組み込むことも可能かも…)
  - ASV5211 内蔵の PID filter の使用
    (これもやり方が判れば将来的には組み込めるかも…)
  - ASIE5607 (新版) のローカル暗号処理

kernel ドライバのため，recfriio 等よりは敷居が高くなっています．
ビルド方法等が判らない人は素直に recfriio 等を使った方が無難です．


■  動作確認済みの環境

    Debian GNU/Linux 5.0 (lenny)
      kernel 2.6.26 (linux-image-2.6.26-2-686 2.6.26-19lenny2)
      kernel 2.6.30 (linux-image-2.6.30-bpo.2-amd64 2.6.30-8~bpo50+1)
      kernel 2.6.31 (自前コンパイル)
      ユーザランドは 32bit (DVB_API_VERSION = 3)
    MonsterTV HDP2
    MonsterTV HDUC
    ※ HDUS や HDP 等の缶チューナー版・未対策版 (ローカル暗号が XOR) に
       ついては，手元に実物が無いため一切の動作確認はしていません．


■  このアーカイブの内容

    dvb-mtvhd/README.txt     このファイル
    dvb-mtvhd/driver/        DVB ドライバソース＆パッチ
    dvb-mtvhd/tools/         ファームウェア生成ツール


■  ドライバのビルド＆インストール

0.  カーネルモジュールのコンパイル環境をインストールしておく
    Debian ならば linux-headers-2.6-686 パッケージ等．

1.  v4l-dvb のソースの入手・展開
    最新 or 2009年11月15日時点の v4l-dvb ソースコードを入手する．

    a)  Mercurial を使って最新のソースを check out する方法
        0)  あらかじめ mercurial をインストールしておく
        1)  適当なワークディレクトリへ移動し以下を実行
              hg clone http://linuxtv.org/hg/v4l-dvb

    b)  2009年11月15日時点のソースを入手する方法
        1)  以下のファイルを入手
            http://linuxtv.org/hg/v4l-dvb/archive/8bff7e6c44d4.tar.bz2
        2)  適当なワークディレクトリへ移動して展開
            tar jxf 8bff7e6c44d4.tar.bz2
        3)  後々のためにディレクトリ名をリネーム
            mv v4l-dvb-8bff7e6c44d4 v4l-dvb

    一度入手・展開後は以下のコマンドで最新にアップデート可能．
      $ cd v4l-dvb
      $ hg pull -u

    その他入手方法等は http://www.linuxtv.org/repo/ を参照してください．

    以降では，本アーカイブを展開した dvb-mtvhd/ をワークディレクトリとし，
    配下に v4l-dvb のソースも展開されていることを前提とします．cd コマンド等
    の起点も dvb-mtvhd/ からを前提にします．
       dvb-mtvhd/driver   本アーカイブ内のドライバソース
       dvb-mtvhd/v4l-dvb  ステップ 1 で入手した v4l-dvb ソース

2.  MonsterTV HD 用ソースコードのコピー＆パッチ適用

    1)  MonsterTV HD 用ソースコードのコピー
        $ cp -p driver/*.[ch] v4l-dvb/linux/drivers/media/dvb/dvb-usb

    2)  パッチの適用
        $ cd v4l-dvb
        $ patch -p1 <../driver/dvb-mtvhd.diff

    2009年11月15日時点のソースならば確実にパッチは当たりますが，パッチは以下の
    ファイルだけなので，それ以降の版でも v4l-dvb に大幅な変更が無い限りは
    dvb-mtvhd.diff を見ながらのマニュアルパッチは可能でしょう．
      v4l-dvb/linux/drivers/media/dvb/dvb-usb/Kconfig
      v4l-dvb/linux/drivers/media/dvb/dvb-usb/Makefile
      v4l-dvb/linux/drivers/media/dvb/dvb-usb/dvb-usb-ids.h

3.  ドライバのビルド
    現在使用中の kernel 用のビルドを想定しています．

    0)  Cleanup
        以前に別バージョンのカーネル用のビルドしていたら以下を実施．
        $ cd v4l-dvb
        $ make distclean
        これにより次項の v4l-dvb/v4l/.config が消えてしまうので，必要に応じて
        どこかに待避．

    1)  ビルド対象モジュールの選択
        v4l-dvb/v4l/.config にビルド対象モジュールや各種設定を指定する．
        (設定内容の詳細は後述．ファームウェアダウンロード方法次第で要設定変更)

        a)  テキストエディタ等で以下のような内容のファイルを直接作成する方法
            (driver/config に同内容のファイルがあるので，コピーしても OK)
CONFIG_MEDIA_SUPPORT=m
CONFIG_DVB_CORE=m
CONFIG_DVB_USB=m
CONFIG_DVB_USB_DEBUG=y
CONFIG_DVB_USB_MTVHD=m
CONFIG_DVB_USB_MTVHD_V1=y
CONFIG_DVB_USB_MTVHD_V2=y
CONFIG_DVB_USB_MTVHD_REMOTE_CONTROL=y
CONFIG_DVB_USB_ASV5211=m
# CONFIG_DVB_USB_ASV5211_WIN_DRIVER is not set

        b)  インタラクティブに (Y/N で回答しながら) 指定する方法
            $ cd v4l-dvb
            $ make config

        c)  コンソール上のテキストメニューで指定する方法
            $ cd v4l-dvb
            $ make menuconfig

        d)  qt ベースの GUI 上のテキストメニューで指定する方法
            $ cd v4l-dvb
            $ make xconfig

    2)  ビルド
        $ cd v4l-dvb
        $ make

4.  モジュールのインストール
    root 権限にてモジュールのインストールを行います．

    1)  インストール先ディレクトリの作成
        # mkdir /lib/modules/`uname -r`/extra
        ※  Debian 等では自前モジュール用のディレクトリがないので作成．
            Fedora 等では既にあるのでスキップ．

    2)  モジュールのコピー
        # cd v4l-dvb/v4l
        # cp -p dvb-core.ko dvb-usb.ko dvb-usb-asv5211.ko dvb-usb-mtvhd.ko /lib/modules/`uname -r`/extra

    3)  モジュールのインストール先ディレクトリを優先的に検索するように設定
        /etc/depmod.conf を修正・作成して優先的に検索するように指定．
        たとえば以下のような内容を指定．(see man depmod.conf)
# override default search ordering
search updates extra built-in weak-updates

        ※  Debian では必須．これをやらないと kernel に含まれる dvb-core や
            dvb-usb モジュールが優先的に使われてしまう．
            Fedora 等では上記設定をしなくてもディフォルト状態で extra 配下を
            優先的に検索するようにカスタマイズされているらしいのでスキップ．

    4)  モジュールの依存関係を更新
        # depmod -a


■  ASV5211 ファームウェアのダウンロード方法

旧来の方法も含め，いくつか方法があります．
以下のいずれの方法でも可能ですが，d) の方法を推奨します．

a)  [旧来] デュアルブートの PC で一旦 Windows を起動した後リブートする
    Windows のドライバでダウンロードする方法．

b)  [旧来] as11loader コマンドを使用
    recfriio の HDUS パッチに含まれる as11loader を使用．
    udev 等により自動的にダウンロードするように設定している場合，本ドライバの
    ダウンロード機能と競合しないように，前期ビルド時のモジュール選択の際に以下
    のように ASV5211 モジュールを作成しないように指定する．
# CONFIG_DVB_USB_ASV5211 is not set
    (或いは dvb-usb-asv5211.ko をインストール先へコピーしない)

c)  Windows 用ドライバのファイルを使用
    以下のうちいずれかのファイルを使い，ドライバ内に含まれているコードをダウン
    ロードする．
      - MTVHDU_080701_Drv に含まれる SKNET_AS11Loader.sys
      - 他製品向け (KWorld-UB320i 等) の特定バージョンの AS11Loader.sys
    特定バージョンのドライバを何とか入手する必要があるが，旧来のやり方 (b) に
    慣れている人は楽かも…．
    ドライバファイルは以下の場所に以下の名前でコピー．
      /lib/firmware/AS11Loader.sys
    この方法を使用する場合，ビルド時の設定で v4l-dvb/v4l/.config に以下のように
    指定する必要がある．
CONFIG_DVB_USB_ASV5211=m
CONFIG_DVB_USB_ASV5211_WIN_DRIVER=y

d)  独自形式のファームウェアファイルを使用
    本ドライバ独自形式のファームウェアファイルを使用してダウンロードする．
    少し面倒だが，最新の Windows ドライバの USB capture log を利用して最新の
    ファームウェアを使用可能．
    以下に UsbSnoop による USB capture log を使用したファームウェアファイル
    作成方法を示す．

      0)  Windows 上で UsbSnoop により ASV5211 (VID=1738 PID=5211) の USB
          capture log を採取する．
          或いはどこかから USB capture log を調達する．(up0451.zip 等)
          以下，採取したファイル名を as11loader.log とする．

      1)  本アーカイブ内に含まれている変換ツールにより，ファームウェアファイル
          を生成する．(生成するファームウェアのファイル名は dvb-usb-asv5211.fw)
          $ cd tools
          $ perl asv5211fw-gen.pl as11loader.log >asv5211fw.c
          $ gcc -o asv5211fw asv5211fw.c
          $ ./asv5211fw dvb-usb-asv5211.fw

      2)  (root 権限で) 生成したファームウェアファイルを /lib/firmware 配下に
          置く．
          # cp dvb-usb-asv5211.fw /lib/firmware

    この方法を使用する場合，ビルド時の設定で v4l-dvb/v4l/.config に以下のように
    指定する必要がある．(前述のビルド方法に記載した指定と同じ)
CONFIG_DVB_USB_ASV5211=m
# CONFIG_DVB_USB_ASV5211_WIN_DRIVER is not set


■  カーネルモジュールのロード

USB の抜き挿しやリブート・電源 Off/On を行う場合には自動的にロードされるため，
特別なことは不要です．
マニュアルでロードしたい場合には以下のいずれかによりロードさせます．
(いずれも root 権限で…)

A)  ASV5211 ファームのダウンロードをドライバで行う場合
    # modprobe dvb_usb_asv5211

B)  既に別の方法でファームウェアがダウンロード済みの場合
    # modprobe dvb_usb_mtvhd

なお，今後本ドライバによりファームウェアのダウンロードを行う場合 (ダウンロード
方法 a や b) には，既に udev 等で自動ダウンロード指示をしていると競合して異常
となる可能性があるため，そのような設定を外してください．
udev 等で USB デバイスのパーミッションを変更しているような場合も，recfriio 等の
USB をダイレクトにアクセスするアプリを併用しない限り，このような設定は不要と
なります．


■  ユーザ空間アプリケーション

一般的な DVB-T 向けのアプリケーションが動きます．
ただし，視聴のためには ARIB B25 のスクランブル解除処理をどこかの段階で行う必要
があります．


■  リモコン

HDU 系 (HDUS/HDUC 等 USB 接続版) では，リモコンが input device として登録され
ます．HDP 系 (HDP/HDP2 等 PCI 接続版) では，ディフォルトでは input device を
登録しません (後述のモジュールパラメータで挙動変更可)．

/dev/input/event? あるいは /dev/input/by-path/pci-?-?-event-ir 経由でアクセス
可能なはずです．


■  制限事項・To Do

  - 安定度のテストはしていません．恐らくは不安定なところがあるでしょう．

  - DVB API のいくつかのインプリメントは適当です．
    FE_READ_SIGNAL_STRENGTH や FE_READ_STATUS 等．
    このあたりは既存の recfriio 等のコードでは参考になるものがないため，
    Windows のドライバの USB capture log を見てだいたいの解析をしています．

  - DVB API の FE_READ_SNR (に限らず FE_READ_SIGNAL_STRENGTH 等もですが…) は
    返す値の形式が決まっていません．S/N 比の計算の仕方自体はほぼ正しそうな感触
    ですが，値の表現は他のドライバとの互換はありません．
    本ドライバでは dB 値を 256 倍した値を返しているつもりです．
    (uint16_t の上位 8bit が dB 値の整数部になる)

  - リモコンの input device としての挙動は未確認です．
    debug 出力により，ドライバとして想定通り動いていることは確認済みですが，
    実際にどう使うかまでは試していません．
    また，リモコンボタンと key event の対応がこれで妥当かどうかも微妙です．


■  モジュールビルド時のモジュール選択・設定

  - CONFIG_DVB_USB_DEBUG
    Enable extended debug support for all DVB-USB devices
    これを y にしないと debug メッセージが一切出力されない．

  - CONFIG_DVB_USB_MTVHD
    SKNET MonsterTV HD ISDB-T support
    m を指定．

  - CONFIG_DVB_USB_MTVHD_V1
    Version 1 of SKNET MonsterTV HD series support
    HDUS/HDP 等のいわゆる缶チューナ版をサポートするか否か．

  - CONFIG_DVB_USB_MTVHD_V2
    Version 2 of SKNET MonsterTV HD series support
    HDUC/HDU2/HDP2 等のいわゆるシリコンチューナ版をサポートするか否か．

  - CONFIG_DVB_USB_MTVHD_REMOTE_CONTROL
    IR remote controller for SKNET MonsterTV HD
    リモコン (input device) 動作をサポートするか否か．

  - CONFIG_DVB_USB_MTVHD_DES_KERNEL
    Use crypto_des library of Linux kernel
    DES の decryption 処理を Linux kernel の crypto_des ライブラリを使うように
    する指定．
    現状ではまともに動いていないので通常は指定しないこと．
    もし指定する場合には，v4l-dvb/linux/drivers/media/dvb/dvb-usb/Kconfig を
    修正して
      depends on BROKEN
    の行を削除する必要がある．

  - CONFIG_DVB_USB_ASV5211
    Firmware downloader for ASICEN ASV5211
    ASV5211 のファームウェアダウンロードをドライバで行うか否か．

  - CONFIG_DVB_USB_ASV5211_WIN_DRIVER
    Use Windows driver file for ASV5211 firmware
    特定バージョンの Windows ドライバをファームウェアファイルとして扱う．


■  モジュールパラメータ

a.  指定方法

    A)  /etc/modprobe.d/ 配下にファイルを置き，以下のような指定をする．
          options dvb_usb_mtvhd debug=1
        モジュールのロード時に指定が有効になる．
        man modprobe.conf 参照．

    B)  root 権限で以下のように指定する．
          # echo 1 >/sys/module/dvb_usb_mtvhd/parameters/debug
        指定したタイミング以降有効になる．

    C)  マニュアルでモジュールをロードする際に指定する．
          # modprobe dvb_usb_mtvhd debug=1

b.  パラメータの種類

  - debug
    dmesg や /var/log/messages に debug メッセージを出力するための指定．
      1  err  - エラー時の詳細
      2  info - 実行時の各種情報
      4  xfer - USB 上の転送トランザクション (大量に出力されるので注意)
      8  rc   - リモコンの動作
    数字は OR 指定可能．err と rc を同時に指定したいなら 9 を指定．

  - enable_hdp_rc
    HDP/HDP2 等の PCI 系のチューナーでリモコン動作を有効にする．(1 を指定)
    このパラメータはモジュールのロード時に指定する必要がある．
    (後で /sys/module/dvb_usb_mtvhd/parameters/enable_hdp_rc を書き換えても
    有効とはならない)


■  内部事情

a.  driver/ 配下の各ファイルの役割分担等
    ちょっとファイル数が多いが，この方がメンテしやすいので…．

  - mtvhd.c
    メイン部．DVB ドライバの登録・リモコン処理・共通のサブルーチン．
    mtvhd_rc_keys[] のエントリを変更することで NEC プロトコル互換の家電のリモ
    コンを扱うことも可能．一例として手元にあった東芝のテレビのリモコンの設定を
    コメント (#if 0) 内に記載．モジュールパラメータで debug=8 を指定してリモ
    コンの動作をメッセージ出力させると，このあたりの情報が得られる．

  - mtvhd-v1.c
    いわゆる缶チューナ版の Frontend 制御部．

  - mtvhd-v2.c
    いわゆるシリコンチューナ版の Frontend 制御部．

  - mtvhd-stream.c
    ストリーム受信後の後処理．いわゆるローカル暗号処理のスケジュール部分．
    どの種類の暗号処理かにより適当な decrypt 処理へ受け渡しをする．
    friio-dvb-0.2 の swbcas のやり方を参考にした．

  - mtvhd-des-gnulib.c
    暗号アルゴリズムが DES の場合の packet decrypt 処理．
    Gnulib の DES ライブラリを使用している．
    固定の鍵でずっと動かしている割にちょっと無駄な部分があるが，kernel の DES
    ライブラリを使う場合とできるだけ近い形にしたかったためにこうなっている．
    暗号用のコンテキストを引数に持つ形にしているので，将来的に暗号鍵が動的に
    変わるような方式にも拡張できるはず．
    Gnulib を使う…ということに気づかせてくれたのは FUKAUMI Naoki さんの BSD
    版のおかげ．

  - des.*
    Gnulib の DES ライブラリ．
    Kernel モジュールとしてコンパイルできるように #include のところだけ修正．

  - mtvhd-des-kernel.c
    暗号アルゴリズムが DES の場合の packet decrypt 処理．
    Linux kernel の crypto_des ライブラリを使用している．
    ライブラリ的には中間鍵は Gnulib と同じで問題ないことは確認済みだが，何故か
    現状ではまともに動いていない．中間鍵を無理矢理設定しているところが悪いのか
    呼び出し方等が悪いのかは不明．
    kernel の DES ライブラリは呼び出しにちょっとオーバーヘッドがあるが，
    モジュール的にはすっきりするので，誰かなんとかしてください．

  - mtvhd-xor.c
    暗号アルゴリズムが XOR の場合の packet decrypt 処理．
    これを使うようなチューナーを持っていないので，動作は未確認．

  - asv5211.*
    ASV5211 ファームウェアダウンローダ．
    as11loader 等の既存ツールによるダウンロードを継続使用したい人のため，別
    モジュールとした．
    as11loader を使っていた人が移行しやすいように Windows ドライバを使った
    やり方も含めているが，最終的には外したい気もする．

b.  戯言戯れ言
    先人たちの解析・偉業には大変感謝しています．
    ただ，DVB ドライバにするにあたっては，USB ログや実験を基に自分なりに解釈し
    直してコード化しています．このため，ライセンスは次項のようにさせてください．


■  ライセンス等

a.  driver/ 配下
    GPL v2+ に従う．
    Gnulib の DES ライブラリについても同様 (GPL v2+) ですが，詳細は以下を参照
    してください．
      http://www.gnu.org/software/gnulib/
    v4l-dvb のメインツリーにマージしたいという奇特な方がいらっしゃったら，
    ご随意に…

b.  tools/ 配下
    パブリックドメイン．
    基本的にサンプルコードなので，as-is で使ってください．


■  変更履歴

v0.3  2009.11.22
  a)  V2 (シリコンチューナー版) の S/N (C/N) 改善．(up0443.zip)
  b)  .frequency_min / .frequency_max の誤り訂正．
  c)  delivery_system を SYS_ISDBT になるように．(friio のやり方を参考)
  d)  V4L-DVB の差分のベースを 2009年11月15日時点のソースに．
      後のマージを楽にするように，最後ではなく friio の後に入れた．
  e)  recisdbt の同梱をやめた．(自分の手を離れるのを期待して…)

v0.2  2009.10.24
  a)  V1 (缶チューナー版) のチューナー初期化パラメータの誤記訂正．
  b)  V2 のチューナーの初期化・設定方法を改善．
      ダブルチューナー版 (HDP2/HDU2) の同時使用時の S/N 改善．
  c)  V1 の PCI 版 (HDP) のリモコンの扱いを V2 と合わせた．
  d)  V4L-DVB の差分のベースを 2009年10月20日時点のソースに．

v0.1  2009.10.12
      初版
