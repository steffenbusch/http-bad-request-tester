#!/usr/bin/env bash

# Display usage guide
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  --host HOST       Specify the host to test against. Used as the Host header in requests."
  echo "  --port PORT       Specify the port to use. Default is 80."
  echo "  --ip IP           Specify the IP address for the nc command. If not specified, the host is used."
  echo "  --testcases FILE  Specify the .txt file(s) for test cases. Supports wildcards."
  echo "  --overview        Display an overview of filenames and HTTP response overviewes at the end."
  echo "  -h, --help        Show this help message."
  exit 1
}

# Initialize variables
host=""
port=80
ip=""
testcases="*.txt"
overview_report=false

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
    --ip)
      ip="$2"
      shift 2
      ;;
    --testcases)
      testcases="$2"
      shift 2
      ;;
    --overview)
      overview_report=true
      shift
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

# Report file and temporary response output file creation when --overview was specified
overview_file=$(mktemp)
temp_reponse_out=$(mktemp)
# Set up traps to clean up temporary files upon script exit or interruption
trap 'rm -f "$overview_file"' EXIT INT TERM
trap 'rm -f "$temp_reponse_out"' EXIT INT TERM

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
  if [ ${#modified_content} -gt 250 ]; then
    printf -- "%s...(%d more characters)\n\n" "${modified_content:0:250}" $((${#modified_content}-250))
  else
    printf -- "%s\n\n" "$modified_content"
  fi

  # Use a separator to delineate Request from Response
  printf -- "${bold}--- Server Response ---${reset}\n"

  # Send the modified content using nc, capture the server's response,
  # and save it temporarily for extracting HTTP status
  printf -- "%s" "$modified_content" | nc "${ip:-$host}" "$port" |& tee "$temp_reponse_out"

  # Extract the HTTP status code if the response starts with "HTTP", or capture the entire first line otherwise,
  # then store the filename and HTTP status (or the first line of the response) for the overview.
  http_status=$(head -n 1 "$temp_reponse_out" | awk '{if ($1 ~ /^HTTP/) print $2; else print $0}')
  printf "%2d %-36s %s\n" "$counter" "$file" "$http_status" >> "$overview_file"

  # Print a separator line
  printf -- "\n\n"

  # Increment the counter
  ((counter++))
done

# Display overview if --overview was specified
if [ "$overview_report" = true ]; then
  echo -e "\n--- Overview ---"
  while IFS= read -r line; do
    echo "$line"
  done < "$overview_file"
fi
