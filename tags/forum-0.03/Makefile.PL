use inc::Module::Install;

name('Forum');
abstract('Catalyst Application');
author('Chisel Wright C<< <pause@herlpacker.co.uk> >>');
version_from('lib/Forum.pm');
license('perl');

include('ExtUtils::AutoInstall');

requires(
    'Catalyst'                                      => '5.61',
    'Catalyst::Plugin::Authentication'              => '0.05',
    'Catalyst::Plugin::Authentication::Store::DBIC' => '0.04',
    'Catalyst::Plugin::Dumper'                      => '0.000001',
    'Catalyst::Plugin::Email'                       => '0.05',
    'Catalyst::Plugin::FillInForm'                  => '0.05',
    'Catalyst::Plugin::Session'                     => '0.01',
    'Catalyst::Plugin::Session::State::Cookie'      => '0.01',
    'Catalyst::Plugin::Session::Store::FastMmap'    => '0.01',
    'Catalyst::Plugin::Static::Simple'              => '0.12',
    'DBIx::Class'                                   => '0.04001',
    'Data::FormValidator'                           => '4.02',
    'Digest::MD5'                                   => '2.33',
    'List::MoreUtils'                               => '0.17',
    'Readonly'                                      => '1.03',
    'Time::Piece'                                   => '1.08',
    'YAML'                                          => '0.39',
);

catalyst_files();

install_script( glob('script/*.pl') );
#auto_install();
&WriteAll;
