# 小米音乐歌词提供器

给**小米音乐（QQ音乐小米版 / `com.miui.player`）**词幕（Lyricon）歌词提供器

hook 到当前歌曲 → 拿 songId → 从 QQ 音乐服务器下载已分好轨的 QRC 歌词（原文 / 翻译 / 罗马音 + 逐字）→ 推送词幕

- 包名：`io.github.proify.lyricon.qmmiprovider`
- 当前版本：1.0.0（versionCode 1）
- 目标 App：`com.miui.player`
- 本仓库只含 `mi-music` 模块，编译需要上游项目的根构建配置，用法见「构建」

## 安装

编译好的 APK 在 [Releases](https://github.com/qingning100607/LyricProvider-mi-music/releases)。

| APK | 说明 |
|---|---|
| `QQMusicMiProvider-1.0.0-release.apk` | 正式版，**无日志**， |
| `QQMusicMiProvider-1.0.0-debug.apk` | 日志版 |

步骤：

1. 安装 APK
2. LSPosed → 启用本模块 → **作用域勾选「音乐」(`com.miui.player`)**

## 工作

### 触发：系统 MediaSession

```
hook android.media.session.MediaSession.setMetadata
  ├─ MEDIA_ID → 判定"切歌"
  ├─ TITLE / ARTIST / DURATION → 元数据
  └─ setPlaybackState → 推送词幕
```

### 取 songId：

```
① 
   MusicPlayerHelper.getInstance().getPlaySong() → SongInfo.getId()
   包名列表同时尝试（跨版本）：
     com.tencent.qqmusiccommon.util.music.MusicPlayerHelper    (4.46.x)
     com.tencent.qqmusiccommon.util.dialog.MusicPlayerHelper   (4.42.x)
② 
   拿 TITLE + ARTIST 去 c.y.qq.com 搜索；歌名必须匹配（分数门槛），否则放弃
```

### 下载与推送

```
QrcDownloader.downloadLyrics(songId)
  → parsedLyric.richLyricLines（已分轨：原文/翻译/罗马音 + 逐字）
  → 翻译占位符 "//" 置空
  → 纯音乐占位文档
  → 磁盘缓存后 setSong
```

歌词按语言分目录落盘：`files/lyricon/lyrics/<语言>/<songId>.json.gz`（JSON + deflate）。切歌先读缓存，没有才去下载。

## 维护：勿 songId 做 mid 缓存

`SongInfo` 的更新**早于** `MediaSession` 里 `MEDIA_ID` 的更新。
若按 `mid → songId` 建缓存，会把"新歌的 id"记到"旧歌的 mid"上，
**表现为：切歌后显示上一首歌的歌词**

## 跨版本记录

| 版本 | 变化 | 影响 |
|---|---|---|
| 4.42.10.5 | 歌词管理器为混淆类 `se.c`，`MusicPlayerHelper` 在 `util.dialog` | 不再依赖混淆名 |
| 4.46.6.1 | `se.c` 改名；`MusicPlayerHelper` 移到 `util.music` | 包名列表已覆盖两版 |
| — | `SongInfo` 是 `com.tencent.qqmusic.core.song.SongInfo`，`getId()` 返回 long | 稳定 |

## 日志

 **仅debug**输出日志路径：

```
/data/data/com.miui.player/files/lyricon_mi_debug.log
/sdcard/Android/data/com.miui.player/files/lyricon_mi_debug.log
```

关键行：

| 日志 | 含义 |
|---|---|
| `✓ 安装成功: ...getPlaySong() x1` | 路线已就绪 |
| `SongInfo: id=xxx title=xxx` | 拿到当前歌曲 |
| `→ 推送 songId=xxx` | 已推送词幕 |
| `downloaded N lines` | 歌词下载成功 |
| `✗ 找不到这首歌` | 失败 |

## 构建

```bash
# 1. 克隆上游项目
git clone https://github.com/tomakino/LyricProvider.git
cd LyricProvider

# 2. 用本仓库的 mi-music 覆盖上游同名模块
rm -rf mi-music && cp -r /path/to/this-repo/mi-music ./

# 3. debug
./gradlew :mi-music:assembleDebug

# 4. release
./gradlew :mi-music:assembleRelease
```


## 许可与致谢

遵循上游 Apache-2.0（见 `LICENSE`），保留原作者版权声明。

感谢 [Proify](https://github.com/proify)、[Tomakino](https://github.com/tomakino) 的 LyricProvider 与词幕。
