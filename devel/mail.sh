#!/bin/bash

#Parameters
to=$1
subject=$2
body=$3

#Other parameters

from="breedbasecall@localhost.sgn.cornell.edu"
boundary="ZZ_/afg6432dfgkl.94531q"
declare -a attachments
attachments=( $4 $5 )

# Build headers
{

printf '%s\n' "From: $from
To: $to
Subject: $subject
Mime-Version: 1.0
Content-Type: multipart/mixed; boundary=\"$boundary\"

--${boundary}
Content-Type: text/plain; charset=\"US-ASCII\"
Content-Transfer-Encoding: 7bit
Content-Disposition: inline

$body
"

# now loop over the attachments, guess the type
# and produce the corresponding part, encoded base64
for file in "${attachments[@]}"; do

  [ ! -f "$file" ] && echo "Warning: attachment $file not found, skipping" >&2 && continue

  mimetype=$(mimetype $file | awk '{n=split($0,a," ");print a[2]}')

  printf '%s\n' "--${boundary}
Content-Type: $mimetype
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=\"$file\"
"

  base64 "$file"
  echo
done

# print last boundary with closing --
printf '%s\n' "--${boundary}--"


} | sendmail -t -oi   # one may also use -f here to set the envelope-from
