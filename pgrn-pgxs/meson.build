groonga = dependency('groonga', version: '>= 14.0.0')
cc = meson.get_compiler('c')
libm = cc.find_library('m')

control_file = meson.project_source_root() / 'pgroonga.control'
pgrn_version = run_command(
  'sh', '-c',
  'grep default_version @0@ | sed -e "s/.*\'\\([0-9.]*\\)\'.*/\\1/"'.format(control_file),
  check: true
).stdout().strip()

pg_config = find_program('pg_config')
pgrn_includedir_server = run_command(pg_config, '--includedir-server', check: true).stdout().strip()
pgrn_pkglibdir = run_command(pg_config, '--pkglibdir', check: true).stdout().strip()

pgrn_include_directories = [
  include_directories('../src'),
  include_directories(pgrn_includedir_server, is_system: true),
]

pgrn_c_args = ['-DPGRN_VERSION="@0@"'.format(pgrn_version)]
if get_option('pgrn_debug')
  pgrn_c_args += ['-O0', '-g3', '-DPGROONGA_DEBUG=1']
endif

pgrn_config = {
  'sources_root': '../src',
  'include_directories': pgrn_include_directories,
  'dependencies': [groonga, libm],
  'c_args': pgrn_c_args,
  'install_dir': pgrn_pkglibdir,
  'headers_install_dir': pgrn_includedir_server,
}