# Loads a certificate bundle into an NSS database.
#
# Parameters:
#   $certdir    - required - defaults to $title
#   $bundlefile - required - path to certificate bundle in PEM format
#   $trustargs  - optional - defaults to 'CT,C,C'
#   $temppath   - optional - temporary path to extract the certificates. Defaults to '/tmp/' 
# 
# Actions:
#   loads certificate and key into the NSS database.
#
# Requires:
#   $certdir
#   $cert
#
# Sample Usage:
#
#   nsstools::add_certbundle { 'mybundle':
#     bundlefile => '/tmp/mybundle.pem,
#     certdir  => '/etc/pki/foo'
#   }
#
#
define nsstools::add_certbundle(
  Stdlib::Absolutepath $bundlefile,
  Stdlib::Absolutepath $certdir,
  Stdlib::Absolutepath $temppath = '/tmp/',
  String $trustargs = 'CT,C,C',
) {
  include nsstools

  file { '/root/certextract':
    ensure  => 'present',
    content => epp('nsstools/certextract.epp', {
      'bundlefile' => $bundlefile,
      'certdir'    => $certdir,
      'temppath'   => $temppath,
      'trustargs'  => $trustargs,
    }),
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
  }

  exec { "add_certbundle_${title}":
    command     => '/root/certextract',
    logoutput   => true,
    require     => [
      Nsstools::Create[$certdir],
      Class['nsstools'],
      File['/root/certextract'],
    ],
  }
}
