set project_name "traffic_light_sim"
set project_dir "./$project_name"

create_project -force $project_name $project_dir

add_files -norecurse ./src/traffic_light.sv
add_files -fileset sim_1 -norecurse ./tb/tb_traffic_light.sv

set_property top tb_traffic_light [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

launch_simulation