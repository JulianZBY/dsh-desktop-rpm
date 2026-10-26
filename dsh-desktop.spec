Name:           dsh-desktop
Version:        2.0.19~next
Release:        1%{?dist}
Summary:        DeepSeek Harness desktop client (next channel)

%global upstream_ver 2.0.19-next
License:        MIT
URL:            https://github.com/anywhere-labs/dsh-desktop
Source0:        %{url}/releases/download/v%{upstream_ver}/DSH-NEXT-%{upstream_ver}-linux-x64.tar.gz
Source1:        dsh-desktop-icon.png
Source2:        dsh.desktop
ExclusiveArch:  x86_64

BuildRequires:  desktop-file-utils

Requires:       gtk3
Requires:       nss
Requires:       alsa-lib
Requires:       cups-libs
Requires:       dbus-libs
Requires:       libdrm
Requires:       libxkbcommon
Requires:       mesa-libgbm
Requires:       libwayland-client
Requires:       libseccomp
Requires:       libX11
Requires:       libXcursor
Requires:       libXrandr
Requires:       libXcomposite
Requires:       libXdamage
Requires:       libXext
Requires:       libXfixes
Requires:       libXi
Requires:       libXinerama
Requires:       libXrender

%global __requires_exclude_from ^/opt/%{name}/
%global __provides_exclude_from ^/opt/%{name}/
%global __brp_check_rpaths %{nil}
%define debug_package %{nil}

%description
DeepSeek Harness desktop application by anywhere-labs, built from
their upstream next-channel release tarball. Community RPM packaging;
app lives under /opt/dsh-desktop.

%prep
%setup -q -n DSH-NEXT-%{upstream_ver}-linux-x64

%install
mkdir -p %{buildroot}/opt/%{name}
cp -a . %{buildroot}/opt/%{name}/
install -Dpm 644 %{SOURCE1} %{buildroot}%{_datadir}/pixmaps/%{name}.png
install -Dpm 644 %{SOURCE2} %{buildroot}%{_datadir}/applications/%{name}.desktop
desktop-file-validate %{buildroot}%{_datadir}/applications/%{name}.desktop

%files
%license LICENSE.electron.txt LICENSES.chromium.html
/opt/%{name}
%attr(4755,root,root) /opt/%{name}/chrome-sandbox
%{_datadir}/pixmaps/%{name}.png
%{_datadir}/applications/%{name}.desktop

%changelog
* Mon Oct 26 2026 JulianZBY <JulianZBY@outlook.com> - 2.0.19~next-1
- Switch to the upstream next channel (next boots without the bundled
  primary runtime that is missing from all 2.0.18 linux artifacts)
* Mon Oct 26 2026 JulianZBY <JulianZBY@outlook.com> - 2.0.18-1
- Initial package from upstream v2.0.18 tarball
