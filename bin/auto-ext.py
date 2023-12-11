import re
import subprocess

def configure_displays():
    # Run xrandr to get connected displays
    result = subprocess.run(['xrandr'], stdout=subprocess.PIPE)
    output = result.stdout.decode('utf-8')

    # Find connected displays that start with "DisplayPort-"
    displays = re.findall(r'DisplayPort-\d+ connected', output)

    # Extract the IDs and sort them
    display_ids = [int(re.search(r'\d+', display).group()) for display in displays]
    display_ids.sort()

    # Generate the xrandr command
    if display_ids:
        xrandr_command = "xrandr --output eDP --off "
        for i, id in enumerate(display_ids):
            if i == len(display_ids) - 1:  # Last one (highest ID) is primary
                xrandr_command += f"--output DisplayPort-{id} --primary --mode 2560x1440 --pos {2560 * i}x0 --rotate normal "
            else:
                xrandr_command += f"--output DisplayPort-{id} --mode 2560x1440 --pos {2560 * i}x0 --rotate normal "

        # Turn off other outputs
        # xrandr_command += "--output DisplayPort-10 --off --output HDMI-1-0 --off"

        return xrandr_command
    else:
        return "No DisplayPort monitors found."

# Run the function and print the command
command = configure_displays()
print(command)
