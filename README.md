# 小米音乐歌词提供器

给**小米音乐（QQ音乐小米版 / `com.miui.player`）**做的词幕（Lyricon）歌词提供器，走"服务器下载"路：

hook 到当前歌曲 → 拿数字 songId → 从 QQ 音乐服务器下载已分好轨的 QRC 歌词（原文 / 翻译 / 罗马音 + 逐字）→ 交给词幕。

- 包名：`io.github.proify.lyricon.qmmiprovider`
- 当前版本：1.0.0（versionCode 1）
- 目标 App：`com.miui.player`
- 本仓库只含 `mi-music` 模块，编译需要上游项目的根构建配置，用法见「构建」

## 安装

编译好的 APK 在 [Releases](https://github.com/qingning100607/LyricProvider-mi-music/releases)。里面有两个：

| APK | 说明 |
|---|---|
| `QQMusicMiProvider-1.0.0-release.apk` | 正式版，**不写日志**， |
| `QQMusicMiProvider-1.0.0-debug.apk` | 日志版 |

步骤：

1. 安装 APK（之前如果装过签过别的 key 的同名包，先卸载，签名不同装不上去）；
2. LSPosed → 启用本模块 → **作用域勾选「音乐」(`com.miui.player`)**；
3. 强制停止小米音乐 → 重新打开，播一首歌；
4. 首次没词是正常的：先推空歌词清屏，下载完成后补上（之后走磁盘缓存）。

## 工作原理

### 触发：系统 MediaSession（不随版本失效）

```
hook android.media.session.MediaSession.setMetadata
  ├─ MEDIA_ID → 只用来判定"换歌了"（注意：它不是 songmid）
  ├─ TITLE / ARTIST / DURATION → 元数据
  └─ setPlaybackState → 转发给词幕
```

### 取 songId：

```
① 权威（不联网）
   MusicPlayerHelper.getInstance().getPlaySong() → SongInfo.getId()
   包名列表同时尝试（跨版本）：
     com.tencent.qqmusiccommon.util.music.MusicPlayerHelper    (4.46.x)
     com.tencent.qqmusiccommon.util.dialog.MusicPlayerHelper   (4.42.x)
② 兜底（联网）
   拿 TITLE + ARTIST 去 c.y.qq.com 搜索；歌名必须匹配（分数门槛），否则放弃
```

### 下载与推送

```
QrcDownloader.downloadLyrics(songId)
  → parsedLyric.richLyricLines（已分好轨：原文/翻译/罗马音 + 逐字）
  → 翻译占位符 "//" 置空
  → 纯音乐占位文档（"纯音乐，请欣赏"）不当歌词
  → 磁盘缓存后 setSong
```

歌词按语言分目录落盘：`files/lyricon/lyrics/<语言>/<songId>.json.gz`（JSON + deflate）。切歌先读缓存，没有才去下载。

## ⚠️ 维护必读：不要给 songId 做 mid 缓存

`SongInfo` 的更新**早于** `MediaSession` 里 `MEDIA_ID` 的更新。
若按 `mid → songId` 建缓存，会把"新歌的 id"记到"旧歌的 mid"上，
**表现为：切歌后显示上一首歌的歌词**（4.0.0 踩过这个坑，4.1.0 已删除该缓存）。

## 跨版本适配记录

| 版本 | 变化 | 影响 |
|---|---|---|
| 4.42.10.5 | 歌词管理器为混淆类 `se.c`，`MusicPlayerHelper` 在 `util.dialog` | 不再依赖混淆名 |
| 4.46.6.1 | `se.c` 改名；`MusicPlayerHelper` 移到 `util.music` | 包名列表已覆盖两版 |
| — | `SongInfo` 一直是 `com.tencent.qqmusic.core.song.SongInfo`，`getId()` 返回 long | 稳定 |

QQ 音乐小米版再升级时的排查顺序：

1. 装 **debug 版**，看日志 `/data/data/com.miui.player/files/lyricon_mi_debug.log`；
2. 若 `✓ 安装成功` 那行不出现 → `MusicPlayerHelper` 又换包了，反编译找新包名加到 `HELPER_CLASSES`；
3. 若出现 `SongInfo 不可用，改用搜索` → 说明走的是兜底路，检查 `SongInfo.getId()` 是否改名。

## 日志

只有 **debug 版**写日志（正式版里 `flog` 直接短路返回，不写）：

```
/data/data/com.miui.player/files/lyricon_mi_debug.log
/sdcard/Android/data/com.miui.player/files/lyricon_mi_debug.log
```

关键行：

| 日志 | 含义 |
|---|---|
| `✓ 安装成功: ...getPlaySong() x1` | 权威路线已就绪 |
| `SongInfo: id=xxx title=xxx` | 拿到当前歌曲 |
| `→ 推送 songId=xxx` | 已推给词幕 |
| `downloaded N lines` | 歌词下载成功 |
| `✗ 找不到这首歌` | 两条路都失败 |

## 构建

```bash
# 1. 克隆上游项目
git clone https://github.com/tomakino/LyricProvider.git
cd LyricProvider

# 2. 用本仓库的 mi-music 覆盖上游同名模块（上游没有的话直接拷进去）
rm -rf mi-music && cp -r /path/to/this-repo/mi-music ./

# 3. debug
./gradlew :mi-music:assembleDebug

# 4. release
./gradlew :mi-music:assembleRelease
```

release 有两个点（`proguard-rules.pro` 里已经包含第一条）：

1. `-keep class io.github.proify.lyricon.qmmiprovider.** { *; }`：R8 混淆会让 `assets/xposed_init` 里的入口类名失配，模块直接失效。
2. 某些 proot / 容器环境需要 `android.enableResourceOptimizations=false` 和 `android.enableResourceShrinking=false`，否则产出的 APK 会缺 `AndroidManifest.xml` / `resources.arsc`。

## 许可与致谢

遵循上游 Apache-2.0（见 `LICENSE`），保留原作者版权声明。

感谢 [Proify](https://github.com/proify)、[Tomakino](https://github.com/tomakino) 的 LyricProvider 与词幕。
