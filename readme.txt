TUMIKI Fighters  readme.txt
for Windows98/2000/XP(要OpenGL)
ver. 0.2
(C) Kenta Cho

敵をくっつけ強くなる。
粘着系ぺたぺたシューティング、TUMIKI Fighters。


○ インストール方法

tf0_2.zipを適当なフォルダに展開してください。
その後、'tf.exe'を実行してください。
（マシンの速度が遅い場合は、'tf_lowres.bat'を実行してください。
  ゲームを低解像度で立ち上げます。）


○ 遊び方

 - 移動             矢印キー, テンキー, [WASD] / ジョイステック
 - ショット         [Z][左Ctrl][.]             / トリガ1, 4, 5, 8
 - スロー/引っ込め  [X][左Alt][左Shift][/]     / トリガ2, 3, 6, 7
 - ポーズ           [P]

タイトル画面でショットキーを押してゲームを開始します。

自機を操作して、敵を破壊してください。
自機は敵の破壊された破片をキャッチすることができます。
破片は自機にくっつき、敵に反撃を始めます。
多くの破片をくっつけたままにすることで、ボーナス点が入ります。
破片は敵弾に当たると破壊されます。

スローキーを押している間、自機は遅くなり、方向が固定されます。
破片は引っ込み、敵弾に破壊されることがなくなりますが、
ボーナス点は1/5になります。
このキーを押している間は、破片をくっつけることはできません。

破片を多くくっつけると、敵はより攻撃的になり多くの弾を
撃つようになります。

敵弾に当たると自機は破壊されます。
敵本体には接触しても破壊されません。

自機は200,000点および500,000点ごとに1機増えます。

以下のオプションが指定できます。
 -brightness n  画面の明るさを指定します(n = 0 - 100, デフォルト100)
 -res x y       画面の解像度を(x, y)にします。
 -nosound       音を出力しません。
 -window        ウィンドウモードで起動します。
 -reverse       ショットとスローのキーを入れ替えます。


○ ご意見、ご感想

コメントなどは、cs8k-cyu@asahi-net.or.jp までお願いします。


○ ウェブページ

TUMIKI Fighters webpage:
http://www.asahi-net.or.jp/~cs8k-cyu/windows/tf.html


○ 謝辞

TUMIKI FightersはD言語で書かれています。
 D Programming Language
 http://www.digitalmars.com/d/index.html

BulletMLファイルのパースにlibBulletMLを利用しています。
 libBulletML
 http://user.ecc.u-tokyo.ac.jp/~s31552/wp/libbulletml/

画面の出力にSimple DirectMedia Layerを利用しています。
 Simple DirectMedia Layer
 http://www.libsdl.org/

BGMとSEの出力にSDL_mixerとOgg Vorbis CODECを利用しています。
 SDL_mixer 1.2
 http://www.libsdl.org/projects/SDL_mixer/
 Vorbis.com
 http://www.vorbis.com/

D - portingのOpenGL, SDL, SDL_mixerヘッダファイルを利用しています。
 D - porting
 http://user.ecc.u-tokyo.ac.jp/~s31552/wp/d/porting.html

乱数発生器にMersenne Twisterを利用しています。
 http://www.math.keio.ac.jp/matumoto/emt.html


○ ヒストリ

2004  5/15  ver. 0.2
            引っ込め機能追加。
            ランク機能追加。破片のサイズが大きくなるほど高ランク。
            破片が破壊される範囲を敵弾が当たった場所に限定。
            自機が破壊されたときに破片が周りに飛び散るように。
            弾幕調整。
            ステージ終了時に自機が破壊される問題修正。
2004  4/11  ver. 0.11
            空中で破片がくっつく問題修正。
            ゲーム中のメッセージ修正。
            コンティニュー機能追加。
2004  4/ 3  ver. 0.1
            最初のリリースバージョン。


○ ライセンス

TUMIKI FightersはBSDスタイルライセンスのもと配布されます。

License
-------

Copyright 2004 Kenta Cho. All rights reserved. 

Redistribution and use in source and binary forms, 
with or without modification, are permitted provided that 
the following conditions are met: 

 1. Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer. 

 2. Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
