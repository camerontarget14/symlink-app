#!/bin/bash

# Function to prompt for sudo password using AppleScript
prompt_for_sudo_password() {
    osascript -e 'Tell application "System Events" to display dialog "Please enter your sudo password:" default answer "" with hidden answer' -e 'text returned of result'
}

# Function to validate the entered password
validate_sudo_password() {
    echo "$1" | sudo -S -v > /dev/null 2>&1
}

# Function to prompt for action using AppleScript
prompt_for_action() {
    osascript <<EOT
        set action_list to {"Create Symlinks", "Transfer Shot", "Archive Show", "Visit Documentation Site"}
        try
            set chosen_action to choose from list action_list with prompt "What would you like to do?"
            if chosen_action is false then
                return "CANCELLED"
            else
                return item 1 of chosen_action
            end if
        on error
            return "CANCELLED"
        end try
EOT
}

# Function to prompt for input using AppleScript
prompt_for_input() {
    prompt="$1"
    default_answer="$2"
    osascript <<EOT
        try
            set user_input to display dialog "$prompt" default answer "$default_answer"
            return text returned of user_input
        on error
            return "CANCELLED"
        end try
EOT
}

# Function to prompt for category selection using AppleScript
prompt_for_category() {
    osascript <<EOT
        set category_list to {"Film", "Series", "Music", "Commercial"}
        try
            set chosen_category to choose from list category_list with prompt "Select a category:"
            if chosen_category is false then
                return "CANCELLED"
            else
                return item 1 of chosen_category
            end if
        on error
            return "CANCELLED"
        end try
EOT
}

# Function to show a popup message using AppleScript
show_popup() {
    message="$1"
    osascript <<EOT
        display dialog "$message" buttons {"OK"} default button 1
EOT
}

# Function to open the documentation site
open_documentation_site() {
    open "https://bakedstudios.github.io/baked-docs/"
}

# Function to execute rsync command in a new terminal window
execute_rsync() {
    local source_path="$1"
    local destination_path="$2"
    osascript <<EOT
        tell application "Terminal"
            activate
            do script "rsync -avh --ignore-existing '$source_path/' '$destination_path/'"
        end tell
EOT
}

# Function to create directory and handle errors
create_directory() {
    local dir_path="$1"
    if echo "$sudo_password" | sudo -S mkdir -p "$dir_path"; then
        log_message "Created directory: $dir_path"
    else
        log_message "Error creating directory: $dir_path"
        show_popup "Error creating directory: $dir_path"
        exit 1
    fi
}

# Function to log messages
log_message() {
    log_path="/Volumes/Suite/symlink_logs.log"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_path"
}

# Function to create symbolic links
create_symlink() {
    target="$1"
    link="$2"
    if [ -L "$link" ]; then
        log_message "Symlink at $link already exists. Skipping creation."
    elif [[ -d "$target" ]]; then
        if ln -s "$target" "$link"; then
            log_message "Created symlink at $link pointing to $target"
        else
            log_message "Failed to create symlink at $link pointing to $target"
            show_popup "Failed to create symlink at $link pointing to $target"
        fi
    else
        log_message "$target is unreachable. Symlink not created."
        show_popup "$target is unreachable. If you're connected to this storage location and are still seeing this error, the project has not yet been created at this location. Otherwise, you can ignore this."
    fi
}

# Prompt for sudo password
sudo_password=$(prompt_for_sudo_password)
if [ -z "$sudo_password" ]; then
    echo "Password entry cancelled by the user."
    exit 1
fi

# Validate the sudo password
if ! validate_sudo_password "$sudo_password"; then
    show_popup "Invalid sudo password. Exiting."
    exit 1
fi

# Check if /Volumes/BAKED exists and prompt to create if not
if [ ! -d "/Volumes/BAKED" ]; then
    response=$(osascript <<EOT
        display dialog "It looks like the BAKED folder does not exist at /Volumes/BAKED - would you like to create it?" buttons {"No", "Yes"} default button "Yes"
        return button returned of result
EOT
    )

    if [ "$response" = "No" ]; then
        echo "Operation cancelled by the user."
        exit 0
    else
        create_directory "/Volumes/BAKED"
        show_popup "The BAKED folder has been created at /Volumes/BAKED."
    fi
fi

# Prompt for action
action=$(prompt_for_action)
if [ "$action" = "CANCELLED" ]; then
    echo "Operation cancelled by the user."
    exit 0
fi

case "$action" in
    "Create Symlinks")
        ;;
    "Transfer Shot")
        project_name=$(prompt_for_input "Enter the project name:" "")
        if [ "$project_name" = "CANCELLED" ]; then
            echo "Operation cancelled by the user at project name prompt."
            exit 0
        fi

        category=$(prompt_for_category)
        if [ "$category" = "CANCELLED" ]; then
            echo "Operation cancelled by the user at category selection."
            exit 0
        fi

        shot_name=$(prompt_for_input "Enter the shot name:" "")
        if [ "$shot_name" = "CANCELLED" ]; then
            echo "Operation cancelled by the user at shot name prompt."
            exit 0
        fi

        if [ -z "$project_name" ] || [ -z "$category" ] || [ -z "$shot_name" ]; then
            echo "Project name, category, or shot name cannot be empty."
            exit 0
        fi

        source_path="/Volumes/BAKED/$category/$project_name/BASKET/2_WORK/1_SEQUENCES/VFX/$shot_name"
        destination_path="/Volumes/BAKED/$category/$project_name/SUITE/2_WORK/1_SEQUENCES/VFX"

        execute_rsync "$source_path" "$destination_path"
        exit 0
        ;;
    "Archive Show")
        project_name=$(prompt_for_input "Enter the project name:" "")
        if [ "$project_name" = "CANCELLED" ]; then
            echo "Operation cancelled by the user at project name prompt."
            exit 0
        fi

        category=$(prompt_for_category)
        if [ "$category" = "CANCELLED" ]; then
            echo "Operation cancelled by the user at category selection."
            exit 0
        fi

        if [ -z "$project_name" ] || [ -z "$category" ]; then
            echo "Project name or category cannot be empty."
            exit 0
        fi

        source_path="/Volumes/BAKED/$category/$project_name/SUITE/2_WORK/1_SEQUENCES/VFX"
        destination_path="/Volumes/BAKED/$category/$project_name/BASKET/2_WORK/1_SEQUENCES"

        execute_rsync "$source_path" "$destination_path"
        exit 0
        ;;
    "Visit Documentation Site")
        open_documentation_site
        exit 0
        ;;
    *)
        echo "Unknown action. Exiting."
        exit 0
        ;;
esac

# Prompt for project name and category for Create Symlinks option
project_name=$(prompt_for_input "Enter the project name:" "")
if [ "$project_name" = "CANCELLED" ]; then
    echo "Operation cancelled by the user at project name prompt."
    exit 0
fi

category=$(prompt_for_category)
if [ "$category" = "CANCELLED" ]; then
    echo "Operation cancelled by the user at category selection."
    exit 0
fi

if [ -z "$project_name" ] || [ -z "$category" ]; then
    echo "Project name or category cannot be empty."
    exit 0
fi

base_path="/Volumes/BAKED"
project_path="$base_path/$category/$project_name"

create_directory "$project_path"

create_symlink "/Volumes/Suite/$category/$project_name" "$project_path/SUITE"
create_symlink "/Volumes/Basket/$category/$project_name" "$project_path/BASKET"

echo "Project directory and symbolic links created successfully."
exit 0
