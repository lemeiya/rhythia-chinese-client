# Rhythia 中文客户端版

**English name:** Rhythia Chinese Client Edition  
**Short name:** Rhythia-CC

Rhythia 中文客户端版是基于 [Sound Space Plus / Rhythia](https://github.com/David20122/sound-space-plus) 的独立第三方客户端版本，面向中文玩家提供本地化界面、客户端功能改进和社区服务接入能力。

本公开仓库只包含客户端及其运行所需的公开资源，不包含社区服务器或社区网站。

## 开源范围

本仓库不发布以下内容：

- 社区服务器源码和 PHP 服务端
- 社区网站、管理后台和 API 实现
- 社区数据库结构、生产数据和部署脚本
- Resend API Key、数据库密码、域名配置和其他生产密钥
- 用户上传的音乐、谱面、头像和社区内容

社区服务由项目维护者独立部署和运营，客户端只通过配置的 API 地址访问服务。服务端相关内容不属于本公开仓库的分发范围。

## 客户端功能

- 中文本地化界面
- SSPM v1/v2 谱面加载与导入
- 本地歌曲、回放和自定义内容管理
- Windows x86_64 客户端构建支持
- 可选的在线社区内容访问能力

## 中文社区

访问 [Rhythia 中文社区](https://rhythia.fastmay.top/) 获取社区动态、谱面和其他中文社区内容。

## 开发环境

项目使用 Godot 4.3，请从 Godot 官网安装对应版本。

解析项目：

```powershell
godot --headless --path . --editor --quit
```

## 用户数据

游戏用户数据位于 Godot 的 `user://SoundSpacePlus` 目录，包含本地设置、回放、谱面缓存和其他个人数据。更新客户端时请勿删除该目录。

## 项目结构

```text
scripts/        Godot 游戏逻辑
scenes/         Godot 场景
assets/         游戏资源
prefabs/        可复用场景组件
localization/   本地化资源
```

## 许可与版权

本项目基于上游 [Sound Space Plus / Rhythia](https://github.com/David20122/sound-space-plus) 修改。上游项目采用 MIT License，发布时应保留原作者版权声明和许可证文本。

本仓库新增的中文本地化和客户端修改属于本项目新增内容。第三方插件、Discord SDK、字体、音乐、谱面、图片和其他素材仍以各自许可证或授权范围为准，不因本项目使用 MIT License 而自动获得重新授权。

## 非官方声明

Rhythia 中文客户端版是独立第三方项目，与原作者、CAPO Games、rhythia.com 及其他相关商业主体无隶属、代理或官方合作关系。除非另有书面授权，本项目不授予任何商标或品牌使用权。

## 贡献

欢迎提交客户端代码和中文本地化的 Issue 或 Pull Request。提交代码或资源前，请确认其许可证允许在本项目中使用和再分发。
