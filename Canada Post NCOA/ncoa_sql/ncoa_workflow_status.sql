drop table if exists ncoa_workflow_status;
create table ncoa_workflow_status(
	id serial not null primary key,
  "recActiveFlag" char(1) default 'Y',
	status varchar(32),
	notes varchar(256)
);

insert into ncoa_workflow_status(status, notes)
values('NCOA Init Data', 'Succeed to import data from estate_master table.'),
('NCOA Processing', 'Succeed to export data to ncoa_submit table.'),
('NCOA Processed', 'Succeed to update data from ncoa_result table.'),
('NCOA Mover Data Applied', 'Succeed to update data to estate_master table.'),
('NCOA Mover Data Pending', 'The address does not exist in TMG database.');