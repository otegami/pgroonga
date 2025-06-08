sources = files(pgrn_config['sources_root'] / 'pgroonga-check.c')

shared_module(
  'pgroonga_check',
  sources,
  dependencies: pgrn_config['dependencies'],
  include_directories: pgrn_config['include_directories'],
  c_args: pgrn_config['c_args'],
  name_prefix: '',
  install: true,
  install_dir: pgrn_config['install_dir'],
)
