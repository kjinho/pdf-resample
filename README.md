# pdf-resample

A script to use imagemagick to resample a given PDF.

## Installation

Make sure both [exiftool](https://exiftool.org/) and [ImageMagick](https://imagemagick.org/index.php)
are installed and callable from the command line.

Also make sure [Racket](https://racket-lang.org/) is installed, and that `racket` is in your PATH.

Place the script in any location callable from your PATH.
If necessary, modify the default locations for `exiftool` and `convert`.

## Usage

```
pdf-resample.rkt [ <option> ... ] <infile> <outfile>
  uses imagemagick to resample a given PDF <infile> into PDF <outfile>

 where <option> is one of

 basic flags
  --preserve, -p : Preserve temporary files

 customization arguments
  --resolution <num>, -r <num> : density of the resulting images
    default: 150
  --depth <num>, -d <num> : depth of the resulting images
    default: 2
  --exiftool <path>, -e <path> : path to `exiftool`
    default: /usr/local/bin/exiftool
  --convert <path>, -c <path> : path to `convert`
    default: /usr/local/bin/convert
    
 color-control options
/ --rgb : RGB colorspace (default)
| --bw : Black and white (overrides depth setting)
\ --gray : Gray colorspace

  --help, -h : Show this help
  -- : Do not treat any remaining argument as a switch (at this level)
 /|\ Brackets indicate mutually exclusive options.
 Multiple single-letter switches can be combined after one `-'; for
  example: `-h-' is the same as `-h --'

 This tool is useful for the following:
 * proper redaction of text PDFs
 * changing the filesize of over-sized image PDFs

 Remember to increase the resolution (to 200 or higher) for OCR.
```
