#!/bin/bash

set -eo pipefail

## VIASH START
par_input=work/fc/34b01dbb67178188ce8571b7c5459e/bcl2
par_output=work/fc/34b01dbb67178188ce8571b7c5459e/foo
par_sample_sheet=work/fc/34b01dbb67178188ce8571b7c5459e/sample_sheet.csv
par_test_mode=false
## VIASH END

[ -d "$par_output" ] || mkdir -p "$par_output"

bcl-convert \
  --force \
  --bcl-input-directory "$par_input" \
  --output-directory "$par_output" \
  --sample-sheet "$par_sample_sheet" \
  --first-tile-only $par_test_mode

if [ "$par_separate_reports" == true ]; then
  echo "Moving reports to its own location"
  mv "$par_output"/Reports "$par_reports"
else
  echo "Leaving reports alone"
fi
