FROM manjarolinux/base:latest

ARG MIRROR_URL

ENV LANG=en_US.UTF-8
ENV TZ=America/New_York
ENV PATH="/usr/bin:${PATH}"
ENV PUSER=user
ENV PUID=1000

# Configure the locale; enable only en_US.UTF-8 and the current locale.
RUN sed -i -e 's~^\([^#]\)~#\1~' '/etc/locale.gen' && \
  echo -e '\nen_US.UTF-8 UTF-8' >> '/etc/locale.gen' && \
  if [[ "${LANG}" != 'en_US.UTF-8' ]]; then \
  echo "${LANG}" >> '/etc/locale.gen'; \
  fi && \
  locale-gen && \
  echo -e "LANG=${LANG}\nLC_ADDRESS=${LANG}\nLC_IDENTIFICATION=${LANG}\nLC_MEASUREMENT=${LANG}\nLC_MONETARY=${LANG}\nLC_NAME=${LANG}\nLC_NUMERIC=${LANG}\nLC_PAPER=${LANG}\nLC_TELEPHONE=${LANG}\nLC_TIME=${LANG}" > '/etc/locale.conf'

# Configure the timezone.
RUN echo "${TZ}" > /etc/timezone && \
  ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime

# Populate the mirror list.
RUN pacman-mirrors -f && \
  if [[ -n "${MIRROR_URL}" ]]; then \
  mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak && \
  echo "Server = ${MIRROR_URL}/stable/\$repo/\$arch" > /etc/pacman.d/mirrorlist; \
  fi

# Install the core packages.
RUN pacman -Syu --noconfirm --needed \
  diffutils \
  findutils \
  manjaro-release \
  manjaro-system \
  sudo && \
  pacman -Scc --noconfirm

# Make sure everything is up-to-date.
RUN sed -i -e 's~^\(\(CheckSpace\|IgnorePkg\|IgnoreGroup\).*\)$~#\1~' /etc/pacman.conf && \
  pacman -Syyu --noconfirm --needed && \
  mv -f /etc/pacman.conf.pacnew /etc/pacman.conf && \
  sed -i -e 's~^\(CheckSpace.*\)$~#\1~' /etc/pacman.conf && \
  pacman -Scc --noconfirm

# Install the common non-GUI packages.
RUN pacman -Sy --noconfirm --needed \
  wireplumber \
  autoconf \
  automake \
  base-devel \
  bash-completion \
  bison \
  bat \
  clang \
  dmidecode \
  fakeroot \
  fd \
  flex \
  fzf \
  git \
  htop \
  iftop \
  inetutils \
  iproute2 \
  iputils \
  jq \
  logrotate \
  lrzip \
  lsof \
  man-db \
  manjaro-aur-support \
  manjaro-base-skel \
  manjaro-browser-settings \
  manjaro-hotfixes \
  manjaro-pipewire \
  manjaro-zsh-config \
  meson \
  mpdecimal \
  net-tools \
  nfs-utils \
  nodejs-lts-fermium \
  openbsd-netcat \
  openresolv \
  openssh \
  p7zip \
  pamac-cli \
  perf \
  pigz \
  pipewire-jack \
  pkgconf \
  procps-ng \
  protobuf \
  psmisc \
  python \
  python-cchardet \
  python-matplotlib \
  python-netifaces \
  python-pip \
  python-setuptools \
  rclone \
  ripgrep \
  rsync \
  sd \
  squashfs-tools \
  systemd-sysvcompat \
  tcpdump \
  tree \
  unace \
  unrar \
  unzip \
  wget \
  xz \
  zip && \
  pacman -Scc --noconfirm

# Configure Pamac.
RUN sed -i -e \
  's~#\(\(RemoveUnrequiredDeps\|SimpleInstall\|EnableAUR\|KeepBuiltPkgs\|CheckAURUpdates\|DownloadUpdates\).*\)~\1~g' \
  /etc/pamac.conf

# Install ncurses5-compat-libs from AUR.
RUN \
  cd /tmp && \
  sudo -u builder gpg --recv-keys CC2AF4472167BE03 && \
  sudo -u builder git clone https://aur.archlinux.org/ncurses5-compat-libs.git && \
  cd ncurses5-compat-libs && \
  sudo -u builder makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/ncurses5-compat-libs/*.pkg.tar* && \
  rm -fr /tmp/ncurses5-compat-libs && \
  pacman -Scc --noconfirm

# Install the common GUI packages.
RUN pacman -Syu --noconfirm --needed \
  gnome \
  manjaro-gnome-settings \
  manjaro-settings-manager \
  manjaro-gnome-extension-settings

# RUN pacman -Rs gnome-software && pacman -Syu --noconfirm --needed \
#   pamac-gnome-integration

# Install xrdp and xorgxrdp from AUR.
# - Remove the generated XRDP RSA key because it will be generated at the first boot.
# - Unlock gnome-keyring automatically for xrdp login.
RUN \
  pacman -Syu --noconfirm --needed \
  check imlib2 tigervnc libxrandr fuse libfdk-aac ffmpeg nasm xorg-server-devel && \
  cd /tmp && \
  sudo -u builder gpg --recv-keys 61ECEABBF2BB40E3A35DF30A9F72CDBC01BF10EB && \
  sudo -u builder git clone https://aur.archlinux.org/xrdp.git && \
  sudo -u builder git clone https://aur.archlinux.org/xorgxrdp.git && \
  cd /tmp/xrdp && sudo -u builder makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/xrdp/*.pkg.tar* && \
  cd /tmp/xorgxrdp && sudo -u builder makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/xorgxrdp/*.pkg.tar* && \
  rm -fr /tmp/xrdp /tmp/xorgxrdp /etc/xrdp/rsakeys.ini && \
  pacman -Scc --noconfirm && \
  systemctl enable xrdp.service

# Install the workaround for:
# - https://github.com/neutrinolabs/xrdp/issues/1684
# - GNOME Keyring asks for password at login.
RUN \
  cd /tmp && \
  wget 'https://github.com/matt335672/pam_close_systemd_system_dbus/archive/f8e6a9ac7bdbae7a78f09845da4e634b26082a73.zip' && \
  unzip f8e6a9ac7bdbae7a78f09845da4e634b26082a73.zip && \
  cd /tmp/pam_close_systemd_system_dbus-f8e6a9ac7bdbae7a78f09845da4e634b26082a73 && \
  make install && \
  rm -fr /tmp/pam_close_systemd_system_dbus-f8e6a9ac7bdbae7a78f09845da4e634b26082a73

# Remove the cruft.
RUN rm -f /etc/locale.conf.pacnew /etc/locale.gen.pacnew

# Enable/disable the services.
RUN \
  systemctl enable \
  sshd.service && \
  systemctl mask \
  bluetooth.service \
  dev-sda1.device \
  dm-event.service \
  dm-event.socket \
  geoclue.service \
  initrd-udevadm-cleanup-db.service \
  lvm2-lvmpolld.socket \
  lvm2-monitor.service \
  power-profiles-daemon.service \
  systemd-boot-update.service \
  systemd-firstboot.service \
  systemd-modules-load.service \
  systemd-network-generator.service \
  systemd-networkd.service \
  systemd-networkd.socket \
  systemd-networkd-wait-online.service \
  systemd-remount-fs.service \
  systemd-udev-settle.service \
  systemd-udev-trigger.service \
  systemd-udevd.service \
  systemd-udevd-control.socket \
  systemd-udevd-kernel.socket \
  udisks2.service \
  upower.service \
  usb-gadget.target \
  usbmuxd.service && \
  systemctl mask --global \
  gvfs-mtp-volume-monitor.service \
  gvfs-udisks2-volume-monitor.service \
  obex.service \
  pipewire.service \
  pipewire.socket \
  pipewire-media-session.service \
  pipewire-pulse.service \
  pipewire-pulse.socket \
  wireplumber.service

# Copy the configuration files and scripts.
COPY files/ /

# Enable the first boot time script.
RUN systemctl enable first-boot.service

# Workaround for the colord authentication issue.
# See: https://unix.stackexchange.com/a/581353
RUN systemctl enable fix-colord.service

# Delete the 'builder' user from the base image.
RUN userdel --force --remove builder

# Create and configure user
RUN groupadd sudo && \
  useradd  \
  --shell /bin/zsh \
  -g users \
  -G sudo,lp,network,power,sys,wheel \
  --badname \
  -u "$PUID" \
  -d "/home/$PUSER" \
  -m -N "$PUSER" && \
  echo -e "$PUSER\n$PUSER" | passwd "$PUSER"

# Switch to the default mirrors since we finished downloading packages.
RUN \
  if [[ -n "${MIRROR_URL}" ]]; then \
  mv /etc/pacman.d/mirrorlist.bak /etc/pacman.d/mirrorlist; \
  fi

# Expose SSH and RDP ports.
EXPOSE 22
EXPOSE 3389

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
