# ThinkPad power script

Found at `home/silk/.local/bin/power` on the arch-backup-2026-09-03 backup
(not in `arch-reference/` - it was never pulled into the first-pass set).
Custom zsh script for the ThinkPad, never ported. Copied here verbatim so
the backup copy can be deleted without losing it.

- [ ] Package this as a home-manager script (e.g.
      `pkgs.writeShellScriptBin "power" ...` added to `home.packages`, similar
      to how `fuzzel-cliphist` is done in `modules/programs/sway.nix`) once
      it's worth another pass. Before wiring it up, double check these
      hardware assumptions still hold on red-sun-whorl (the ThinkPad X1
      Nano) - they were written against whatever ThinkPad the old Arch
      install ran on:
      - `BAT0` as the battery name under `/sys/class/power_supply/`
      - `intel_backlight` as the backlight name under
        `/sys/class/backlight/`
      - `/sys/firmware/acpi/platform_profile` existing at all (not all
        ThinkPads expose this)
      - Runtime deps: `acpi`, `brightnessctl`, plus `sudo` access to write
        to the sysfs files in `-s` mode (brightness/charge thresholds)

```zsh
#!/usr/bin/env zsh

c_think="\033[41;30m"
c_red="\033[1;31m"
c_white="\033[1;97m"
c_reset="\033[0m"

bat=$(acpi -b | cut -d':' -f2-)
temp=$(acpi -t | cut -d':' -f2-)
charge_start=$(cat /sys/class/power_supply/BAT0/charge_start_threshold)
charge_stop=$(cat /sys/class/power_supply/BAT0/charge_stop_threshold)
perf_profile=$(cat /sys/firmware/acpi/platform_profile)
brightness=$(cat /sys/class/backlight/intel_backlight/actual_brightness)
cpu_power=$(awk 'BEGIN{OFMT="%.2f"} {print $0 / 1000000}' /sys/class/power_supply/BAT0/power_now)
suspend_mode=$(cat /sys/power/mem_sleep)

printf "$c_think%s$c_reset\n"                 "ThinkPad System Info"
printf "$c_white%s$c_reset\n"                 "--------------------"
printf "$c_red%s$c_reset$c_white%s$c_reset\n" "Battery" ": ${bat#?}"
printf "$c_red%s$c_reset$c_white%s$c_reset\n" "Thermal" ": ${temp#?}"
printf "$c_red%s$c_reset$c_white%s$c_reset\n" "Power" ": ${cpu_power} W"
printf "$c_red%s$c_reset$c_white%s$c_reset\n" "Charge threshold" ": START: $charge_start STOP: $charge_stop"
printf "$c_red%s$c_reset$c_white%s$c_reset\n" "Profile" ": $perf_profile"
printf "$c_red%s$c_reset$c_white%s$c_reset\n" "Brightness" ": $brightness"
printf "$c_red%s$c_reset$c_white%s$c_reset\n" "Suspend mode" ": $suspend_mode"
printf "%s\n"                 ""

while getopts s opt; do
    case $opt in
        s)
            printf "$c_white%s$c_reset\n" "Change system parameters: 1)Brightness  2)Charge Start  3)Charge Stop"
            printf "$c_white%s$c_reset"   "Enter Selection: "
            read -n1 param
            case $param in
            	1)
                maxbrightness=$(brightnessctl max)
                currentbrightness=$(brightnessctl get)
                echo "special calculation: $(($currentbrightness / $maxbrightness))"
            		sysinfo=/sys/class/backlight/intel_backlight/brightness
            		[ ! -e $sysinfo ] && echo -e "\nFile does not exist. Script exiting..." && exit
            		echo -e "\nCurrent brightness value: $(cat $sysinfo)"
            		read -p "Set brightness (MAX VALUE: 19393): " value
            		echo $value | sudo tee $sysinfo
                    [ $? -ne 0 ] && exit
            		echo "New brightness value set to $(cat $sysinfo)"
            		exit
            		;;
            	2)
            		sysinfo=/sys/class/power_supply/BAT0/charge_start_threshold
            		[ ! -e $sysinfo ] && echo -e "\nFile does not exist. Script exiting..." && exit
            		echo -e "\nCurrent charge start value: $(cat $sysinfo)"
            		read -p "Set charge start (MAX VALUE: 0): " value
            		echo $value | sudo tee $sysinfo
                    [ $? -ne 0 ] && exit
            		echo "New charge start value set to $value"
            		exit
            		;;
            	3)
            		sysinfo=/sys/class/power_supply/BAT0/charge_stop_threshold
            		[ ! -e $sysinfo ] && echo -e "\nFile does not exist. Script exiting..." && exit
            		echo -e "\nCurrent charge stop value: $(cat $sysinfo)"
            		read -p "Set charge stop (MAX VALUE: 100): " value
            		echo $value | sudo tee $sysinfo
                    [ $? -ne 0 ] && exit
            		echo "New charge stop value set to $value"
            		exit
            		;;
            	*)
            		echo -e "\nExiting..."
            		exit
            		;;
            esac
    esac
done
```
