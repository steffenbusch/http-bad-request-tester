#!/usr/bin/env bash

# Display usage guide
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  --host HOST       Specify the host to test against."
  echo "  --port PORT       Specify the port to use. Default is 80."
  echo "  --testcases FILE  Specify the .txt file(s) for test cases. Supports wildcards."
  echo "  -h, --help        Show this help message."
  exit 1
}

# Initialize variables
host=""
port=80
testcases="*.txt"

# Parse command-line options
while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      host="$2"
      shift 2
      ;;
    --port)
      port="$2"
      shift 2
      ;;
    --testcases)
      testcases="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      printf "Unknown parameter: %s\n" "$1"
      exit 1
      ;;
  esac
done


# ANSI color codes
if [ -z "$NO_COLOR" ] && [ -t 1 ]; then
    red='\033[0;31m'
    bold='\033[1m'
    reset='\033[0m'
else
    red=''
    bold=''
    reset=''
fi

# Check if nc is available
if ! command -v nc >/dev/null 2>&1; then
  echo "Error: nc command is not available."
  exit 1
fi

# Check if it is from the Nmap project
if ! nc --version 2>&1 | grep -iq 'nmap'; then
  echo "Error: This script requires the Ncat version of nc from the Nmap project."
  exit 1
fi

# Check if host is provided
if [ -z "$host" ]; then
    printf "Please provide a host using --host.\n"
    exit 1
fi

# Counter for processed files
counter=1

# Calculate the total number of files to be processed
total_files=$(find . -maxdepth 1 -name "$testcases" -type f | wc -l)

if [ "$total_files" -eq 0 ]; then
    printf "No matching files found for testcases: %s\n" "$testcases"
    exit 1
fi

# Loop through all matching files sorted alphabetically
for file in $(find . -maxdepth 1 -name "$testcases" -type f | sort); do
    file=${file#./}  # remove leading './' returned by find

    # Replace 'example.com' with the provided host and store it in a variable
    # Append a marker '@@@' to ensure trailing newlines are included
    modified_content=$(sed "s/example.com/$host/g" "$file"; echo '@@@')

    # Remove the marker '@@@' before sending the request
    modified_content=${modified_content%@@@}

    # Print the name and modified content of the file
    printf -- "${bold}======= Sending File: ${red}%s${reset}${bold} [Test %d/%d] =======${reset}\n\n" "$file" "$counter" "$total_files"
    printf -- "${bold}--- Request (Modified Content of the File) ---${reset}\n"
    printf -- "%s\n\n" "$modified_content"

    # Use a separator to delineate Request from Response
    printf -- "${bold}--- Server Response ---${reset}\n"

    # Send the modified content using nc and capture the server's response
    printf -- "%s" "$modified_content" | nc "$host" "$port"

    # Print a separator line
#    printf "\n============================================================\n\n"
    printf -- "\n\n"

    # Increment the counter
    ((counter++))
done
