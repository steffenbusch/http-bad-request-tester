# Simple HTTP Bad Request Testing Utility

## Description

This utility is a Bash script designed to automate the process of testing HTTP bad requests against a given host. It's useful for quickly performing a series of tests based on predefined `.txt` test case files.

## Features

- Easily specify the host to test against
- Specify custom port (default is 80)
- Supports wildcards for specifying multiple test cases
- Color-coded output for better readability
- Supports disabling color output

## Requirements

- Bash 4.0 or later
- Ncat version of `nc` from the Nmap project

## Installation

1. Clone this repository:

    ```bash
    git clone https://github.com/steffenbusch/http-bad-request-tester
    ```

2. Navigate into the directory:

    ```bash
    cd http-bad-request-tester
    ```

3. Make the script executable:

    ```bash
    chmod +x run.sh
    ```

## Usage

### Basic Usage

To test against a specific host:

```bash
./run.sh --host arm.stbu.net
```

To test against a specific host and port:

```bash
./run.sh --host arm.stbu.net --port 8080
```

To specify a single test case:

```bash
./run.sh --host arm.stbu.net --testcases good-request.txt
```

To specify multiple test cases using wildcards:

```bash
./run.sh --host arm.stbu.net --testcases "http0.9*"
```

## Help

For the usage guide:

```bash
./run.sh --help
```

## Disabling Color Output

To disable color output, set the NO_COLOR environment variable:

```bash
NO_COLOR=true ./run.sh --host arm.stbu.net
```

## Disclaimer

This utility is intended for educational and ethical testing purposes only. **Only run it against hosts you own or have explicit permission to test.** Unauthorized testing is illegal and unethical.

Use at your own risk. The author of this utility is not responsible for any illegal activities or misuse.
