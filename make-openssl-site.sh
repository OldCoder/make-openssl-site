#!/bin/sh
# make-openssl-site.sh - OpenSSL setup script (and tutorial)
# Author:   Robert Kiraly - OldCoder from http://oldcoder.org/
# License:  C.C. Attribution-NonCommercial-ShareAlike 3.0 Unported
# Revision: 120708

#---------------------------------------------------------------------
# Important note.

# This software is provided on an  AS IS basis with ABSOLUTELY NO WAR-
# RANTY.  The  entire  risk as to the  quality and  performance of the
# software is with you.  Should the software prove defective,  you as-
# sume the cost of all necessary servicing,  repair or correction.  In
# no  event will any of the developers,  or any other party, be liable
# to  anyone for damages arising  out of use of  the software,  or in-
# ability to use the software.

#---------------------------------------------------------------------
# Program parameters.

# This  script  has  one  configuration  parameter  (CNFPATH). CNFPATH
# should specify an absolute path for the system's master copy  of the
# file "openssl.cnf".  For typical systems,  this might be one  of the
# following paths:
#
#     /etc/openssl.cnf
#     /etc/ssl/openssl.cnf
#     /usr/lib/ssl/openssl.cnf
#     /usr/share/ssl/openssl.cnf

# Note: If the user doesn't set CNFPATH, the next section tries to set
# this parameter automatically.

CNFPATH=

#---------------------------------------------------------------------
# Try to set CNFPATH automatically.

# If the user didn't set CNFPATH, this code tries to set the parameter
# in question automatically.

if [ -z "$CNFPATH" ]; then
    X=/etc/openssl.cnf
    if [ -f $X ]; then CNFPATH=$X; fi
    X=/etc/ssl/openssl.cnf
    if [ -f $X ]; then CNFPATH=$X; fi
    X=/usr/lib/ssl/openssl.cnf
    if [ -f $X ]; then CNFPATH=$X; fi
    X=/usr/share/ssl/openssl.cnf
    if [ -f $X ]; then CNFPATH=$X; fi
fi

#---------------------------------------------------------------------
# Set global variable CNFDIR.

# This code sets a variable named CNFDIR. CNFDIR specifies an absolute
# path for  the  directory that  contains  the system's master copy of
# "openssl.cnf".  Additionally,  this code performs  some  consistency
# checks related to CNFPATH.

ERR="Error: CNFPATH"
if [ -z "$CNFPATH" ]; then echo $ERR is empty; exit 1; fi
X=`echo $CNFPATH | grep "^/" | wc -l`
if [ $X -eq 0 ]; then echo $ERR must be absolute; exit 1; fi
X=`echo $CNFPATH | grep " " | wc -l`
if [ $X -gt 0 ]; then echo "$ERR can't contain spaces"; exit 1; fi
if [ \! -f $CNFPATH ]; then echo $ERR must be a file; exit 1; fi
X=`echo $CNFPATH | sed "s@/openssl\.cnf\\\$@@"`
if [ \! -d $X ]; then echo $ERR setting is invalid; exit 1; fi
CNFDIR=$X
unset ERR

#---------------------------------------------------------------------
# Set global variable DATADIR.

# This code sets a variable named DATADIR.  DATADIR specifies an abso-
# lute path  for a directory that  will hold  data files used by  this
# script's version of the  OpenSSL framework  (excluding the "openssl.
# cnf" file mentioned previously).

# You should have received a separate file named "openssl.cnf.initial"
# with this script. The basename of the directory specified by DATADIR
# (i.e., the part after the last slash) must  match the  "dir" setting
# in "openssl.cnf.initial".

# Warning:  This script deletes the directory in question and rebuilds
# it from scratch.

DATADIR=$CNFDIR/myssldata

#---------------------------------------------------------------------
# Set global variable SCRIPTDIR.

# This code  sets a variable named SCRIPTDIR.  SCRIPTDIR  specifies an
# absolute path  for the  directory that contains  this script and the
# file "openssl.cnf.initial" mentioned previously.

SCRIPTDIR=`pwd`

if [ ! -f $SCRIPTDIR/make-openssl-site.sh ]; then
    echo Error: Script must be run from directory that contains it
    exit 1
fi

if [ ! -f $SCRIPTDIR/openssl.cnf.initial ]; then
    echo Error: Script directory is missing openssl.cnf.initial
    exit 1
fi

#---------------------------------------------------------------------
# End-of-page support routine.

EndPage()
{
    answer=
    echo ; echo -n "Press Enter " ; read answer
    echo
    if [ "x$answer" == "xq" ]; then exit 1; fi
    if [ "x$answer" == "xQ" ]; then exit 1; fi
}

#---------------------------------------------------------------------
# Display introduction.

cat <<END

This is both an  OpenSSL tutorial and a runnable script.  It shows the
approaches that I'm presently using to create root certificates,  user
certificates, and private keys.  Additionally, it displays sample com-
mands that can be used to create and/or decode S/MIME messages. Every-
thing is done with "openssl" commands; i.e., "CA.pl" isn't required.

This script  creates a new OpenSSL certificate framework from scratch.
The new framework replaces the  existing framework  (both the official
framework and any previous version of this script's framework). If you
back-up the following file before you begin, you'll be able to restore
the  official framework.  To restore the official framework,  copy the
backup file back into place:

$CNFPATH

To abort the script,  press control-C at any "Press Enter" prompt,  or
type q followed by Enter.  If you  quit now,  nothing will be changed.
If you quit at a later point, you  may be left with an incomplete con-
figuration. To fix this, restore the backup or run the script again.
END
EndPage

#---------------------------------------------------------------------
# Go to root directory.

cat <<END
Some notes on pathnames
-----------------------

The key pathnames used by this script are:

"openssl.cnf" directory:  $CNFDIR
"openssl.cnf" pathname:   $CNFPATH
Data directory:           $DATADIR

Most  OpenSSL commands can be  executed from anywhere,  as long as you
specify  absolute paths for filename arguments.  If you go to the data
directory first,  you can omit directory paths for most arguments (ex-
cept for "-config" arguments).  There's at least one special case. For
technical reasons, you'll need  to execute  "openssl ca" commands from
the directory that contains "openssl.cnf".

We'll start out in the root directory (/).

Command: cd /
END
EndPage

cd / || exit 1

#---------------------------------------------------------------------
# Additional setup.

cat <<END
We're going to delete (and recreate) the  following configuration file
and data directory now.  If you don't want to do this, press control-C
or q followed by Enter.

Configuration file:  $CNFPATH
Data directory:      $DATADIR

Four objects will be created in the  data directory initially;  speci-
fically,  two  empty subdirectories  named  "certs" and "private",  an
empty file named "certindex.txt",  and a file named "serial" that con-
tains a sequence number. For more information, see the script's source
code.
END
EndPage

rm    $CNFPATH                                 || exit 1
touch $CNFPATH                                 || exit 1
rm    $CNFPATH                                 || exit 1
cp -p $SCRIPTDIR/openssl.cnf.initial $CNFPATH  || exit 1

rm -fr   $DATADIR  || exit 1
mkdir -p $DATADIR  || exit 1
cd       $DATADIR  || exit 1

mkdir -p      $DATADIR/certs          || exit 1
mkdir -p      $DATADIR/private        || exit 1
touch         $DATADIR/certindex.txt  || exit 1
echo 100001 > $DATADIR/serial         || exit 1

#---------------------------------------------------------------------
# Create a root certificate.

cat <<END
Next,  we'll create a root certificate and an  associated private key.
You'll need to select a passphrase, which we'll refer to as the master
passphrase.  Make a note of the master passphrase. Keep it secret, and
don't lose it.

You can respond to most questions with a period (.). Correct responses
should be given for Password, E-mail address, Country name, and Common
Name. Suggested response for Common Name: My Certificate Authority

Commands: pushd $DATADIR
openssl req -new -x509 -extensions v3_ca -days 9999 \\
    -out cacert.pem \\
    -keyout private/cakey.pem \\
    -config $CNFPATH

ln -s cacert.pem cacert.crt
ln -s cacert.pem \`openssl x509 -noout -hash -in cacert.pem\`.0
popd
END
EndPage

pushd $DATADIR || exit 1
openssl req -new -x509 -extensions v3_ca -days 9999 \
    -out cacert.pem \
    -keyout private/cakey.pem \
    -config $CNFPATH || exit 1

ln -s cacert.pem cacert.crt
ln -s cacert.pem \`openssl x509 -noout -hash -in cacert.pem\`.0
popd

cat <<END

Here's the files that we just created. "cacert.pem" is the root certi-
ficate. This file can be treated as public; i.e., you can give it out.
"cakey.pem" should be treated as private.
END
echo
ls -l $DATADIR/cacert.pem $DATADIR/private/cakey.pem | \
sed -e "s/^-rw......- //" -e "s/^.*root root //"
EndPage

#---------------------------------------------------------------------
# Verify the root certificate.

cat <<END
Next, we'll verify the root certificate.  Note: Error  messages  about
self-signed certificates  are normal.  If the script doesn't terminate
here, you can disregard messages of this type.

Command:

openssl verify $DATADIR/cacert.pem
END
echo
openssl verify $DATADIR/cacert.pem || exit 1
EndPage

#---------------------------------------------------------------------
# Create a sample user certificate request.

cat <<END
Next,  we'll do  the  initial setup  for a sample user.  Specifically,
we'll create two PEM files with names of the following form:

    NAME-private.pem  - Private key (must be kept private)
    NAME-request.pem  - Certificate request (only needed temporarily)

The sample user can be a real person,  or you can make somebody up for
testing purposes. Identity questions refer to the sample user, and not
to the system administrator.  As before, you can respond to most ques-
tions with a period (.).  Correct responses  should be given for Pass-
word, E-mail address, Country name, and Common Name.

Commands: pushd $DATADIR
openssl req -new -nodes -days 9999 \\
    -out johndoe-request.pem \\
    -keyout private/johndoe-private.pem \\
    -config $CNFPATH
popd
END
EndPage

pushd $DATADIR || exit 1
openssl req -new -nodes -days 9999 \
    -out johndoe-request.pem \
    -keyout private/johndoe-private.pem \
    -config $CNFPATH || exit 1
popd

echo
echo These are the two PEM files discussed previously:
echo
ls -l $DATADIR/johndoe-request.pem \
      $DATADIR/private/johndoe-private.pem | \
sed -e "s/^-rw......- //" -e "s/^.*root root //"
EndPage

#---------------------------------------------------------------------
# Create public certificate for sample user.

cat <<END
Next,  we'll  create a  PEM-format  public certificate  for the sample
user.  Third parties  will  be able to use  this certificate  (through
"openssl smime") like a public key.  Specifically,  it will allow them
to create encrypted mail that can only be decrypted by the recipient.

"openssl"  will ask you for a  passphrase during this step.  Enter the
master passphrase that you set initially.

Notes:  (a) For technical reasons,  we'll need to execute this step in
the  directory that contains "openssl.cnf".  (b) If this  step is suc-
cessful, we'll delete the "NAME-request.pem" file that we created pre-
viously (it won't be needed any longer).

Commands: pushd $CNFDIR
openssl ca -days 9999 \\
    -out $DATADIR/johndoe-public.pem \\
    -config $CNFPATH \\
    -infiles $DATADIR/johndoe-request.pem
popd
END
EndPage

pushd $CNFDIR || exit 1
openssl ca -days 9999 \
    -out $DATADIR/johndoe-public.pem \
    -config $CNFPATH \
    -infiles $DATADIR/johndoe-request.pem || exit 1
popd

rm -f $DATADIR/johndoe-request.pem

echo
echo This is the public certificate mentioned previously:
echo
ls -l $DATADIR/johndoe-public.pem | \
sed -e "s/^-rw......- //" -e "s/^.*root root //"
EndPage

#---------------------------------------------------------------------
# Create complete P12 file for sample user.

cat <<END
Next,  we'll create a P12 file that contains  both a certificate and a
private key for the sample user.  Some E-mail and/or browser  programs
use files of this type. Note: The file should be kept private.

"openssl" will ask you to select an  "Export Password" passphrase dur-
ing this step. If the sample user is a real person,  "Export Password"
can (and probably should) be set by the person in question.

Note: The "-name" setting specified here doesn't  need to be identical
to the user name specified previously.

Commands: pushd $DATADIR
openssl pkcs12 -export -name "John Q. Doe" \\
    -in johndoe-public.pem \\
    -inkey private/johndoe-private.pem \\
    -certfile cacert.pem \\
    -out johndoe-full.p12
popd
END
EndPage

pushd $DATADIR || exit 1
openssl pkcs12 -export -name "John Q. Doe" \
    -in johndoe-public.pem \
    -inkey private/johndoe-private.pem \
    -certfile cacert.pem \
    -out johndoe-full.p12 || exit 1
popd

echo
echo This is the P12 file discussed previously:
echo
ls -l $DATADIR/johndoe-full.p12 | \
sed -e "s/^-rw......- //" -e "s/^.*root root //"
EndPage

#---------------------------------------------------------------------
# Create complete PEM file for sample user.

cat <<END
Next,  we'll create a PEM file that contains  both a certificate and a
private key  for  the sample user.  This file  can  be  used  (through
"openssl smime") both to encrypt and to decrypt S/MIME messages. Note:
The file should be kept private.

"openssl" will ask you to specify an "Import Password" passphrase dur-
ing this step.  "Import Password" should be  the same as "Export Pass-
word" from the preceding step.

"openssl" will also request a "PEM pass phrase".  This should be a new
passphrase. If the sample user is a real person,  the  passphrase  can
(and probably should) be set by the person in question.

Commands:

pushd $DATADIR
openssl pkcs12 -in johndoe-full.p12 -out johndoe-full.pem
popd
END
EndPage

pushd $DATADIR || exit 1
openssl pkcs12 -in johndoe-full.p12 -out johndoe-full.pem || exit 1
popd

echo
echo This is the PEM file discussed previously:
echo
ls -l $DATADIR/johndoe-full.pem | \
sed -e "s/^-rw......- //" -e "s/^.* root root //"
EndPage

#---------------------------------------------------------------------
# Wrap it up.

cat <<END
To encrypt mail to an arbitrary user, use a command similar to:

openssl smime -sign -in message.txt \\
    -signer johndoe-full.pem -text | \\
openssl smime -encrypt -des3 -out message.smime \\
    -from "sender address" \\
    -to "recipient address" \\
    -subject "Subject goes here" \\
    johndoe-public.pem

Replace "johndoe-full.pem"   with a "*-full.pem" file for  the sender.
Replace "johndoe-public.pem" with a "*-public.pem" file for the recip-
ient.
END
EndPage

cat <<END
The recipient should be able to decrypt the mail as follows:

openssl smime -decrypt \\
    -in message.smime -inkey johndoe-private.pem > output.txt
(or)

openssl smime -decrypt \\
    -in message.smime -inkey johndoe-full.pem > output.txt

Note:  The  first case  doesn't require  anybody  to know a  password.
Therefore, it's a good idea to store "johndoe-private.pem" in a secure
location.
END
EndPage
