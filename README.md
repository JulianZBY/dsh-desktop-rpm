# dsh-desktop-rpm

DeepSeek Harness 桌面版的社区 RPM 打包(非官方)。数据源:上游 GitHub release 的官方 Linux x64 tarball,装到 `/opt/dsh-desktop`,带应用菜单入口,chrome-sandbox 以 4755 权限安装(无需 --no-sandbox)。

## 文件

| 文件 | 用途 |
|---|---|
| `dsh-desktop.spec` | RPM 打包说明,版本号宏化,上游发新版只改 `Version:` |
| `dsh.desktop` | 应用菜单入口(Wayland/X11 自动) |
| `dsh-desktop-icon.png` | 图标(取自上游仓库 resources/icon.png) |
| `copr-build.sh` | Copr custom 构建脚本:自动取上游最新版 → 改版本号 → 出 SRPM |

## 本地构建

```bash
cp dsh-desktop.spec ~/rpmbuild/SPECS/
cp SOURCES/* ~/rpmbuild/SOURCES/
rpmbuild -bb ~/rpmbuild/SPECS/dsh-desktop.spec
```

## 上线 Copr(全自动 webhook 路线)

1. 把 `copr-build.sh` 里的 `YOUR_GITHUB_USERNAME` 换成你的 GitHub 用户名
2. GitHub 建仓库(如 `dsh-desktop-rpm`),push 本目录
3. 登录 [Copr](https://copr.fedorainfracloud.org/),新建项目(如 `dsh`),勾选 fedora-4X-x86_64 chroot
4. 项目里 Packages → Create package:名称 `dsh-desktop`,source method 选 **Custom**,Script URL 填:
   `https://raw.githubusercontent.com/<你的用户名>/dsh-desktop-rpm/main/copr-build.sh`
5. 在该 package 页面复制 **Webhook URL** → GitHub 仓库 Settings → Webhooks → Add webhook:粘贴 URL,Content type `application/json`,触发事件选 **Releases**
6. 本机接入:
   ```bash
   sudo dnf copr enable <你的Copr用户名>/dsh
   sudo dnf install dsh-desktop
   ```

之后上游每发新版:GitHub webhook → Copr 自动构建 → 本机 `dnf upgrade` 即可(配 dnf-automatic 可完全无人值守)。

## 已知边界

- SRPM 约 306MB,若超出 Copr 单包限额构建会被拒,届时改走本地构建 + copr-cli 上传
- 上游 app 内置更新器在 Linux 上禁用,更新走包管理器,正好分工
- 图标 1104x1104 放 `/usr/share/pixmaps`,非标准 hicolor 尺寸,Copr 包可接受
