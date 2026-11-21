#!/bin/bash
# Tự động nhận diện thư mục chứa script hiện tại
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR"

# Tự động tìm lệnh adb (tương thích cả Termux và OpenWrt/Linux)
if command -v adb >/dev/null 2>&1; then
    ADB_COMMAND="$(command -v adb)"
elif [ -x "/usr/bin/adb" ]; then
    ADB_COMMAND="/usr/bin/adb"
else
    ADB_COMMAND="adb"
fi

# BẢNG MÀU ANSI 
RED='\033[0;31m'  
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BBLUE='\033[1;34m'
BMAGENTA='\033[1;35m'
BCYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

trap '$ADB_COMMAND disconnect >/dev/null 2>&1; exit' INT TERM

# =================== PHẦN HIỂN THỊ PHIÊN BẢN VÀ BẢN QUYỀN ===================
print_header() {
    clear
    echo -e "${BCYAN}🚀 TRÌNH CÀI TIẾNG VIỆT CHO XIAOMI BY KHÁNH IT${NC}"
    echo -e "${BGREEN}📞 Hotline: 0967.341.608${NC}"
    echo -e "${WHITE}📦 Phiên bản: V6.0    Cập Nhật: 21-11-2026${NC}"
    echo
}

# =================== KHỐI LỆNH CÀI APK (TỐI ƯU CHO ANDROID 5-14) ===================
install_apk() {
    local apk_file="$1"
    if [ ! -f "$apk_file" ]; then
        echo -e "${BYELLOW}⚠ Không tìm thấy file: $apk_file (Tại: $PWD)${NC}"
        return
    fi

    echo -e "→ Đang cài ứng dụng: ${BCYAN}$apk_file${NC}"
    
    if ! $ADB_COMMAND push "$apk_file" "/data/local/tmp/temp_app.apk" >/dev/null 2>&1; then
        echo -e "${BRED}📁 ✗ Lỗi đẩy file APK vào bộ nhớ tạm TV !${NC}"
        return
    fi

    local output
    if [ "${SDK:-0}" -ge 23 ]; then
        output=$($ADB_COMMAND shell pm install -r -g "/data/local/tmp/temp_app.apk" 2>&1)
    else
        output=$($ADB_COMMAND shell pm install -r "/data/local/tmp/temp_app.apk" 2>&1)
    fi

    $ADB_COMMAND shell rm -f "/data/local/tmp/temp_app.apk" >/dev/null 2>&1

    if echo "$output" | grep -q "Success"; then
        echo -e "${BGREEN}📁 ✓ Cài Đặt ứng dụng Thành Công !${NC}"
    else
        echo -e "${BRED}📁 ✗ Cài Đặt Thất Bại !${NC}"
        echo -e "${YELLOW}   Lý do: $(echo "$output" | tr -d '\r' | tail -n 1)${NC}"
    fi
}

# =================== KIỂM TRA MÔI TRƯỜNG ===================
check_adb() {
    if ! $ADB_COMMAND version >/dev/null 2>&1; then
        echo -e "${RED}❌ adb chưa sẵn sàng. Hãy cài android-tools trước:${NC}"
        echo "pkg install android-tools (Termux) hoặc apk add android-tools (OpenWrt)"
        exit 1
    fi
    cd "$SOURCE_DIR" || exit 1
}

# =================== MENU 1: KẾT NỐI TV ===================
menu1() {
    while true; do
        print_header
        echo -e "${BBLUE}📡 MENU KẾT NỐI TIVI XIAOMI PRO${NC}"
        echo -e "${BLUE}────────────────────────────${NC}"
        echo ""
        echo -e "${BMAGENTA}📺 HƯỚNG DẪN KẾT NỐI TIVI${NC}\n"
        echo -e "${CYAN}🎮 Điều khiển:${NC} ${BYELLOW}↑ lên trên cùng${NC} → ${WHITE}Cài đặt ⚙${NC}"
        echo -e "${CYAN}🌐 Ngôn ngữ :${NC} ${BYELLOW}↓ 4 lần${NC} → ${WHITE}Language${NC} → ${BGREEN}English${NC}"
        echo -e "${CYAN}🔓 Developer:${NC} ${WHITE}About${NC} → ${BYELLOW}Model${NC} → ${BGREEN}OK 9 lần${NC}"
        echo -e "${CYAN}⚙️  Quyền    :${NC} ${BGREEN}ADB Debugging${NC} + ${BGREEN}Unknown Sources${NC}"
        echo -e "${CYAN}⛔ Lưu ý    :${NC} ${BRED}Tắt Update tự động${NC}"
        echo -e "${CYAN}📶 Thiết bị :${NC} ${BYELLOW}${DEVICE_IP:-Chưa kết nối}${NC} | ${BGREEN}Android ${ANDROID:-N/A}${NC}"
        echo ""
        echo -e "${BLUE}────────────────────────────${NC}"
        read -p "$(echo -e "${BGREEN}📶 Nhập IP Tivi:${NC} ")" RAW_IP
        [ -z "$RAW_IP" ] && continue

        [[ "$RAW_IP" != *":5555" ]] && DEVICE_IP="${RAW_IP}:5555" || DEVICE_IP="$RAW_IP"

        local retry_count=0
        local max_retries=5
        local connected=false

        while [ $retry_count -le $max_retries ]; do
            echo -e "\n→ ${BCYAN}Đang thử kết nối (Lần $((retry_count + 1)))...${NC}"
            
            $ADB_COMMAND disconnect >/dev/null 2>&1
            $ADB_COMMAND connect "$DEVICE_IP" >/dev/null 2>&1
            
            sleep 3 

            if $ADB_COMMAND devices | grep -q "$DEVICE_IP.*device"; then
                connected=true
                break
            else
                echo -e "${BYELLOW}⚠ Bấm OK trên điều khiển để tích vào ô đồng ý...${NC}"
                echo -e "${BYELLOW}⚠ Sau đó bấm phím xuống -> Sang phải -> Allow/OK${NC}"
                ((retry_count++))
            fi
        done

        if [ "$connected" = true ]; then
            echo -e "${BGREEN}✓ Kết nối thành công đến tivi !${NC}"
            echo -e "${BGREEN}✓ Chào mừng bạn đến với MENU CÀI ĐẶT !${NC}"
            echo -e "${WHITE}📱 TV đang kết nối tại: ${BCYAN}$DEVICE_IP${NC}"
            export DEVICE_IP
            sleep 1
            menu2
            break 
        else
            echo
            echo -e "${BRED}⛔ Đã thử 6 lần thất bại.${NC}"
            echo -e "${BRED}⛔ Vui lòng kiểm tra lại IP hoặc BẤM ĐỒNG Ý CHO PHÉP KẾT NỐI TRÊN TIVI.${NC}"
            sleep 5
        fi
    done
}

# =================== MENU 2 GIAO DIỆN SAU KHI KẾT NỐI ===================
menu2() {
    while true; do
        print_header
        echo -e "${WHITE}📱 TV đang kết nối tại: ${BCYAN}$DEVICE_IP${NC}"
        echo
        
        MODEL=$($ADB_COMMAND shell getprop ro.product.model | tr -d '\r')
        BRAND=$($ADB_COMMAND shell getprop ro.product.brand | tr -d '\r')
        PANEL=$($ADB_COMMAND shell getprop ro.boot.mi.panel_size 2>/dev/null | tr -d '\r')
        ANDROID=$($ADB_COMMAND shell getprop ro.build.version.release | tr -d '\r')
        PATCH=$($ADB_COMMAND shell getprop ro.build.version.security_patch | tr -d '\r')
        BUILD_SHOW=$($ADB_COMMAND shell getprop ro.build.version.incremental | tr -d '\r')
        DATE=$($ADB_COMMAND shell getprop ro.build.date | tr -d '\r')
        SERIAL=$($ADB_COMMAND shell getprop ro.serialno | tr -d '\r')
        SDK=$($ADB_COMMAND shell getprop ro.build.version.sdk | tr -d '\r')
        DEVICE=$($ADB_COMMAND shell getprop ro.product.device | tr -d '\r')
        [ -z "$PANEL" ] && PANEL="?"
        [ -z "$SDK" ] && SDK="22"
        
        echo -e "${BYELLOW}────────────────────────────────────────${NC}"
        echo -e "${CYAN}📺${NC} ${WHITE}$MODEL${NC} ${BYELLOW}|${NC} ${YELLOW}$BRAND${NC} ${BYELLOW}|${NC} ${BGREEN}Tivi (${PANEL} Inch)${NC}"
        echo -e "${CYAN}🤖${NC} ${WHITE}Android $ANDROID${NC} ${BYELLOW}|${NC} ${BBLUE}$BUILD_SHOW${NC}"
        echo -e "${CYAN}🆔${NC} ${WHITE}$SERIAL${NC} ${BYELLOW}|${NC} ${BBLUE}SDK $SDK${NC} ${BYELLOW}|${NC} ${WHITE}$DEVICE${NC}"
        echo -e "${CYAN}📅${NC} ${WHITE}$DATE${NC} ${BYELLOW}|${NC} ${BRED}$PATCH${NC}"
        echo -e "${BYELLOW}────────────────────────────────────────${NC}"
        echo
        echo -e "${BMAGENTA}📋 MENU CÀI ĐẶT GIAO DIỆN TIẾNG VIỆT CHO TIVI${NC}"
        echo
        echo -e "${GREEN}⛔ 1.${NC} ${BGREEN}⭐ CÀI TIẾNG VIỆT & HOME TV${NC}"
        echo -e "${GREEN}⛔ 2.${NC} ${WHITE}🖼️ CẬP NHẬT APP MỚI LÊN TV${NC}"
        echo -e "${GREEN}⛔ 3.${NC} ${BYELLOW}🔄 KHỞI ĐỘNG LẠI TV (REBOOT)${NC}"
        echo -e "${GREEN}⛔ 4.${NC} ${BRED}⚠️ XOÁ SẠCH DỮ LIỆU TIVI KHỞI ĐỘNG VÀO RESET CỨNG${NC}"
        echo -e "${GREEN}⛔ 5.${NC} ${BCYAN}🔗 NGẮT VÀ KẾT NỐI LẠI TV KHÁC${NC}"
        echo -e "${RED}⛔ 6.${NC} ${BRED}🚪 THOÁT${NC}"
        echo

        read -p "$(echo -e "${BGREEN}→ Nhập tùy chọn của bạn [1-6]:${NC} ")" CHOICE

        case $CHOICE in
            1) install_hometv_new; break ;;
            2) install_all_apks ;;
            3) reboot_tv "normal"; break ;;
            4) reboot_tv "recovery"; break ;;
            5) $ADB_COMMAND disconnect >/dev/null 2>&1; menu1; break ;; 
            6) $ADB_COMMAND disconnect >/dev/null 2>&1; echo -e "${BGREEN}👋 Tạm biệt! Hẹn gặp lại.${NC}"; exit 0 ;;
            *) echo -e "${BYELLOW}⚠️ Lựa chọn không hợp lệ, vui lòng chọn lại từ 1 đến 6.${NC}"; sleep 2 ;;
        esac
    done
}

# =================== CHỨC NĂNG ===================

# CHỨC NĂNG 1: CÀI GIAO DIỆN HOME TV MỚI (com.home.miuixiaomi) + TỰ KHỞI ĐỘNG LẠI
install_hometv_new() {
    echo -e "${BBLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "   ${BGREEN}✔${WHITE} CÀI GIAO DIỆN HOME TV MIUI XIAOMI${NC}"
    echo -e "${BBLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    echo -e "${BYELLOW}[1/6] Đang mở khóa cài đặt & cài Home TV mới...${NC}"
    $ADB_COMMAND shell settings put secure install_non_market_apps 1 >/dev/null 2>&1
    $ADB_COMMAND shell settings put global install_non_market_apps 1 >/dev/null 2>&1
    $ADB_COMMAND shell settings put global verifier_verify_adb_installs 0 >/dev/null 2>&1

    # Gỡ bản haki cũ nếu có trên máy để tránh xung đột Launcher
    $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.haki >/dev/null 2>&1

    install_apk "hometv.apk"

    local pkg="com.home.miuixiaomi"
    local runtime_perms="android.permission.RECORD_AUDIO \
        android.permission.BLUETOOTH_CONNECT \
        android.permission.WRITE_SECURE_SETTINGS \
        android.permission.CHANGE_CONFIGURATION \
        android.permission.WRITE_EXTERNAL_STORAGE \
        android.permission.READ_EXTERNAL_STORAGE \
        android.permission.READ_MEDIA_IMAGES"

    for perm in $runtime_perms; do
        $ADB_COMMAND shell pm grant "$pkg" "$perm" >/dev/null 2>&1
    done

    $ADB_COMMAND shell appops set "$pkg" SYSTEM_ALERT_WINDOW allow >/dev/null 2>&1
    $ADB_COMMAND shell appops set "$pkg" MANAGE_EXTERNAL_STORAGE allow >/dev/null 2>&1
    $ADB_COMMAND shell appwidget grantbind --package "$pkg" --user 0 >/dev/null 2>&1
    $ADB_COMMAND shell pm set-home-activity "$pkg/.MainActivity" >/dev/null 2>&1
    $ADB_COMMAND shell cmd package set-home-activity "$pkg/.MainActivity" >/dev/null 2>&1
    $ADB_COMMAND shell am force-stop "$pkg" >/dev/null 2>&1
    $ADB_COMMAND shell am start -W -n "$pkg/.MainActivity" >/dev/null 2>&1
	
    echo -e "${BYELLOW}[2/6] Đang gỡ bỏ và vô hiệu hóa ứng dụng rác & trợ lý gốc...${NC}"
    local apps="com.mitv.tvhome com.android.tv.settings com.mitv.gallery com.xiaomi.tweather \
        com.mitv.screensaver com.xiaomi.mitv.shop com.duokan.videodaily com.xiaomi.tv.gallery \
        com.mitv.cloudcontrol com.miui.tv.analytics com.xiaomi.voicecontrol com.xiaomi.voiceassistant \
        com.miui.voiceassist com.xiaomi.mitv.upgrade com.xiaomi.mitv.appstore com.xiaomi.mitv.calendar \
        com.xiaomi.mitv.handbook com.xiaomi.screenrecorder com.droidlogic.imageplayer \
        com.sohu.inputmethod.sogou.tv com.xiaomi.mitv.karaoke.service"

    for app in $apps; do
        $ADB_COMMAND shell pm uninstall --user 0 "$app" >/dev/null 2>&1
        $ADB_COMMAND shell pm disable-user --user 0 "$app" >/dev/null 2>&1
    done

    echo -e "${BCYAN}[3/6] 📦 Bắt đầu cài đặt các ứng dụng phụ trợ...${NC}"
    echo
    local apks_to_install="
      1.apk
      2.apk
      3.apk
      4.apk
      5.apk
      6.apk"

    for apk in $apks_to_install; do
        install_apk "$apk"
    done

    # Cấp quyền micro & bộ nhớ cho các app vệ tinh sau khi cài xong
    $ADB_COMMAND shell pm grant com.android5.truyenhinh android.permission.RECORD_AUDIO >/dev/null 2>&1
    $ADB_COMMAND shell pm grant com.khanhitpro.wallpaperchanger android.permission.WRITE_EXTERNAL_STORAGE >/dev/null 2>&1

    echo -e "${BCYAN}[4/6] 🖼️ Đang nạp dữ liệu ảnh nền...${NC}"
    copy_wallpapers

    echo -e "${BYELLOW}[5/6] 🔑 Đang cấu hình Tiếng Việt, tắt hiệu ứng và cài bàn phím...${NC}"
    for cmd in \
        "setprop persist.sys.language vi" \
        "setprop persist.sys.country VN" \
        "setprop persist.sys.locale vi-VN" \
        "settings put global device_locales vi-VN" \
        "settings put global sys_locale vi-VN" \
        "settings put system system_locales vi-VN" \
        "settings put global animator_duration_scale 0" \
        "settings put global transition_animation_scale 0" \
        "settings put global window_animation_scale 0" \
        "ime enable com.liskovsoft.leankeyboard/.ime.LeanbackImeService" \
        "settings put secure default_input_method com.liskovsoft.leankeyboard/.ime.LeanbackImeService" \
        "appops set com.google.android.katniss SYSTEM_ALERT_WINDOW allow"
    do
        $ADB_COMMAND shell "$cmd" >/dev/null 2>&1
    done

    echo -e "${BYELLOW}[6/6] 🏠 Cấp lại quyền, đặt mặc định & mở giao diện Home TV mới...${NC}"
    for perm in $runtime_perms; do
        $ADB_COMMAND shell pm grant "$pkg" "$perm" >/dev/null 2>&1
    done
    $ADB_COMMAND shell appops set "$pkg" SYSTEM_ALERT_WINDOW allow >/dev/null 2>&1
    $ADB_COMMAND shell appops set "$pkg" MANAGE_EXTERNAL_STORAGE allow >/dev/null 2>&1

    # Đặt làm Home mặc định (tương thích cả Android 5-6 và Android 7-14)
    $ADB_COMMAND shell pm set-home-activity "$pkg/.MainActivity" >/dev/null 2>&1
    $ADB_COMMAND shell cmd package set-home-activity "$pkg/.MainActivity" >/dev/null 2>&1

    # Khởi động tiến trình Home mới trước khi reboot
    $ADB_COMMAND shell am force-stop "$pkg" >/dev/null 2>&1
    sleep 1
    $ADB_COMMAND shell am start -W -n "$pkg/.MainActivity" >/dev/null 2>&1
    $ADB_COMMAND shell input keyevent 3 >/dev/null 2>&1

    echo -e "${BYELLOW}🔄 Đang đồng bộ dữ liệu ổ cứng TV trước khi khởi động lại...${NC}"
    $ADB_COMMAND shell sync >/dev/null 2>&1
    sleep 2

    echo -e "${BGREEN}✅ CÀI ĐẶT GIAO DIỆN HOME TV MỚI HOÀN TẤT!${NC}"
    echo -e "${BYELLOW}🔄 Tivi sẽ tự động khởi động lại sau 2 giây...${NC}"
    sleep 2

    # Tự động khởi động lại Tivi và quay về Menu 1
    reboot_tv "normal"
}

# CHỨC NĂNG 2: CẬP NHẬT APP MỚI CHO TIVI XIAOMI
install_all_apks() {
    echo -e "${BBLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "   ${BGREEN}✔${WHITE} CÀI APP MỚI CHO TIVI 2026${NC}"
    echo -e "${BBLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    $ADB_COMMAND shell settings put secure install_non_market_apps 1 >/dev/null 2>&1
    $ADB_COMMAND shell settings put global install_non_market_apps 1 >/dev/null 2>&1
    $ADB_COMMAND shell settings put global verifier_verify_adb_installs 0 >/dev/null 2>&1

    local apks_to_install="
      3.apk 
      4.apk 
      5.apk
      6.apk"

    echo -e "${BCYAN}📦 Bắt đầu cài đặt các ứng dụng mới cho TV...${NC}"
    echo
    for apk in $apks_to_install; do
        install_apk "$apk"
    done
    
    echo -e "${BGREEN}✅ CẬP NHẬT ỨNG DỤNG HOÀN TẤT!${NC}"
    read -p "$(echo -e "${WHITE}Nhấn Enter để quay lại Menu...${NC}")"
}

copy_wallpapers() {
    local count=0
    $ADB_COMMAND shell mkdir -p "/sdcard/DCIM" >/dev/null 2>&1

    for file in *.{jpg,jpeg,png,JPG,JPEG,PNG}; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            echo -e "    → Đang gửi ảnh: ${WHITE}$filename${NC}"
            $ADB_COMMAND push "$file" "/sdcard/DCIM/$filename" >/dev/null 2>&1
            count=$((count + 1))
        fi
    done

    if [ "$count" -eq 0 ]; then
        echo -e "    ${BYELLOW}⚠️ Không tìm thấy file ảnh nào trong thư mục hiện tại.${NC}"
    else
        $ADB_COMMAND shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/DCIM" >/dev/null 2>&1
        echo -e "${BGREEN}✅ Đã gửi thành công $count ảnh vào /sdcard/DCIM/ !${NC}"
    fi
    sleep 3
}

# CHỨC NĂNG 3-4: KHỞI ĐỘNG LẠI - XOÁ DATA
reboot_tv() {
    local mode="$1"
    print_header
    
    if [ "$mode" = "recovery" ]; then
        echo -e "${BRED}⚠️ Đang gửi lệnh khởi động lại (Recovery)...${NC}"
        echo -e "${WHITE}ℹ️  Vui lòng nhìn lên màn hình Tivi.${NC}"
        echo -e "${WHITE}ℹ️  Làm theo hướng dẫn để Xoá DATA Tivi.${NC}"
        $ADB_COMMAND reboot recovery >/dev/null 2>&1 &
    else
        echo -e "${BYELLOW}🔄 Đang khởi động lại TV (Reboot)...${NC}"
        echo -e "${WHITE}ℹ️  Vui lòng chờ sau vài giây.${NC}"
        $ADB_COMMAND reboot >/dev/null 2>&1 &
    fi

    echo -e "${CYAN}→ Đã gửi lệnh reboot thành công.${NC}"
    sleep 1

    echo -e "${CYAN}→ Đang dọn dẹp và ngắt kết nối ADB hiện tại...${NC}"
    $ADB_COMMAND disconnect >/dev/null 2>&1

    echo -e "${BYELLOW}⏳ Đang chờ TV khởi động lại...${NC}"
    sleep 8

    echo -e "${BGREEN}✓ Quá trình khởi động hoàn tất!${NC}"
    echo -e "${BCYAN}→ Quay về Menu kết nối ban đầu...${NC}"
    sleep 1
    menu1
}

# =========== KHỞI CHẠY CHƯƠNG TRÌNH ===========
check_adb
menu1