#! /usr/bin/env bash

ROOT_UID=0
DEST_DIR=

# Destination directory
if [ "$UID" -eq "$ROOT_UID" ]; then
  DEST_DIR="/usr/share/themes"
  ICON_DEST_DIR="/usr/share/icons"
else
  DEST_DIR="$HOME/.themes"
  ICON_DEST_DIR="$HOME/.icons"
fi

SRC_DIR=$(cd $(dirname $0) && pwd)

THEME_NAME=Canta
COLOR_VARIANTS=('' '-light' '-dark')
SIZE_VARIANTS=('' '-compact')
THEME_VARIANTS=('' '-blue' '-indigo')

show_info() {
  echo -e "\033[1;34m$@\033[0m"
}

show_tips() {
  echo -e "\033[1;32m$@\033[0m"
}

if [[ "$(command -v gnome-shell)" ]]; then
  SHELL_VERSION="$(gnome-shell --version | cut -d ' ' -f 3 | cut -d . -f -1)"
  if [[ "${SHELL_VERSION:-}" -ge "40" ]]; then
    GS_VERSION="new"
  else
    GS_VERSION="old"
  fi
  else
    echo "'gnome-shell' not found, using styles for last gnome-shell version available."
    GS_VERSION="new"
fi

usage() {
  printf "%s\n" "Usage: $0 [OPTIONS...]"
  printf "\n%s\n" "OPTIONS:"
  printf "  %-25s%s\n" "-d, --dest DIR" "Specify theme destination directory (Default: ${DEST_DIR})"
  printf "  %-25s%s\n" "-n, --name NAME" "Specify theme name (Default: ${THEME_NAME})"
  printf "  %-25s%s\n" "-t, --theme VARIANTS" "Specify theme color variant(s) [standard|blue|indigo] (Default: All variants)"
  printf "  %-25s%s\n" "-c, --color VARIANTS" "Specify theme bright variant(s) [standard|light|dark] (Default: All variants)"
  printf "  %-25s%s\n" "-s, --size VARIANT" "Specify theme size variant [standard|compact] (Default: All variants)"
  printf "  %-25s%s\n" "-o, --ordinary" "Install ordinary theme without nautilus background images"
  printf "  %-25s%s\n" "-g, --gdm" "Install GDM theme"
  printf "  %-25s%s\n" "-i, --icon" "Install icon theme"
  printf "  %-25s%s\n" "-h, --help" "Show this help"
  printf "\n%s\n" "INSTALLATION EXAMPLES:"
  printf "%s\n" "Install all theme variants into ~/themes"
  printf "  %s\n" "$0 --dest ~/themes"
  printf "%s\n" "Install all theme variants into ~/themes including GDM theme"
  printf "  %s\n" "$0 --dest ~/themes --gdm"
  printf "%s\n" "Install standard theme variant only"
  printf "  %s\n" "$0 --dest ~/icons --icon"
  printf "%s\n" "Install standard icon theme only"
  printf "  %s\n" "$0 --color standard --size standard"
  printf "%s\n" "Install square theme variant only"
  printf "%s\n" "Install specific theme variants with different name into ~/themes"
  printf "  %s\n" "$0 --dest ~/themes --name MyTheme --color light dark --size compact"
}

install() {
  local dest=${1}
  local name=${2}
  local theme=${3}
  local color=${4}
  local size=${5}

  [[ ${color} == '-dark' ]] && local ELSE_DARK=${color}
  [[ ${color} == '-light' ]] && local ELSE_LIGHT=${color}

  local THEME_DIR=${dest}/${name}${theme}${color}${size}

  [[ -d ${THEME_DIR} ]] && rm -rf ${THEME_DIR}

  echo "Installing '${THEME_DIR}'..."

  theme_tweaks

  mkdir -p                                                                           ${THEME_DIR}
  cp -rf ${SRC_DIR}/COPYING                                                          ${THEME_DIR}
  cp -rf ${SRC_DIR}/AUTHORS                                                          ${THEME_DIR}

  echo "[Desktop Entry]" >> ${THEME_DIR}/index.theme
  echo "Type=X-GNOME-Metatheme" >> ${THEME_DIR}/index.theme
  echo "Name=${name}${theme}${color}${size}" >> ${THEME_DIR}/index.theme
  echo "Comment=An Flat Gtk+ theme based on Material Design" >> ${THEME_DIR}/index.theme
  echo "Encoding=UTF-8" >> ${THEME_DIR}/index.theme
  echo "" >> ${THEME_DIR}/index.theme
  echo "[X-GNOME-Metatheme]" >> ${THEME_DIR}/index.theme
  echo "GtkTheme=${name}${theme}${color}${size}" >> ${THEME_DIR}/index.theme
  echo "MetacityTheme=${name}${theme}${color}${size}" >> ${THEME_DIR}/index.theme
  echo "IconTheme=Adwaita" >> ${THEME_DIR}/index.theme
  echo "CursorTheme=Adwaita" >> ${THEME_DIR}/index.theme
  echo "ButtonLayout=menu:minimize,maximize,close" >> ${THEME_DIR}/index.theme

  mkdir -p                                                                           ${THEME_DIR}/gnome-shell
  cp -rf ${SRC_DIR}/src/gnome-shell/{*.svg,extensions,noise-texture.png,pad-osd.css} ${THEME_DIR}/gnome-shell
  cp -rf ${SRC_DIR}/src/gnome-shell/gnome-shell-theme.gresource.xml                  ${THEME_DIR}/gnome-shell
  cp -rf ${SRC_DIR}/src/gnome-shell/assets${ELSE_DARK}                               ${THEME_DIR}/gnome-shell/assets
  cp -rf ${SRC_DIR}/src/gnome-shell/common-assets/*.svg                              ${THEME_DIR}/gnome-shell/assets

  if [[ "$tweaks" == 'true' ]]; then
    if [[ "${GS_VERSION:-}" == 'new' ]]; then
      sassc $SASSC_OPT ${SRC_DIR}/src/gnome-shell/shell-40-0/gnome-shell${color}${size}.scss ${THEME_DIR}/gnome-shell/gnome-shell.css
    else
      sassc $SASSC_OPT ${SRC_DIR}/src/gnome-shell/shell-3-36/gnome-shell${color}${size}.scss ${THEME_DIR}/gnome-shell/gnome-shell.css
    fi
  else
    if [[ "${GS_VERSION:-}" == 'new' ]]; then
      cp -rf ${SRC_DIR}/src/gnome-shell/shell-40-0/gnome-shell${color}${size}.css    ${THEME_DIR}/gnome-shell/gnome-shell.css
    else
      cp -rf ${SRC_DIR}/src/gnome-shell/shell-3-36/gnome-shell${color}${size}.css    ${THEME_DIR}/gnome-shell/gnome-shell.css
    fi
  fi

  mkdir -p                                                                           ${THEME_DIR}/gtk-2.0
  cp -rf ${SRC_DIR}/src/gtk-2.0/{apps.rc,hacks.rc,panel.rc}                          ${THEME_DIR}/gtk-2.0
  cp -rf ${SRC_DIR}/src/gtk-2.0/main.rc${theme}                                      ${THEME_DIR}/gtk-2.0/main.rc
  cp -rf ${SRC_DIR}/src/gtk-2.0/assets${ELSE_DARK}                                   ${THEME_DIR}/gtk-2.0/assets
  [[ ${theme} != '' && ${color} == '-dark' ]] && \
  cp -rf ${SRC_DIR}/src/gtk-2.0/assets-theme-dark/*.png                              ${THEME_DIR}/gtk-2.0/assets
  cp -rf ${SRC_DIR}/src/gtk-2.0/gtkrc${theme}${color}                                ${THEME_DIR}/gtk-2.0/gtkrc

  mkdir -p                                                                           ${THEME_DIR}/gtk-3.0
  cp -rf ${SRC_DIR}/src/gtk/assets                                                   ${THEME_DIR}/gtk-3.0
  cp -rf ${SRC_DIR}/src/gtk/common-assets                                            ${THEME_DIR}/gtk-3.0

  if [[ "$tweaks" == 'true' ]]; then
    sassc $SASSC_OPT ${SRC_DIR}/src/gtk/3.0/gtk${color}${size}.scss                  ${THEME_DIR}/gtk-3.0/gtk.css
    [[ ${color} != '-dark' ]] && \
    sassc $SASSC_OPT ${SRC_DIR}/src/gtk/3.0/gtk-dark${size}.scss                     ${THEME_DIR}/gtk-3.0/gtk-dark.css
  else
    cp -rf ${SRC_DIR}/src/gtk/3.0/gtk${color}${size}.css                             ${THEME_DIR}/gtk-3.0/gtk.css
    [[ ${color} != '-dark' ]] && \
    cp -rf ${SRC_DIR}/src/gtk/3.0/gtk-dark${size}.css                                ${THEME_DIR}/gtk-3.0/gtk-dark.css
  fi

  mkdir -p                                                                           ${THEME_DIR}/gtk-4.0
  cp -rf ${SRC_DIR}/src/gtk/assets                                                   ${THEME_DIR}/gtk-4.0
  cp -rf ${SRC_DIR}/src/gtk/common-assets                                            ${THEME_DIR}/gtk-4.0

  if [[ "$tweaks" == 'true' ]]; then
    sassc $SASSC_OPT ${SRC_DIR}/src/gtk/4.0/gtk${color}${size}.scss                  ${THEME_DIR}/gtk-4.0/gtk.css
    [[ ${color} != '-dark' ]] && \
    sassc $SASSC_OPT ${SRC_DIR}/src/gtk/4.0/gtk-dark${size}.scss                     ${THEME_DIR}/gtk-4.0/gtk-dark.css
  else
    cp -rf ${SRC_DIR}/src/gtk/4.0/gtk${color}${size}.css                             ${THEME_DIR}/gtk-4.0/gtk.css
    [[ ${color} != '-dark' ]] && \
    cp -rf ${SRC_DIR}/src/gtk/4.0/gtk-dark${size}.css                                ${THEME_DIR}/gtk-4.0/gtk-dark.css
  fi

  mkdir -p                                                                           ${THEME_DIR}/metacity-1
  cp -rf ${SRC_DIR}/src/metacity-1/assets/*.png                                      ${THEME_DIR}/metacity-1
  cp -rf ${SRC_DIR}/src/metacity-1/metacity-theme-1${color}.xml                      ${THEME_DIR}/metacity-1/metacity-theme-1.xml
  cd ${THEME_DIR}/metacity-1
  ln -s metacity-theme-1.xml metacity-theme-2.xml
  ln -s metacity-theme-1.xml metacity-theme-3.xml

  mkdir -p                                                                           ${THEME_DIR}/unity
  cp -rf ${SRC_DIR}/src/unity/{*.svg,*.png,dash-widgets.json}                        ${THEME_DIR}/unity
  cp -rf ${SRC_DIR}/src/unity/assets${ELSE_LIGHT}                                    ${THEME_DIR}/unity/assets

  mkdir -p                                                                           ${THEME_DIR}/xfwm4
  cp -rf ${SRC_DIR}/src/xfwm4/{*.svg,themerc}                                        ${THEME_DIR}/xfwm4
  cp -rf ${SRC_DIR}/src/xfwm4/assets${ELSE_LIGHT}                                    ${THEME_DIR}/xfwm4/assets

  if [[ "${theme}" == '' ]]; then
    mkdir -p                                                                         ${THEME_DIR}/cinnamon
    cp -rf ${SRC_DIR}/src/cinnamon/cinnamon${ELSE_DARK}.css                          ${THEME_DIR}/cinnamon/cinnamon.css
    cp -rf ${SRC_DIR}/src/cinnamon/assets/common-assets                              ${THEME_DIR}/cinnamon/assets
    cp -rf ${SRC_DIR}/src/cinnamon/assets/assets${ELSE_DARK}/checkbox/*.svg          ${THEME_DIR}/cinnamon/assets/checkbox
    cp -rf ${SRC_DIR}/src/cinnamon/assets/assets${ELSE_DARK}/menu/*.svg              ${THEME_DIR}/cinnamon/assets/menu
    cp -rf ${SRC_DIR}/src/cinnamon/assets/assets${ELSE_DARK}/misc/*.svg              ${THEME_DIR}/cinnamon/assets/misc
    cp -rf ${SRC_DIR}/src/cinnamon/assets/assets${ELSE_DARK}/switch/*.svg            ${THEME_DIR}/cinnamon/assets/switch
    cp -rf ${SRC_DIR}/src/cinnamon/thumbnail${ELSE_DARK}.png                         ${THEME_DIR}/cinnamon/thumbnail.png
  fi

  mkdir -p                                                                           ${THEME_DIR}/plank
  cp -rf ${SRC_DIR}/src/plank/dock${ELSE_LIGHT}.theme                                ${THEME_DIR}/plank/dock.theme
}

install_gdm() {
  local THEME_DIR=${1}/${2}${3}${4}${5}
  local GS_THEME_FILE="/usr/share/gnome-shell/gnome-shell-theme.gresource"
  local UBUNTU_THEME_FILE="/usr/share/gnome-shell/theme/ubuntu.css"

  if [[ -f "$GS_THEME_FILE" ]] && [[ "$(which glib-compile-resources 2> /dev/null)" ]]; then
    echo "Installing '$GS_THEME_FILE'..."
    cp -an "$GS_THEME_FILE" "$GS_THEME_FILE.bak"
    glib-compile-resources \
      --sourcedir="$THEME_DIR/gnome-shell" \
      --target="$GS_THEME_FILE" \
      "$THEME_DIR/gnome-shell/gnome-shell-theme.gresource.xml"
  else
    echo
    echo "ERROR: Failed to install '$GS_THEME_FILE'"
    exit 1
  fi

  if [[ -f "$UBUNTU_THEME_FILE" ]]; then
    echo "Installing '$UBUNTU_THEME_FILE'..."
    cp -an "$UBUNTU_THEME_FILE" "$UBUNTU_THEME_FILE.bak"
    cp -af "$THEME_DIR/gnome-shell/gnome-shell.css" "$UBUNTU_THEME_FILE"
  fi
}

install_icon() {
  echo -e "\nInstalling Canta icon theme..."

  # Copying files
  cp -rf ${SRC_DIR}/icons/Canta ${ICON_DEST_DIR}

  # update icon caches
  gtk-update-icon-cache ${ICON_DEST_DIR}/Canta

  echo -e "\nInstallation complete!"
  show_tips "\nIf you want a better experience you should install numix-circle first!"
  show_tips "Because Canta icon theme use numix-icon-theme-circle icon theme for Inherits!\n"
}

# check command avalibility
function has_command() {
  command -v $1 > /dev/null
}

install_package() {
  if [ ! "$(which sassc 2> /dev/null)" ]; then
     echo sassc needs to be installed to generate the css.
     if has_command zypper; then
      sudo zypper in sassc
        elif has_command apt-get; then
      sudo apt-get install sassc
        elif has_command dnf; then
      sudo dnf install sassc
        elif has_command yum; then
      sudo yum install sassc
        elif has_command pacman; then
      sudo pacman -S --noconfirm sassc
      fi
  fi
}

themes=()
colors=()
sizes=()

while [[ "$#" -gt 0 ]]; do
  case "${1:-}" in
    -d|--dest)
      dest="${2}"
      if [[ ! -d "${dest}" ]]; then
        echo "ERROR: Destination directory does not exist."
        exit 1
      fi
      shift 2
      ;;
    -n|--name)
      name="${2}"
      shift 2
      ;;
    -g|--gdm)
      gdm='true'
      shift 1
      ;;
    -i|--icon)
      icon='true'
      shift 1
      ;;
    -o|--ordinary)
      ordinary='true'
      shift 1
      ;;
    -t|--theme)
      accent='true'
      shift
      for theme in "${@}"; do
        case "${theme}" in
          standard)
            themes+=("${THEME_VARIANTS[0]}")
            shift
            ;;
          blue)
            themes+=("${THEME_VARIANTS[1]}")
            shift
            ;;
          indigo)
            themes+=("${THEME_VARIANTS[2]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized theme variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -c|--color)
      shift
      for color in "${@}"; do
        case "${color}" in
          standard)
            colors+=("${COLOR_VARIANTS[0]}")
            shift
            ;;
          light)
            colors+=("${COLOR_VARIANTS[1]}")
            shift
            ;;
          dark)
            colors+=("${COLOR_VARIANTS[2]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized color variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -s|--size)
      shift
      for size in "${@}"; do
        case "${size}" in
          standard)
            sizes+=("${SIZE_VARIANTS[0]}")
            shift
            ;;
          compact)
            sizes+=("${SIZE_VARIANTS[1]}")
            shift
            ;;
          -*|--*)
            break
            ;;
          *)
            echo "ERROR: Unrecognized size variant '$1'."
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        esac
      done
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unrecognized installation option '$1'."
      echo "Try '$0 --help' for more information."
      exit 1
      ;;
  esac
done

if [[ "${#themes[@]}" -eq 0 ]] ; then
  themes=("${THEME_VARIANTS[0]}")
fi

if [[ "${#colors[@]}" -eq 0 ]] ; then
  colors=("${COLOR_VARIANTS[@]}")
fi

if [[ "${#sizes[@]}" -eq 0 ]] ; then
  sizes=("${SIZE_VARIANTS[@]}")
fi

install_theme() {
  for theme in "${themes[@]}"; do
    for color in "${colors[@]}"; do
      for size in "${sizes[@]}"; do
         install "${dest:-${DEST_DIR}}" "${name:-${THEME_NAME}}" "${theme}" "${color}" "${size}"
      done
    done
  done
}

tweaks_temp() {
  cp -rf ${SRC_DIR}/src/_sass/_tweaks.scss ${SRC_DIR}/src/_sass/_tweaks-temp.scss
}

theme_colors() {
  if [[ "$theme" != '' ]]; then
    case "$theme" in
      -blue)
        theme_color='blue'
        ;;
      -indigo)
        theme_color='indigo'
        ;;
    esac
    sed -i "/\$color:/s/default/${theme_color}/" ${SRC_DIR}/src/_sass/_tweaks-temp.scss
  fi
}

bakground_image() {
    echo "Install with no nautilus bakground image..."
    sed -i "/\$theme_image:/s/true/false/" ${SRC_DIR}/src/_sass/_tweaks-temp.scss
}

theme_tweaks() {
  if [[ "$accent" == 'true' || "${ordinary}" == 'true' ]]; then
    tweaks='true'
    install_package; tweaks_temp
  fi

  if [[ "$accent" == 'true' ]] ; then
    theme_colors
  fi

  if [[ "${ordinary}" == 'true' ]] ; then
    bakground_image
  fi
}

install_theme

if [[ "${gdm:-}" == 'true' ]]; then
  install_gdm "${dest:-${DEST_DIR}}" "${name:-${THEME_NAME}}" "${theme}" "${color}" "${size}"
fi

if [[ "${icon:-}" == 'true' ]]; then
  install_icon "${dest:-${DEST_DIR}}" "${name:-${THEME_NAME}}" "${theme}" "${color}" "${size}"
fi

echo
echo Done.
