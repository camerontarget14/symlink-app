#!/bin/bash

# Safety/behavior flags
set -o errexit
set -o pipefail
set -o nounset

log_path="/tmp/symlink_logs.log"
company_name_placeholder="CAMERON"
storage_one_placeholder="CLOUD"
storage_two_placeholder="PREM"
doc_site_placeholder="https://camerontarget.com"
base_path="/Volumes/$company_name_placeholder"

log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_path"
}

show_popup() {
  local message="$1"
  /usr/bin/osascript <<EOT
    display dialog "$message" buttons {"OK"} default button 1
EOT
}

prompt_for_sudo_password() {
  /usr/bin/osascript -e 'display dialog "Please enter your system password: 🔐" default answer "" with hidden answer' \
                     -e 'text returned of result'
}

validate_sudo_password() {
  echo "$1" | /usr/bin/sudo -S -v >/dev/null 2>&1
}

prompt_for_action() {
  /usr/bin/osascript <<'EOT'
    set action_list to {"Create Symlinks 🔗", "Visit Documentation Site ⚙️"}
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

prompt_for_input() {
  local prompt="$1"
  local default_answer="${2:-}"
  /usr/bin/osascript <<EOT
    try
      set user_input to display dialog "$prompt" default answer "$default_answer"
      return text returned of user_input
    on error
      return "CANCELLED"
    end try
EOT
}

prompt_for_category() {
  /usr/bin/osascript <<'EOT'
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

open_documentation_site() {
  /usr/bin/open "$doc_site_placeholder"
}

create_directory() {
  local dir_path="$1"
  if /usr/bin/sudo /bin/mkdir -p "$dir_path"; then
    log_message "Created directory: $dir_path"
  else
    log_message "Error creating directory: $dir_path"
    show_popup "Error creating directory: $dir_path"
    exit 1
  fi
}

create_symlink() {
  local target="$1"
  local link="$2"

  if [ -L "$link" ]; then
    log_message "Symlink at $link already exists. Skipping."
    return 0
  fi

  if [ -e "$link" ] && [ ! -L "$link" ]; then
    log_message "Path $link exists and is not a symlink. Skipping to avoid clobbering."
    show_popup "⚠️ $link already exists and is not a symlink. Please remove or rename it and try again."
    return 1
  fi

  if [ -d "$target" ]; then
    if /usr/bin/sudo /bin/ln -s "$target" "$link"; then
      log_message "Created symlink: $link → $target"
    else
      log_message "Failed to create symlink: $link → $target"
      show_popup "Failed to create symlink:\n$link → $target"
      return 1
    fi
  else
    log_message "Target missing/unreachable: $target"
    show_popup "$target is unreachable. Ensure you're connected 📍 or contact a project manager 🙋‍♂️."
    return 1
  fi
}

sudo_password="$(prompt_for_sudo_password || true)"
if [ -z "${sudo_password:-}" ]; then
  echo "Password entry cancelled by the user."
  exit 0
fi

if ! validate_sudo_password "$sudo_password"; then
  show_popup "⚠️ That password didn't work. Exiting."
  exit 0
fi
unset sudo_password

if [ ! -d "$base_path" ]; then
  response="$(/usr/bin/osascript -e 'display dialog "The folder does not exist at '"$base_path"'. Create it?" buttons {"No","Yes"} default button "Yes"' -e 'button returned of result' || true)"
  if [ "$response" != "Yes" ]; then
    echo "Operation cancelled by the user."
    exit 0
  fi
  create_directory "$base_path"
  show_popup "👏 The folder has been created at $base_path."
fi

# Main action
action="$(prompt_for_action)"
if [ "$action" = "CANCELLED" ]; then
  echo "Operation cancelled by the user."
  exit 0
fi

case "$action" in
  "Visit Documentation Site ⚙️")
    open_documentation_site
    exit 0
    ;;
  "Create Symlinks 🔗")
    ;;
  *)
    echo "Unknown action. Exiting."
    exit 0
    ;;
esac

project_name="$(prompt_for_input "Enter the project name:" "")"
if [ "$project_name" = "CANCELLED" ]; then
  echo "Operation cancelled by the user at project name prompt."
  exit 0
fi

category="$(prompt_for_category)"
if [ "$category" = "CANCELLED" ]; then
  echo "Operation cancelled by the user at category selection."
  exit 0
fi

if [ -z "$project_name" ] || [ -z "$category" ]; then
  show_popup "⚠️ Project name or category cannot be empty."
  exit 0
fi

project_path="$base_path/$category/$project_name"
create_directory "$project_path"

# Create symbolic links
create_symlink "/Volumes/$storage_one_placeholder/$category/$project_name"   "$project_path/$storage_one_placeholder"
create_symlink "/Volumes/$storage_two_placeholder/$category/$project_name"  "$project_path/$storage_two_placeholder"

echo "Project directory and symbolic links created successfully."
show_popup "🥳 Symlinks created. Nice one! 🎉"
exit 0
