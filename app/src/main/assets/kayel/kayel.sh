#!/system/bin/sh
# Kayel Tweak MAX v3 (POSIX sh / BusyBox ash). Semua perubahan di-backup & bisa di-restore.
# Baru di v3: anim, tap, dark, density, fontsz, battpct, notif, sbar, screenoff, aod,
# refresh, phantom, thermal, stopbg/unstopbg, turboclean, gameboost, preset gacor.
D=${KAYEL_DIR:-/data/local/tmp/kayel_tweak}; B=$D/backup; C=$D/conf
RST=${KAYEL_RESET_FILE:-/sdcard/kayel_reset}
mkdir -p "$B" 2>/dev/null; touch "$C" "$D/disabled.list" "$D/restricted.list"
L(){ echo "$(date '+%F %T') $*" >> "$D/log.txt"; }
ok(){ case "$1" in ''|*[!A-Za-z0-9._]*) return 1;; esac; }
okv(){ case "$1" in ''|*[!0-9a-zA-Z.,_-]*) return 1;; esac; }
getv(){ if [ "$1" = dc ]; then device_config get activity_manager "$2" 2>/dev/null; else settings get "$1" "$2" 2>/dev/null; fi; }
putv(){ if [ "$1" = dc ]; then device_config put activity_manager "$2" "$3"; else settings put "$1" "$2" "$3"; fi; }
delv(){ if [ "$1" = dc ]; then device_config delete activity_manager "$2"; else settings delete "$1" "$2"; fi; }
KEYS="global:window_animation_scale global:transition_animation_scale global:animator_duration_scale global:disable_window_blurs global:wifi_scan_always_enabled global:ble_scan_always_enabled global:activity_starts_logging_enabled global:settings_enable_monitor_phantom_procs global:wifi_suspend_optimizations_enabled global:adaptive_battery_management_enabled global:private_dns_mode global:private_dns_specifier global:status_bar_show_battery_percent global:heads_up_notifications_enabled global:display_density_forced secure:long_press_timeout secure:multi_press_timeout secure:ui_night_mode secure:doze_always_on secure:icon_blacklist system:min_refresh_rate system:peak_refresh_rate system:font_scale system:screen_off_timeout dc:max_cached_processes dc:max_phantom_processes dc:use_compaction dc:process_start_async"
allowed(){ for k in $KEYS; do [ "$k" = "$1:$2" ] && return 0; done; return 1; }
lrm(){ grep -vxF "$2" "$1" > "$1.t" 2>/dev/null; mv "$1.t" "$1"; }
rest1(){ f="$B/$1__$2"; [ -f "$f" ] || return 0; v=$(cat "$f"); if [ -z "$v" ] || [ "$v" = null ]; then delv "$1" "$2"; else putv "$1" "$2" "$v"; fi; rm -f "$f"; }
setk(){ allowed "$1" "$2" || { echo "ERR key"; return 1; }; okv "$3" || { echo "ERR nilai"; return 1; }
  f="$B/$1__$2"; [ -f "$f" ] || getv "$1" "$2" > "$f"
  lrm "$C" "$(grep "^$1 $2 " "$C")" 2>/dev/null
  if [ "$3" = default ]; then rest1 "$1" "$2"; else putv "$1" "$2" "$3" && echo "$1 $2 $3" >> "$C"; fi; L "set $1 $2 $3"; }
ram(){ awk '/MemTotal/{print int($2/1024)}' /proc/meminfo; }
cachep(){ r=$(ram); if [ "$r" -le 2300 ]; then echo 10; elif [ "$r" -le 3400 ]; then echo 14; elif [ "$r" -le 4600 ]; then echo 20; else echo default; fi; }
restore(){ for f in "$B"/*__*; do [ -f "$f" ] || continue; n=${f##*/}; rest1 "${n%%__*}" "${n#*__}"; done; : > "$C"
  while read p; do [ -n "$p" ] && pm enable "$p" >/dev/null 2>&1; done < "$D/disabled.list"; : > "$D/disabled.list"
  while read p; do [ -n "$p" ] && { cmd appops set "$p" RUN_ANY_IN_BACKGROUND default; cmd appops set "$p" RUN_IN_BACKGROUND default; } >/dev/null 2>&1; done < "$D/restricted.list"; : > "$D/restricted.list"
  perfm off >/dev/null; thermal off >/dev/null
  wm density reset >/dev/null 2>&1
  mode=$(getv secure ui_night_mode); [ "$mode" = yes ] || mode=no; cmd uimode night "$mode" >/dev/null 2>&1
  L restore; echo "OK: semua kembali ke default"; }
anim(){ case "$1" in
  mati|off|ngacir) v=0;; cepat|ngebut) v=0.25;; sedang|gesit) v=0.5;; normal) v=1.0;;
  default) for k in window_animation_scale transition_animation_scale animator_duration_scale; do setk global $k default; done; echo "OK: animasi kembali standar"; return;;
  *) echo "ERR pilihan (ngacir/ngebut/gesit/normal/default)"; return 1;; esac
  for k in window_animation_scale transition_animation_scale animator_duration_scale; do setk global $k "$v"; done; echo "OK: animasi $1 — HP terasa ngacir!"; }
tap(){ case "$1" in
  cepat) setk secure long_press_timeout 250; setk secure multi_press_timeout 250; echo "OK: sentuhan lebih responsif";;
  normal|default) setk secure long_press_timeout default; setk secure multi_press_timeout default; echo "OK: sentuhan kembali normal";;
  *) echo "ERR pilihan (cepat/normal)"; return 1;; esac; }
dark(){ case "$1" in
  on|gelap) setk secure ui_night_mode yes; cmd uimode night yes >/dev/null 2>&1; echo "OK: mode gelap AKTIF";;
  off|terang) setk secure ui_night_mode no; cmd uimode night no >/dev/null 2>&1; echo "OK: mode terang AKTIF";;
  default) setk secure ui_night_mode default; echo "OK: ikut pengaturan bawaan";;
  *) echo "ERR pilihan (on/off/default)"; return 1;; esac; }
density(){ ph=$(wm density 2>/dev/null | sed -n 's/Physical density: \([0-9][0-9]*\)px/\1/p'); [ -n "$ph" ] || ph=$(getprop ro.sf.lcd_density)
  [ -n "$ph" ] || { echo "ERR: tidak bisa baca density layar"; return 1; }
  case "$1" in
    kecil|small) v=$((ph-40));; besar|big) v=$((ph+40));;
    normal|default) setk global display_density_forced default; wm density reset >/dev/null 2>&1; echo "OK: ukuran tampilan kembali standar"; return;;
    *) case "$1" in ''|*[!0-9]*) echo "ERR nilai"; return 1;; esac; v=$1;; esac
  [ "$v" -ge 300 ] 2>/dev/null || v=300
  setk global display_density_forced "$v" && { wm density "$v" >/dev/null 2>&1; echo "OK: tampilan diubah (skala $v, standar $ph)"; } }
fontsz(){ case "$1" in
  kecil) v=0.87;; normal) v=1.0;; besar) v=1.15;; banget) v=1.30;; default) v=default;;
  *) case "$1" in ''|*[!0-9.]*) echo "ERR pilihan"; return 1;; esac; v=$1;; esac
  if [ "$v" = default ]; then setk system font_scale default; echo "OK: ukuran huruf standar"; else setk system font_scale "$v" && echo "OK: ukuran huruf $v"; fi; }
screenoff(){ case "$1" in
  30s) v=30000;; 1m) v=60000;; 2m) v=120000;; 5m) v=300000;; 10m) v=600000;; never|biarin) v=86400000;; default) v=default;;
  *) echo "ERR pilihan"; return 1;; esac
  if [ "$v" = default ]; then setk system screen_off_timeout default; echo "OK: layar mati ikut bawaan"; else setk system screen_off_timeout "$v"; echo "OK: layar mati otomatis setelah $1"; fi; }
aod(){ case "$1" in
  on) setk secure doze_always_on 1; echo "OK: always-on display nyala";;
  off) setk secure doze_always_on 0; echo "OK: always-on display mati (baterai lebih awet)";;
  default) setk secure doze_always_on default; echo "OK: AOD ikut bawaan";;
  *) echo "ERR pilihan (on/off/default)"; return 1;; esac; }
battpct(){ case "$1" in
  on) setk global status_bar_show_battery_percent 1; echo "OK: persen baterai tampil di pojok atas";;
  off) setk global status_bar_show_battery_percent 0; echo "OK: persen baterai disembunyikan";;
  default) setk global status_bar_show_battery_percent default; echo "OK: ikut bawaan";;
  *) echo "ERR pilihan (on/off/default)"; return 1;; esac; }
notif(){ case "$1" in
  popup) setk global heads_up_notifications_enabled 1; echo "OK: notifikasi muncul sebagai pop-up";;
  senyap) setk global heads_up_notifications_enabled 0; echo "OK: pop-up notifikasi dimatikan (masih muncul di ikon)";;
  default) setk global heads_up_notifications_enabled default; echo "OK: ikut bawaan";;
  *) echo "ERR pilihan (popup/senyap/default)"; return 1;; esac; }
sbar(){ case "$1" in
  hide) case "$2" in ''|*[!a-z,]*) echo "ERR daftar ikon"; return 1;; esac
    cur=$(getv secure icon_blacklist); [ -z "$cur" ] || [ "$cur" = null ] && cur=
    for i in $(echo "$2" | tr ',' ' '); do case ",$cur," in *",$i,"*) ;; *) cur="${cur:+$cur,}$i";; esac; done
    setk secure icon_blacklist "$cur" && echo "OK: ikon disembunyikan: $cur";;
  unhide) case "$2" in ''|*[!a-z,]*) echo "ERR daftar ikon"; return 1;; esac
    cur=$(getv secure icon_blacklist); [ -z "$cur" ] || [ "$cur" = null ] && cur=
    for i in $(echo "$2" | tr ',' ' '); do cur=$(echo "$cur" | tr ',' '\n' | grep -vx "$i" | paste -sd, -); done
    if [ -n "$cur" ]; then setk secure icon_blacklist "$cur"; else setk secure icon_blacklist default; fi
    echo "OK: ikon dimunculkan lagi";;
  show) setk secure icon_blacklist default; echo "OK: semua ikon status bar tampil lagi";;
  *) echo "ERR (hide/unhide daftar / show)"; return 1;; esac; }
refresh(){ case "$1" in
  60|90|120) setk system min_refresh_rate "$1"; setk system peak_refresh_rate "$1"; echo "OK: layar dikunci di $1 Hz";;
  auto|default) setk system min_refresh_rate default; setk system peak_refresh_rate default; echo "OK: refresh rate kembali otomatis";;
  *) echo "ERR pilihan (60/90/120/auto)"; return 1;; esac; }
phantom(){ case "$1" in
  relax|santai) setk dc max_phantom_processes 2147483647; setk global settings_enable_monitor_phantom_procs false; echo "OK: pembunuh aplikasi belakang dikendurkan";;
  default|normal) setk dc max_phantom_processes default; setk global settings_enable_monitor_phantom_procs default; echo "OK: kembali normal";;
  *) echo "ERR pilihan (relax/default)"; return 1;; esac; }
thermal(){ case "$1" in
  on) cmd thermalservice override-status 0 >/dev/null 2>&1 && { touch "$D/thermal"; echo "OK: turbo termal AKTIF (anti-lemot saat panas). Reset otomatis saat restart."; } || echo "ERR: tidak didukung HP ini";;
  off|default) cmd thermalservice reset >/dev/null 2>&1; rm -f "$D/thermal"; echo "OK: pengatur suhu kembali normal";;
  *) echo "ERR pilihan (on/off)"; return 1;; esac; }
stopbg(){ ime=$(settings get secure default_input_method | cut -d/ -f1)
  pm list packages -3 2>/dev/null | sed 's/^package://' | while read p; do
    protq "$p" && continue; [ "$p" = "$ime" ] && continue
    cmd appops set "$p" RUN_ANY_IN_BACKGROUND ignore >/dev/null 2>&1
    cmd appops set "$p" RUN_IN_BACKGROUND ignore >/dev/null 2>&1
    grep -qxF "$p" "$D/restricted.list" || echo "$p" >> "$D/restricted.list"
  done; L stopbg; echo "OK: semua aplikasi user dibatasi di latar belakang (baterai awet, notif bisa telat)"; }
unstopbg(){ while read p; do [ -n "$p" ] && { cmd appops set "$p" RUN_ANY_IN_BACKGROUND default; cmd appops set "$p" RUN_IN_BACKGROUND default; } >/dev/null 2>&1; done < "$D/restricted.list"; : > "$D/restricted.list"; L unstopbg; echo "OK: semua pembatasan latar belakang dilepas"; }
turboclean(){ am kill-all >/dev/null 2>&1; pm trim-caches 999G >/dev/null 2>&1; cmd activity idle-maintenance >/dev/null 2>&1; sm fstrim >/dev/null 2>&1
  L turboclean; echo "OK: BERSIH TOTAL - proses latar ditutup, cache dibuang, storage dirapikan"; }
gameboost(){ perfm on >/dev/null; setk global wifi_suspend_optimizations_enabled 0 >/dev/null; am kill-all >/dev/null 2>&1; stopall >/dev/null 2>&1
  L gameboost; echo "OK: MODE GAME - performa maksimal, semua gangguan ditutup"; }
preset(){ case "$1" in
  balanced) anim sedang >/dev/null; setk global disable_window_blurs 1; setk secure long_press_timeout 300;;
  perf) anim cepat >/dev/null; tap cepat >/dev/null
    setk global disable_window_blurs 1
    setk global wifi_scan_always_enabled 0; setk global ble_scan_always_enabled 0; setk global activity_starts_logging_enabled 0
    setk dc max_cached_processes "$(cachep)"; setk dc use_compaction true; setk dc process_start_async true;;
  gaming) preset perf >/dev/null; setk global wifi_suspend_optimizations_enabled 0; phantom relax >/dev/null; perfm on >/dev/null;;
  saver) anim sedang >/dev/null
    setk global wifi_scan_always_enabled 0; setk global ble_scan_always_enabled 0
    setk dc max_cached_processes "$(cachep)"; setk dc use_compaction true
    setk secure doze_always_on 0; setk system screen_off_timeout 30000;;
  gacor) anim cepat >/dev/null; tap cepat >/dev/null
    setk global disable_window_blurs 1
    setk dc max_cached_processes "$(cachep)"; setk dc use_compaction true; setk dc process_start_async true
    phantom relax >/dev/null
    setk global wifi_scan_always_enabled 0; setk global ble_scan_always_enabled 0; setk global activity_starts_logging_enabled 0
    setk global wifi_suspend_optimizations_enabled 0
    setk global status_bar_show_battery_percent 1
    perfm on >/dev/null;;
  default) restore; return;;
  *) echo "ERR preset"; return 1;; esac; L "preset $1"; echo "OK preset $1"; }
protq(){ case "$1" in android|com.android.*|com.google.android.gms*|com.google.android.gsf*|com.google.android.webview*|com.google.android.inputmethod*|com.mediatek*|com.unisoc*|com.sprd*|com.qualcomm*|vendor.*|org.codeaurora*|frb.axeron*|moe.shizuku*|*launcher*|*systemui*|*setupwizard*|*provision*|*settings*|*telephony*|*telecom*|*keyguard*|*inputmethod*|*keyboard*|*overlay*|*permission*|*packageinstaller*|*webview*|*bluetooth*|*nfc*|*dialer*|*contacts*|*mms*|*vending*|*gms*|*gsf*|*carrier*|*.ims*) return 0;; esac; return 1; }
prot(){ protq "$1" && return 0; h=$(cmd package resolve-activity --brief -c android.intent.category.HOME -a android.intent.action.MAIN 2>/dev/null | tail -n1 | cut -d/ -f1); [ "$1" = "$h" ]; }
apps(){ case "$1" in sys) s=-s;; *) s=-3;; esac
  pm list packages $s 2>/dev/null | sed 's/^package://' | sort | while read p; do f=; protq "$p" && f=P; grep -qxF "$p" "$D/disabled.list" && f=${f}D; grep -qxF "$p" "$D/restricted.list" && f=${f}R; echo "$p|$f"; done; }
appact(){ ok "$2" || { echo "ERR paket"; return 1; }
  case "$1" in
  disable) prot "$2" && { echo "ERR paket dilindungi"; return 1; }; pm disable-user --user 0 "$2" && { grep -qxF "$2" "$D/disabled.list" || echo "$2" >> "$D/disabled.list"; };;
  enable) pm enable "$2"; lrm "$D/disabled.list" "$2";;
  restrict) prot "$2" && { echo "ERR paket dilindungi"; return 1; }; cmd appops set "$2" RUN_ANY_IN_BACKGROUND ignore; cmd appops set "$2" RUN_IN_BACKGROUND ignore; grep -qxF "$2" "$D/restricted.list" || echo "$2" >> "$D/restricted.list";;
  unrestrict) cmd appops set "$2" RUN_ANY_IN_BACKGROUND default; cmd appops set "$2" RUN_IN_BACKGROUND default; lrm "$D/restricted.list" "$2";;
  compile) cmd package compile -m speed-profile -f "$2";;
  *) echo "ERR aksi"; return 1;; esac; L "app $1 $2"; echo "OK $1 $2"; }
perfm(){ case "$1" in on) cmd power set-fixed-performance-mode-enabled true >/dev/null 2>&1; touch "$D/perfmode";; *) cmd power set-fixed-performance-mode-enabled false >/dev/null 2>&1; rm -f "$D/perfmode";; esac; echo "OK perfmode $1"; }
dns(){ case "$1" in off) setk global private_dns_mode off;; auto) setk global private_dns_mode opportunistic;; cloudflare) setk global private_dns_specifier one.one.one.one; setk global private_dns_mode hostname;; google) setk global private_dns_specifier dns.google; setk global private_dns_mode hostname;; default) setk global private_dns_mode default; setk global private_dns_specifier default;; *) echo "ERR dns"; return 1;; esac; echo "OK dns $1"; }
stopall(){ ime=$(settings get secure default_input_method | cut -d/ -f1); pm list packages -3 | sed 's/^package://' | while read p; do protq "$p" && continue; [ "$p" = "$ime" ] && continue; am force-stop "$p" >/dev/null 2>&1; done; echo "OK aplikasi pengguna dihentikan"; }
job(){ case "$1" in speed-profile|speed) m=$1;; *) echo "ERR mode"; return 1;; esac
  grep -q RUNNING "$D/job.state" 2>/dev/null && { echo "Masih berjalan"; return 0; }
  echo RUNNING > "$D/job.state"; ( cmd package compile -m "$m" $2 -a > "$D/job.log" 2>&1; echo DONE > "$D/job.state" ) >/dev/null 2>&1 &
  L "compile $m $2"; echo "Dimulai di latar belakang (biarkan HP dicas)"; }
status(){ echo "model=$(getprop ro.product.model)"; echo "brand=$(getprop ro.product.brand)"; echo "android=$(getprop ro.build.version.release)"; echo "soc=$(getprop ro.board.platform)"
  echo "ram_total=$(ram)"; echo "ram_free=$(awk '/MemAvailable/{print int($2/1024)}' /proc/meminfo)"; echo "ram_rec=$(cachep)"
  df /data 2>/dev/null | tail -n1 | awk '{print "st_total=" int($2/1024) "\nst_free=" int($4/1024)}'
  echo "battery=$(dumpsys battery 2>/dev/null | awk '/ level/{print $2}')"
  echo "charging=$(dumpsys battery 2>/dev/null | awk '/status/{print $2}')"
  echo "batt_temp=$(dumpsys battery 2>/dev/null | awk '/temperature/{print $2/10}')"
  echo "density=$(wm density 2>/dev/null | sed -n 's/Physical density: \([0-9][0-9]*\)px/\1/p')"
  echo "uptime=$(cut -d. -f1 /proc/uptime)"
  echo "perf=$([ -f "$D/perfmode" ] && echo on || echo off)"; echo "thermal=$([ -f "$D/thermal" ] && echo on || echo off)"
  echo "job=$(cat "$D/job.state" 2>/dev/null)"
  echo "n_dis=$(grep -c . "$D/disabled.list" 2>/dev/null)"; echo "n_res=$(grep -c . "$D/restricted.list" 2>/dev/null)"
  echo "n_active=$(grep -c . "$C" 2>/dev/null)"
  for k in $KEYS; do echo "v.${k%%:*}.${k#*:}=$(getv "${k%%:*}" "${k#*:}")"; done; }
case "$1" in
 status) status;; set) setk "$2" "$3" "$4" && echo "OK $3=$4";; preset) preset "$2";; restore) restore;;
 anim) anim "$2";; tap) tap "$2";; dark) dark "$2";; density) density "$2";; fontsz) fontsz "$2";;
 screenoff) screenoff "$2";; aod) aod "$2";; battpct) battpct "$2";; notif) notif "$2";; sbar) sbar "$2" "$3";;
 refresh) refresh "$2";; phantom) phantom "$2";; thermal) thermal "$2";;
 stopbg) stopbg;; unstopbg) unstopbg;; turboclean) turboclean;; gameboost) gameboost;;
 apps) apps "$2";; app) appact "$2" "$3";; compile) job "$2" "$3";;
 dns) dns "$2";; perfmode) perfm "$2";; stopall) stopall;;
 fstrim) sm fstrim 2>&1; echo "OK TRIM penyimpanan selesai";; idle) cmd activity idle-maintenance 2>&1; echo "OK idle-maintenance";;
 dexopt) cmd package bg-dexopt-job; echo "OK bg-dexopt";;
 resetcompile) echo RUNNING > "$D/job.state"; ( cmd package compile --reset -a > "$D/job.log" 2>&1; echo DONE > "$D/job.state" ) >/dev/null 2>&1 & echo "Reset compile dimulai";;
 trim) pm trim-caches 999G 2>&1; echo "OK cache dibersihkan";; killbg) am kill-all 2>&1; echo "OK proses latar belakang ditutup";;
 log) tail -n 40 "$D/log.txt" 2>/dev/null; tail -n 5 "$D/job.log" 2>/dev/null;;
 boot) sleep ${KAYEL_BOOT_DELAY:-12}; if [ -f "$RST" ]; then restore; rm -f "$RST"; else while read a b c; do [ -n "$c" ] && putv "$a" "$b" "$c"; done < "$C"; [ -f "$D/perfmode" ] && perfm on >/dev/null; L boot-apply; fi;;
 *) echo "kayel: status|set ns key val|preset balanced/perf/gaming/saver/gacor/default|anim ngacir/ngebut/gesit/normal|tap cepat/normal|dark on/off|density kecil/normal/besar|fontsz kecil/normal/besar/banget|screenoff 30s/1m/2m/5m/10m/never|aod on/off|battpct on/off|notif popup/senyap|sbar hide/unhide ikon|sbar show|refresh 60/90/120/auto|phantom relax/default|thermal on/off|turboclean|gameboost|stopbg|unstopbg|restore|apps user/sys|app disable/enable/restrict/unrestrict/compile pkg|compile speed-profile/speed [-f]|dns off/auto/cloudflare/google/default|perfmode on/off|stopall|killbg|trim|fstrim|idle|dexopt|resetcompile|log";;
esac
