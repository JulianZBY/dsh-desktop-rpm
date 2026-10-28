# dsh-desktop-rpm

DeepSeek Harness 桌面端(anywhere-labs 社区项目)的社区 RPM 打包。跟踪上游 **next 频道**,装到 `/opt/dsh-desktop`,带应用菜单入口,chrome-sandbox 以 4755 权限安装(无需 --no-sandbox)。

## 安装(社区 Copr 仓库,Fedora)

```bash
sudo dnf copr enable julianzby/dsh
sudo dnf install dsh-desktop --refresh
```

升级:`sudo dnf upgrade dsh-desktop --refresh`。

## 为什么是 next 频道

上游 2.0.18 stable 的全部 Linux 产物(tar.gz/AppImage/deb)都缺少捆绑的 primary runtime(`resources/runtime/` 整个不存在,疑似 `prepare:runtime` 备料在 linux 管线上未执行),装机态首启即报 `the bundled primary runtime is missing` 进入 Recovery。next(2.0.19-next)实测不依赖捆绑 runtime,解包即用,故本包跟踪 next。

回 stable 的方法:git 历史里有 2.0.18 版 spec/脚本(commit `5355079` 之前),且需自行解决 runtime(见下文"止血")。

## 文件

| 文件 | 用途 |
|---|---|
| `dsh-desktop.spec` | RPM 打包说明。`Version: 2.0.19~next`(RPM 不允许 `-`,prerelease 惯例用 `~`),上游 tag 版本由 `%global upstream_ver` 单独维护 |
| `dsh.desktop` | 应用菜单入口(Wayland/X11 自动),Exec 指向 `dsh-desktop-next` |
| `dsh-desktop-icon.png` | 图标(取自上游仓库 resources/icon.png) |
| `copr-build.sh` | Copr custom 构建脚本:`git ls-remote` 探测最新 next tag → 下载 tarball → 改 spec 版本 → 出 SRPM |

## 本地构建

```bash
cp dsh-desktop.spec ~/rpmbuild/SPECS/
cp dsh.desktop ~/rpmbuild/SOURCES/
cp SOURCES/DSH-NEXT-*-linux-x64.tar.gz ~/rpmbuild/SOURCES/   # 从上游 release 下载对应版本
rpmbuild -bb ~/rpmbuild/SPECS/dsh-desktop.spec
```

## 上线 Copr(全自动 webhook 路线,已验证)

前置:`sudo dnf install copr-cli`,API token 存 `~/.config/copr`(从 https://copr.fedorainfracloud.org/api/ 获取);GitHub 已 `gh auth login`。

```bash
copr-cli create --chroot fedora-44-x86_64 --description "..." dsh
copr-cli add-package-custom dsh --name dsh-desktop \
    --script ./copr-build.sh \
    --script-chroot fedora-44-x86_64 \
    --script-builddeps "rpm-build curl git" \
    --webhook-rebuild on
copr-cli build-package dsh --name dsh-desktop          # 首次构建
```

然后网页一次性操作:package 页面 Webhooks 标签复制 URL → GitHub 仓库 Settings→Webhooks→Add,事件选 **Releases**。

本机接入:
```bash
sudo dnf copr enable <你的Copr用户名>/dsh
sudo dnf install dsh-desktop --refresh
```

## 已知边界与坑(全部实测踩过)

- 脚本 chroot 里**没有 dnf、mock 非特权**,装依赖只能靠 `--script-builddeps`
- `COPR_RESULTDIR` 与工作目录相同时不要 cp(同文件复制报错)
- `${VAR/-/~}` 的 `~` 在参数展开替换串里会被 **tilde 展开**(Copr 里 `$HOME=/builddir`),必须写 `\~`
- 探版本不要走 api.github.com(匿名限流 403),用 `git ls-remote --tags` 直接读 git
- grep `-m1` 只限"行"不限"匹配",单行 JSON 会吐出全部匹配,取最新要 `sort -V | tail -1`
- 捆绑的 sherpa-onnx.node 带上游 CI runpath 残留,spec 必须 `%global __brp_check_rpaths %{nil}`
- `SOURCES/` 在 .gitignore 里,要分发的文件(图标)需 `git add -f`
- 图标 1104x1104 放 `/usr/share/pixmaps`,非标准 hicolor 尺寸,Copr 包可接受

## 止血记录(stable 2.0.18 专用,当前不需要)

若使用 2.0.18 stable 且首启报 `the bundled primary runtime is missing`:把一份 linux x64 primary runtime payload(含 `runtime.json`、`dependencies/{node,python}`)放到 `/opt/dsh-desktop/resources/runtime/x64/primary-runtime` 即可正常引导。环境变量 `DSH_DESKTOP_PRIMARY_RUNTIME_DIR` 理论可重定向,但实测崩溃→Recovery 重启链路会丢失环境变量,不推荐。
