# Stylix wallpaper for red-sun-whorl (Hyprland, via stylix.targets.hyprland's
# hyprpaper wiring). bubu-brain is headless and never renders stylix.image,
# so this only has to suit the laptop - no need for a separate per-host
# image split yet.
#
# Depicts the Whorl (Gene Wolfe's Solar Cycle generation ship the host is
# named for): the long sun-line and a red sun low over layered ridgelines,
# colors pulled from ancient-ruins.nix rather than a new palette so the
# desktop stays visually one piece.
{ pkgs }:

let
  theme = import ./ancient-ruins.nix;
  c = name: "#${theme.${name}}";

  svg = pkgs.writeText "red-sun-whorl-wallpaper.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2160 1350" width="2160" height="1350">
      <defs>
        <radialGradient id="sunGlow" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stop-color="${c "base0A"}" stop-opacity="0.95"/>
          <stop offset="35%" stop-color="${c "base09"}" stop-opacity="0.55"/>
          <stop offset="70%" stop-color="${c "base08"}" stop-opacity="0.18"/>
          <stop offset="100%" stop-color="${c "base08"}" stop-opacity="0"/>
        </radialGradient>
        <linearGradient id="lineGlow" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="${c "base0A"}" stop-opacity="0"/>
          <stop offset="50%" stop-color="${c "base0A"}" stop-opacity="0.55"/>
          <stop offset="100%" stop-color="${c "base0A"}" stop-opacity="0"/>
        </linearGradient>
        <radialGradient id="vignette" cx="50%" cy="45%" r="75%">
          <stop offset="0%" stop-color="${c "base00"}" stop-opacity="0"/>
          <stop offset="100%" stop-color="${c "base00"}" stop-opacity="0.55"/>
        </radialGradient>
      </defs>

      <rect x="0" y="0" width="2160" height="1350" fill="${c "base00"}"/>

      <g stroke="${c "base03"}" stroke-width="2" fill="none">
        <path d="M -200,760 A 3000,3000 0 0 1 2360,720" opacity="0.16"/>
        <path d="M -200,600 A 2600,2600 0 0 1 2360,560" opacity="0.13"/>
        <path d="M -200,430 A 2200,2200 0 0 1 2360,400" opacity="0.10"/>
      </g>

      <g fill="${c "base06"}">
        <circle cx="532.1" cy="221.8" r="2.71" opacity="0.34"/>
        <circle cx="1292.7" cy="525.3" r="2.73" opacity="0.66"/>
        <circle cx="205.1" cy="346.5" r="1.17" opacity="0.42"/>
        <circle cx="1908.6" cy="11.2" r="1.14" opacity="0.70"/>
        <circle cx="101.4" cy="496.0" r="2.19" opacity="0.36"/>
        <circle cx="982.3" cy="431.0" r="1.43" opacity="0.48"/>
        <circle cx="543.8" cy="422.2" r="2.59" opacity="0.31"/>
        <circle cx="847.9" cy="182.6" r="1.86" opacity="0.55"/>
        <circle cx="1740.0" cy="473.7" r="1.68" opacity="0.54"/>
        <circle cx="1395.9" cy="51.0" r="0.89" opacity="0.55"/>
        <circle cx="423.8" cy="488.6" r="0.86" opacity="0.30"/>
        <circle cx="127.8" cy="237.0" r="0.94" opacity="0.58"/>
        <circle cx="817.0" cy="167.5" r="2.00" opacity="0.57"/>
        <circle cx="108.8" cy="191.9" r="0.86" opacity="0.69"/>
        <circle cx="423.2" cy="320.4" r="2.42" opacity="0.75"/>
        <circle cx="164.8" cy="497.0" r="1.96" opacity="0.33"/>
        <circle cx="1259.5" cy="497.4" r="1.73" opacity="0.50"/>
        <circle cx="981.0" cy="428.2" r="1.61" opacity="0.42"/>
        <circle cx="1413.2" cy="361.8" r="2.46" opacity="0.76"/>
        <circle cx="1945.4" cy="32.6" r="2.59" opacity="0.55"/>
        <circle cx="396.6" cy="100.7" r="1.15" opacity="0.43"/>
        <circle cx="1478.2" cy="210.9" r="0.86" opacity="0.43"/>
        <circle cx="951.9" cy="186.9" r="2.66" opacity="0.62"/>
        <circle cx="1914.7" cy="10.5" r="1.64" opacity="0.38"/>
        <circle cx="1328.0" cy="143.1" r="1.33" opacity="0.47"/>
        <circle cx="900.7" cy="535.6" r="1.64" opacity="0.42"/>
        <circle cx="1607.4" cy="370.4" r="1.56" opacity="0.68"/>
        <circle cx="124.0" cy="318.3" r="1.21" opacity="0.44"/>
        <circle cx="1762.2" cy="239.4" r="1.88" opacity="0.68"/>
        <circle cx="1889.1" cy="322.5" r="2.17" opacity="0.71"/>
        <circle cx="1858.5" cy="265.2" r="2.62" opacity="0.36"/>
        <circle cx="257.6" cy="136.3" r="0.81" opacity="0.48"/>
        <circle cx="316.1" cy="183.2" r="1.37" opacity="0.49"/>
        <circle cx="1109.1" cy="13.6" r="2.15" opacity="0.70"/>
        <circle cx="651.2" cy="472.2" r="2.68" opacity="0.38"/>
        <circle cx="730.0" cy="121.6" r="0.85" opacity="0.45"/>
        <circle cx="785.8" cy="236.5" r="2.26" opacity="0.38"/>
        <circle cx="557.5" cy="306.5" r="1.77" opacity="0.46"/>
        <circle cx="2017.2" cy="73.4" r="2.76" opacity="0.61"/>
        <circle cx="581.6" cy="51.9" r="2.38" opacity="0.76"/>
        <circle cx="1030.4" cy="322.1" r="0.81" opacity="0.77"/>
        <circle cx="1039.5" cy="335.4" r="1.01" opacity="0.47"/>
        <circle cx="2140.9" cy="99.8" r="1.63" opacity="0.45"/>
        <circle cx="535.3" cy="136.9" r="2.44" opacity="0.75"/>
        <circle cx="902.4" cy="154.2" r="1.61" opacity="0.72"/>
        <circle cx="359.5" cy="227.7" r="0.90" opacity="0.29"/>
        <circle cx="190.3" cy="42.6" r="2.73" opacity="0.63"/>
        <circle cx="1154.5" cy="450.5" r="2.72" opacity="0.76"/>
        <circle cx="1060.0" cy="550.1" r="1.84" opacity="0.27"/>
        <circle cx="1390.6" cy="416.6" r="1.55" opacity="0.49"/>
        <circle cx="726.3" cy="348.9" r="2.63" opacity="0.52"/>
        <circle cx="333.1" cy="159.4" r="1.78" opacity="0.58"/>
        <circle cx="1157.9" cy="104.3" r="1.92" opacity="0.53"/>
        <circle cx="1800.2" cy="206.9" r="1.04" opacity="0.72"/>
        <circle cx="285.1" cy="33.1" r="2.29" opacity="0.53"/>
        <circle cx="1836.3" cy="449.4" r="1.67" opacity="0.65"/>
        <circle cx="1237.9" cy="392.9" r="1.66" opacity="0.54"/>
        <circle cx="1492.2" cy="407.7" r="1.62" opacity="0.43"/>
        <circle cx="2072.3" cy="241.0" r="1.11" opacity="0.78"/>
        <circle cx="1516.8" cy="428.8" r="0.88" opacity="0.75"/>
        <circle cx="605.6" cy="58.2" r="2.50" opacity="0.40"/>
        <circle cx="1039.4" cy="430.7" r="1.41" opacity="0.42"/>
        <circle cx="2089.9" cy="293.3" r="1.90" opacity="0.69"/>
        <circle cx="1918.6" cy="503.9" r="1.36" opacity="0.79"/>
        <circle cx="902.8" cy="28.5" r="1.63" opacity="0.71"/>
        <circle cx="141.6" cy="12.5" r="1.65" opacity="0.53"/>
        <circle cx="702.5" cy="135.1" r="0.91" opacity="0.74"/>
        <circle cx="426.8" cy="341.2" r="1.83" opacity="0.40"/>
        <circle cx="295.7" cy="506.6" r="1.14" opacity="0.71"/>
        <circle cx="1905.7" cy="501.6" r="1.75" opacity="0.44"/>
      </g>

      <rect x="0" y="705" width="2160" height="90" fill="url(#lineGlow)"/>
      <rect x="0" y="747" width="2160" height="6" fill="${c "base0A"}" opacity="0.9"/>

      <circle cx="1500" cy="750" r="230" fill="url(#sunGlow)"/>
      <circle cx="1500" cy="750" r="58" fill="${c "base08"}"/>
      <circle cx="1500" cy="750" r="40" fill="${c "base09"}"/>

      <polygon points="0,900 140,820 300,870 460,790 620,850 780,800 940,860 1100,810 1260,870 1420,800 1580,860 1740,810 1900,870 2060,820 2160,860 2160,1350 0,1350"
               fill="${c "base0E"}" opacity="0.45"/>

      <polygon points="0,980 180,900 360,950 540,890 720,940 900,880 1080,930 1260,890 1440,950 1620,900 1800,940 1980,890 2160,930 2160,1350 0,1350"
               fill="${c "base03"}" opacity="0.65"/>

      <polygon points="0,1120 120,1060 200,1000 260,1070 320,960 380,1080 460,1020 560,1090 640,1010 720,1100 800,860 840,1100 920,1030 1000,1110 1100,1040 1180,1120 1280,1050 1360,1130 1450,1060 1550,1140 1650,1070 1750,1150 1850,1080 1950,1160 2050,1090 2160,1150 2160,1350 0,1350"
               fill="${c "base09"}" opacity="0.88"/>

      <polygon points="0,1260 150,1200 300,1250 450,1190 600,1240 750,1180 900,1230 1050,1170 1150,1100 1190,1230 1230,1150 1270,1240 1400,1180 1550,1230 1700,1170 1850,1220 2000,1160 2160,1220 2160,1350 0,1350"
               fill="${c "base01"}"/>

      <g fill="${c "base03"}">
        <circle cx="1909.9" cy="1186.4" r="1.95" opacity="0.21"/>
        <circle cx="1339.4" cy="1184.3" r="0.91" opacity="0.32"/>
        <circle cx="872.8" cy="1238.4" r="0.89" opacity="0.29"/>
        <circle cx="1151.8" cy="1222.9" r="1.31" opacity="0.34"/>
        <circle cx="902.1" cy="1225.6" r="1.74" opacity="0.31"/>
        <circle cx="109.9" cy="1183.5" r="0.89" opacity="0.16"/>
        <circle cx="1213.9" cy="1233.2" r="1.83" opacity="0.25"/>
        <circle cx="314.4" cy="1229.3" r="1.39" opacity="0.12"/>
        <circle cx="1740.9" cy="1219.9" r="0.97" opacity="0.12"/>
        <circle cx="35.6" cy="1189.6" r="1.38" opacity="0.34"/>
      </g>

      <rect x="0" y="0" width="2160" height="1350" fill="url(#vignette)"/>
    </svg>
  '';
in
pkgs.runCommand "red-sun-whorl-wallpaper.png"
  {
    nativeBuildInputs = [ pkgs.librsvg ];
  }
  ''
    rsvg-convert -w 2160 -h 1350 ${svg} -o $out
  ''
