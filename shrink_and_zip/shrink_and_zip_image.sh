#! /bin/bash
file="$1"
shrink_filename="${file/raw/shrink}"
zip_filename="${file/-raw.img/.zip}"

pishrink.sh "$file" "$shrink_filename" 
zip "$zip_filename" "$shrink_filename"
