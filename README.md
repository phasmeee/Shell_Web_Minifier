# Shell Web Minifier

A lightweight, 100% POSIX-compliant shell script (`dash` / `sh`) to minify HTML and CSS files.
The script duplicates the source web project's directory structure into a destination directory while optimizing the size of the targeted files.

## Features

* **HTML Minification:** Removal of comments, reduction of consecutive whitespaces, tabs, and line breaks.

* **CSS Minification:** Syntax cleanup, removal of unnecessary whitespaces and comments.

* **Directory Structure Preservation:** Untargeted folders and files (images, JS, PHP, etc.) are copied as-is.

* **Custom Tags Support:** Ability to provide a file containing a list of HTML tags to specifically clean up spaces around them (case-insensitive).

* **POSIX Compliant:** Runs natively and optimally, without relying on GNU `sed` or non-standard utilities.

## Usage

Options must strictly be placed **before** the source and destination directories.

```bash
./minifier.sh [OPTIONS] DIR_SOURCE DIR_DEST
```

### Available Options

| Option | Description | 
| ----- | ----- | 
| `--help` | Displays help and exits the program. | 
| `-v` | **Verbose mode:** Displays the list of minified files, their before/after sizes, and the reduction percentage. | 
| `-f` | **Force:** Overwrites the `DIR_DEST` directory if it already exists, without asking the user for confirmation. | 
| `-t TAGS_FILE` | **Custom tags:** Removes the spaces preceding and following the tags listed in the `TAGS_FILE`. | 

## Examples

**1. Basic minification with confirmation prompt (if the folder exists):**

```bash
./minifier.sh ./my_source_site ./my_minified_site
```

**2. Minification with forced overwrite and statistics display:**

```bash
./minifier.sh -v -f ./my_source_site ./my_minified_site
```

**3. Advanced minification with specific block tags cleanup (e.g., `div`, `p`, `ul`):**

```bash
./minifier.sh -v -f -t tags.txt ./my_source_site ./my_minified_site
```

## License & Context

Project carried out as part of the Computer Science Bachelor's Degree (Université Marie & Louis Pasteur).
