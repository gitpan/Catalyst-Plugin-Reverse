use inc::Module::Install;

name      'Catalyst-Plugin-Reverse';
license   'perl';
all_from  'lib/Catalyst/Plugin/Reverse.pm';

requires  'Catalyst::Runtime' => 5.80;

test_requires 'Test::More';

auto_install;

WriteAll;

