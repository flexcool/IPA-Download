#!/bin/sh
set -e

APP_BUNDLE="${1:-${CODESIGNING_FOLDER_PATH}}"
if [ -z "${APP_BUNDLE}" ]; then
    exit 0
fi

SPARKLE_RESOURCES="${APP_BUNDLE}/Contents/Frameworks/Sparkle.framework/Versions/B/Resources"
if [ ! -d "${SPARKLE_RESOURCES}" ]; then
    exit 0
fi

patch_strings_file() {
    STRINGS_FILE="$1"
    if [ ! -f "${STRINGS_FILE}" ]; then
        return
    fi

    /usr/bin/plutil -convert xml1 "${STRINGS_FILE}"

    /usr/bin/perl -0pi -CS -e '
        s/>您使用的就是最新版！</>目前已是最新版。</g;
        s/>您已有最新版本！</>目前已是最新版。</g;
        s/>你用緊最新版本！</>目前已是最新版本。</g;

        s/您的macOS版本/当前 macOS 版本/g;
        s/您的 Mac/当前 Mac/g;
        s/您的系統版本/目前系統版本/g;
        s/您的 macOS 版本/目前 macOS 版本/g;
        s/您的Mac/目前 Mac/g;
        s/您現在的版本是/目前版本是/g;
        s/您正在執行的版本是/目前執行的版本是/g;
        s/您正在运行/当前运行版本为/g;
        s/您现在的版本是/当前版本是/g;
        s/您要在网站上查看/要在网站上查看/g;
        s/您想让/是否允许/g;
        s/您也可以/也可以/g;
        s/您需要/需要/g;
        s/請確認您是否/請確認是否/g;
        s/请验证您是否/请确认是否/g;
        s/如果您对此有疑问/如果对此有疑问/g;
        s/如果您對此有疑問/如果對此有疑問/g;
        s/您//g;
    ' "${STRINGS_FILE}"

    /usr/bin/plutil -convert binary1 "${STRINGS_FILE}"
}

patch_strings_file "${SPARKLE_RESOURCES}/zh_CN.lproj/Sparkle.strings"
patch_strings_file "${SPARKLE_RESOURCES}/zh_TW.lproj/Sparkle.strings"
patch_strings_file "${SPARKLE_RESOURCES}/zh_HK.lproj/Sparkle.strings"
