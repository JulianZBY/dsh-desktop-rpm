# dsh-desktop-rpm

DeepSeek Harness 桌面版的社区 RPM 打包(非官方)。数据源:上游 GitHub release 的官方 Linux x64 tarball,装到 `/opt/dsh-desktop`,带应用菜单入口,chrome-sandbox 以 4755 权限安装(无需 --no-sandbox)。

## 文件

| 文件 | 用途 |
|---|---|
| `dsh-desktop.spec` | RPM 打包说明,版本号宏化,上游发新版只改 `Version:` |
| `dsh.desktop` | 应用菜单入口(Wayland/X11 自动) |
| `dsh-desktop-icon.png` | 图标(取自上游仓库 resources/icon.png) |
| `copr-build.sh` | Copr custom 构建脚本:自动取上游最新版 → 改版本号 → 出 SRPM(依赖 Copr 的 `--script-builddeps rpm-build curl`)|

## 本地构建

```bash
cp dsh-desktop.spec ~/rpmbuild/SPECS/
cp SOURCES/* ~/rpmbuild/SOURCES/
rpmbuild -bb ~/rpmbuild/SPECS/dsh-desktop.spec
```

## 上线 Copr(全自动 webhook 路线,已验证走通)

前置:`sudo dnf install copr-cli`,API token 存 `~/.config/copr`(从 https://copr.fedorainfracloud.org/api/ 获取);GitHub 已 `gh auth login`。

```bash
copr-cli create --chroot fedora-44-x86_64 --description "..." dsh
copr-cli add-package-custom dsh --name dsh-desktop \
    --script ./copr-build.sh \
    --script-chroot fedora-44-x86_64 \
    --script-builddeps "rpm-build curl" \
    --webhook-rebuild on
copr-cli build-package dsh --name dsh-desktop          # 首次构建
```

然后网页一次性操作:package 页面 Webhooks 标签复制 URL → GitHub 仓库 Settings→Webhooks→Add,事件选 **Releases**。

本机接入:
```bash
sudo dnf copr enable <你的Copr用户名>/dsh
sudo dnf install dsh-desktop
```

之后上游每发新版:GitHub webhook → Copr 自动构建 → 本机 `dnf upgrade` 即可(配 dnf-automatic 可完全无人值守)。

## 已知边界

- SRPM 约 304MB,Copr 实测可收
- 上游 app 内置更新器在 Linux 上禁用,更新走包管理器,正好分工
- 图标 1104x1104 放 `/usr/share/pixmaps`,非标准 hicolor 尺寸,Copr 包可接受
- 脚本 chroot 里没有 dnf、mock 非特权,依赖只能靠 `--script-builddeps`;`COPR_RESULTDIR` 与工作目录相同时不要 cp
