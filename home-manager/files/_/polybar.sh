## It seems like we could theoretically get all the nessecary data (enabled and connected) 
## from /sys/class/drm/*, but it I am unsure how to map 'DP-1' to the correct 'DisplayPort-1' device.
## And since the performance impact when parsing xrandr seems not that big, we might a will just use xrandr.

xrandr_output="$(/run/current-system/sw/bin/xrandr --listactivemonitors)"
## Example xrandr output:
## Monitors: 2
## 1: +HDMI-A-0 1920/521x1080/293+0+0  HDMI-A-0
## 0: +*DisplayPort-0 1920/521x1080/293+1920+0  DisplayPort-0

regex='^([[:digit:]]):.*  (.+)$'
## Regex matches the two groups.
## The first is the monitor index, e.g. 0 or 1.
## The second is the monitor name, e.g. "HDMI-A-0" or "DisplayPort-0".

## The primary monitor is marked with an asterisk.
## In different tests in seemed like the primary monitor is always in position 0,
## so we use that instead for simplicity.

update() {
  ## kill all existing polybars
  for pid in $(/run/current-system/sw/bin/pidof polybar) ; do 
    kill $pid
  done

  ## restart polybars with new monitor layout
  start
}

start() {
  ## Loop over each line in xrandr output
  while read -r line; do
    if [[ $line =~ $regex ]]; then
      index="${BASH_REMATCH[1]}"
      name="${BASH_REMATCH[2]}"

      if [[ $index == 0 ]]; then
        bar="main"
      else
        bar="secondary"
      fi

      ## Actually start polybar in background
      MONITOR=$name polybar $bar &
    fi
  done <<< "$xrandr_output"
}

## initialize
update

## main update loop
while /run/current-system/sw/bin/sleep 10; do
  xrandr_output_new="$(/run/current-system/sw/bin/xrandr --listactivemonitors)"
  if [[ $xrandr_output != $xrandr_output_new ]]; then
    xrandr_output=$xrandr_output_new
    update
  fi
done &
