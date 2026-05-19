# =========================================================
# Скрипт автоматической сборки и симуляции: Задание 1 (FIFO)
# =========================================================

set project_name "sync_fifo_sim"
set project_dir "./$project_name"


create_project -force $project_name $project_dir
add_files -norecurse ./src/sync_fifo_ramb36e2.sv
add_files -fileset sim_1 -norecurse ./tb/tb_sync_fifo.sv

set_property top tb_sync_fifo [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
launch_simulation