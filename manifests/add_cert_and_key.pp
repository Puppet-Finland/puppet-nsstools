# Loads a certificate and key into an NSS database.
#
# Parameters:
#   $certdir  - required - defaults to $title
#   $cert     - required - path to certificate in PEM format
#   $key      - required - path to unencrypted key in PEM format
#   $nickname - optional - the nickname for the NSS certificate
#   $certdir_managed - optional - is certdir managed by this module. Defaults to true
#   $password - required - password to nss database
#
# Actions:
#   loads certificate and key into the NSS database.
#
# Requires:
#   $certdir
#   $cert
#   $key
#
# Sample Usage:
#
#     nsstools::add_cert_and_key{ 'Server-Cert':
#       certdir  => '/dne',
#       cert     => '/tmp/server.crt',
#       key      => '/tmp/server.key',
#       password => 'changeme',
#     }
#
define nsstools::add_cert_and_key (
  Stdlib::Absolutepath $certdir,
  Stdlib::Absolutepath $cert,
  Stdlib::Absolutepath $key,
  String $password,
  String $nickname  = $title,
  Boolean $certdir_managed = true,
) {
  include nsstools

  nsstools::create { $certdir:
    password        => $password,
    certdir_managed => $certdir_managed,
  }

  # downcase and change spaces into _s
  $pkcs12_name = downcase(regsubst("${nickname}.p12", '[\s]', '_', 'GM'))

  exec {"generate_pkcs12_${title}":
    command => "/usr/bin/openssl pkcs12 -export -in ${cert} -inkey ${key} -password 'file:${certdir}/nss-password.txt' -out '${certdir}/${pkcs12_name}' -name '${nickname}'", # lint:ignore:140chars
    creates => "${certdir}/${pkcs12_name}",
    umask   => '7077',
    require => [
      Nsstools::Create[$certdir],
      Class['nsstools'],
    ],
  }

  exec { "add_pkcs12_${title}":
    path      => ['/usr/bin'],
    command   => "pk12util -d ${certdir} -i ${certdir}/${pkcs12_name} -w ${certdir}/nss-password.txt -k ${certdir}/nss-password.txt",
    unless    => "certutil -d ${certdir} -L -n '${nickname}'",
    logoutput => true,
    require   => [
      Exec["generate_pkcs12_${title}"],
      Nsstools::Create[$certdir],
      Class['nsstools'],
    ],
  }
}
