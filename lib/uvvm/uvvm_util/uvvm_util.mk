adaptations_pkg-lib                         := uvvm_util
alert_hierarchy_pkg-lib                     := uvvm_util
bfm_common_pkg-lib                          := uvvm_util
data_fifo_pkg-lib                           := uvvm_util
data_queue_pkg-lib                          := uvvm_util
data_stack_pkg-lib                          := uvvm_util
generic_queue_pkg-lib                       := uvvm_util
global_signals_and_shared_variables_pkg-lib := uvvm_util
hierarchy_linked_list_pkg-lib               := uvvm_util
license_pkg-lib                             := uvvm_util
methods_pkg-lib                             := uvvm_util
protected_types_pkg-lib                     := uvvm_util
string_methods_pkg-lib                      := uvvm_util
types_pkg-lib                               := uvvm_util
uvvm_util_context-lib                       := uvvm_util

adaptations_pkg: types_pkg
alert_hierarchy_pkg: hierarchy_linked_list_pkg protected_types_pkg
protected_types_pkg: string_methods_pkg
hierarchy_linked_list_pkg: global_signals_and_shared_variables_pkg string_methods_pkg
global_signals_and_shared_variables_pkg: protected_types_pkg
bfm_common_pkg: methods_pkg
methods_pkg: license_pkg
data_fifo_pkg: data_queue_pkg
uvvm_util_context: methods_pkg bfm_common_pkg license_pkg
