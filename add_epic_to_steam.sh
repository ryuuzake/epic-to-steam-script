#!/bin/sh

check_installed() {
    cmd="$1"

    if ! command -v "$cmd" &> /dev/null; then
	echo "Error: $cmd is not installed. Please install $cmd before running this script."
	exit 1
    fi
}

check_dir() {
    directory="$1"

    if [ ! -d "$directory" ]; then
	echo "Error: Directory not found: $directory"
	exit 1
    fi
}

check_file() {
    file="$1"

    if [ -z "$file" ]; then
	echo "Error: $file not found"
	exit 1
    fi
}

get_dir() {
    directory="$1"

    if [ -z "$1" ]; then
	directory=$(gum input --width 0 --header "$2" --value "$3")
    fi

    eval "directory=\"$directory\""
    check_dir "$directory"

    echo "$directory"
}

check_installed "gum"
check_installed "steamtinkerlaunch"

games_default_dir="/home/deck/Games"
epic_default_dir="/home/deck/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/"

games_dir=$(get_dir "$1" "Epic Games Directory" "$games_default_dir")

# Find all .mancpn files in .egstore directories
mancpn_files=$(find "$games_dir" -type f -path "*/.egstore/*.mancpn")

# CSV file path
csv_file="epic_ids.csv"

# Create or clear the CSV file
echo "Game,AppName" > "$csv_file"

# Process each .mancpn file and append to the CSV file
while IFS= read -r mancpn_file; do
    # Get the parent directory (game name)
    game_name=$(basename "$(dirname "$(dirname "$mancpn_file")")")

    # Parse JSON and extract AppName using jq
    app_name=$(jq -r '.AppName' < "$mancpn_file")

    # Append to the CSV file
    echo "$game_name,$app_name" >> "$csv_file"
done <<< "$mancpn_files"

epic_dir=$(get_dir "$2" "Epic Games Compat Data Directory" "$epic_default_dir")

check_file "epic_ids.csv"

selected_game=$(gum table < epic_ids.csv -w 40,40 --height 10)
game_name=$(echo $selected_game | cut -d ',' -f 1)
game_id=$(echo $selected_game | cut -d ',' -f 2)

# Define an array of possible paths to the Epic Games Launcher executable
epic_launcher_paths=(
    "$epic_dir/pfx/drive_c/Program Files (x86)/Epic Games/Launcher/Portal/Binaries/Win32/EpicGamesLauncher.exe"
    "$epic_dir/drive_c/Program Files (x86)/Epic Games/Launcher/Portal/Binaries/Win32/EpicGamesLauncher.exe"
)

# Find the first existing path to the Epic Games Launcher executable
epic_launcher=""
for path in "${epic_launcher_paths[@]}"; do
    if [ -f "$path" ]; then
        epic_launcher="$path"
        break
    fi
done

check_file "$epic_launcher"

proton_default="GE-Proton8-23"

launch_option="STEAM_COMPAT_DATA_PATH=\"$epic_dir\" %command% -com.epicgames.launcher://apps/$game_id?action=launch"

steamtinkerlaunch addnonsteamgame -an="$game_name" -ep="$epic_launcher" -lo="$launch_option" -ct="$proton_default"

