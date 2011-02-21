
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'add a SEE ALSO pod section',
  'dist_author' => [
    'Apocalypse <APOCAL@cpan.org>'
  ],
  'dist_name' => 'Pod-Weaver-Section-SeeAlso',
  'dist_version' => '1.002',
  'license' => 'perl',
  'module_name' => 'Pod::Weaver::Section::SeeAlso',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Moose' => '1.03',
    'Moose::Autobox' => '0.10',
    'Pod::Weaver::Role::Section' => '3.100710',
    'perl' => '5.006'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
