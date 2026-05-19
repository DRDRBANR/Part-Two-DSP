# =========================================================
# Скрипт автоматической сборки и симуляции: Задание 2 (AXIS Mux)
# =========================================================

set project_name "axis_mux_sim"
set project_dir "./$project_name"

create_project -force $project_name $project_dir

add_files -norecurse ./src/axis_mux.sv

add_files -fileset sim_1 -norecurse ./tb/tb_axis_mux.sv

set_property top tb_axis_mux [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

launch_simulation