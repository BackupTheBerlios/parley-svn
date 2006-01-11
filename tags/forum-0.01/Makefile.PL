use inc::Module::Install;

name('Forum');
abstract('Catalyst Application');
author('Chisel Wright C<< <pause@herlpacker.co.uk> >>');
version_from('lib/Forum.pm');
license('perl');

include('ExtUtils::AutoInstall');

requires( Catalyst => '5.60' );

catalyst_files();

install_script( glob('script/*.pl') );
auto_install();
&WriteAll;
