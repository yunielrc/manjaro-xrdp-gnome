FROM manjarolinux/base:latest

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
RUN pacman-mirrors -f

# Install the core packages.
RUN pacman -Syu --noconfirm --needed \
  diffutils \
  findutils \
  manjaro-release \
  manjaro-system \
  sudo

# Make sure everything is up-to-date.
RUN sed -i -e 's~^\(\(CheckSpace\|IgnorePkg\|IgnoreGroup\).*\)$~#\1~' /etc/pacman.conf && \
  pacman -Syu --noconfirm --needed && \
  mv -f /etc/pacman.conf.pacnew /etc/pacman.conf && \
  sed -i -e 's~^\(CheckSpace.*\)$~#\1~' /etc/pacman.conf

# Install the common non-GUI packages.
RUN pacman -Syu --noconfirm --needed \
  wireplumber \
  base-devel \
  bash-completion \
  clang \
  dmidecode \
  fakeroot \
  git \
  htop \
  inetutils \
  iproute2 \
  iputils \
  logrotate \
  man-db \
  manjaro-aur-support \
  manjaro-base-skel \
  manjaro-pipewire \
  manjaro-zsh-config \
  nfs-utils \
  openresolv \
  openssh \
  pamac-cli \
  pipewire-jack \
  procps-ng \
  protobuf \
  psmisc \
  python \
  rsync \
  sd \
  systemd-sysvcompat \
  unzip \
  wget \
  xz \
  zip

# Configure Pamac.
RUN sed -i -e \
  's~#\(\(RemoveUnrequiredDeps\|SimpleInstall\|EnableAUR\|KeepBuiltPkgs\|CheckAURUpdates\|DownloadUpdates\).*\)~\1~g' \
  /etc/pamac.conf

# Install paru AUR helper from AUR.
RUN cd /tmp && \
  sudo -u builder git clone https://aur.archlinux.org/paru-bin.git && \
  cd paru-bin && \
  sudo -u builder makepkg -si --noconfirm --needed && \
  sudo rm -rf /tmp/paru-bin

# Install the common GUI packages.
RUN pacman -Syu --noconfirm --needed \
  gnome \
  manjaro-gnome-settings \
  manjaro-settings-manager \
  manjaro-gnome-extension-settings && \
  pacman -Rs --noconfirm gnome-software && \
  pacman -Syu --noconfirm --needed pamac-gnome-integration
# RUN pacman -Rs gnome-software && pacman -Syu --noconfirm --needed \
#   pamac-gnome-integration

# Install ncurses5-compat-libs from AUR.
RUN sudo -u builder  paru -S --noconfirm ncurses5-compat-libs

# Install packages
RUN pacman -Syu --noconfirm --needed \
  adobe-source-sans-fonts \
  adwaita-qt5 \
  adwaita-qt6 \
  amtk \
  cronie \
  gnome-browser-connector \
  gnome-themes-extra \
  gnome-tweaks \
  gnome-wallpapers \
  inxi \
  mailcap \
  manjaro-application-utility \
  manjaro-artwork \
  manjaro-hello \
  manjaro-settings-manager-notifier \
  man-pages \
  mousetweaks \
  nano \
  nano-syntax-highlighting \
  nautilus-admin \
  nautilus-empty-file \
  networkmanager \
  noto-fonts \
  ntp \
  numactl \
  numlockx \
  os-prober \
  papirus-maia-icon-theme \
  polkit-gnome \
  qgnomeplatform-qt5 \
  qgnomeplatform-qt6 \
  shared-color-targets \
  ttf-dejavu \
  ttf-droid \
  ttf-inconsolata \
  ttf-indic-otf \
  ttf-liberation \
  vim \
  vte3 \
  web-installer-url-handler \
  xcursor-breeze \
  xorg-mkfontscale \
  xorg-twm \
  zenity


# Install xrdp and xorgxrdp from AUR.
# - Unlock gnome-keyring automatically for xrdp login.
RUN pacman -Syu --noconfirm --needed \
  check imlib2 tigervnc libxrandr fuse libfdk-aac ffmpeg nasm xorg-server-devel && \
  sudo -u builder paru -S --noconfirm xrdp xorgxrdp && \
  systemctl enable xrdp.service

# Install the workaround for:
# - https://github.com/neutrinolabs/xrdp/issues/1684
# - GNOME Keyring asks for password at login.
RUN cd /tmp && \
  wget --progress=dot:giga 'https://github.com/matt335672/pam_close_systemd_system_dbus/archive/f8e6a9ac7bdbae7a78f09845da4e634b26082a73.zip' && \
  unzip f8e6a9ac7bdbae7a78f09845da4e634b26082a73.zip && \
  cd /tmp/pam_close_systemd_system_dbus-f8e6a9ac7bdbae7a78f09845da4e634b26082a73 && \
  make install && \
  rm -fr /tmp/pam_close_systemd_system_dbus-f8e6a9ac7bdbae7a78f09845da4e634b26082a73

# Remove the cruft.
RUN rm -f /etc/locale.conf.pacnew /etc/locale.gen.pacnew

# Clean Pacman cache
RUN pacman -Scc --noconfirm

# Enable/disable the services.
RUN systemctl enable sshd.service && \
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
COPY rootfs/ /

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

# Expose SSH and RDP ports.
EXPOSE 22
EXPOSE 3389

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
