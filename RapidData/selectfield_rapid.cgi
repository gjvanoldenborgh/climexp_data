#!/bin/sh
echo 'Content-Type: text/html'
echo
echo

. ./getargs.cgi
[ -z "$EMAIL" ] && EMAIL=someone@somewhere

. ./myvinkhead.cgi "Select a field" "Reconstructions based on proxy data and early instrumental records" "index,nofollow"
cat <<EOF
<form action="select.cgi" method="POST">
<input type="hidden" name="email" value="$EMAIL">
<table class="realtable" width="100%" border=0 cellspacing=0 cellpadding=0>
<tr><th colspan="3"><input type="submit" class="formbutton" value="Select field"> Choose a field and press this button</td></tr>
EOF

sed -e "s/EMAIL/$EMAIL/" ./selectfield_rapid.html

cat <<EOF
</table>

<img src='RapidData/RAPIDlogo_h60.jpg' border=0 hspace=0 vspace=0>
<img src='RapidData/SOAPlogo_h60.jpg' border=0 hspace=5 vspace=0>
<br>
Part of this page resulted from work done within the framework of the RAPID Climate Change Programme and the SOAP project

EOF

. ./myvinkfoot.cgi
