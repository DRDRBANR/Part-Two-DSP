# =========================================================
# Скрипт автоматической сборки и симуляции: Задание 3 (CDC)
# =========================================================

set project_name "cdc_sim"
set project_dir "./$project_name"

create_project -force $project_name $project_dir

add_files -norecurse ./src/cdc_pulse_sync.sv
add_files -norecurse ./src/cdc_multibit_sync.sv

add_files -fileset sim_1 -norecurse ./tb/tb_cdc.sv

set_property top tb_cdc [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

launch_simulation