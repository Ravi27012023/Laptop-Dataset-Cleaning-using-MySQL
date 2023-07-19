use laptop_dataset;

select * from laptopdata;

-- Let's create Backup
create table laptop_backup like laptopdata;
insert into laptop_backup 
select * from laptopdata;

-- Check for rows having all columns null
select * from laptopdata
where Company is null and TypeName is null and Inches is null and ScreenResolution is null and Cpu is null and Ram is null and Memory is null and
Gpu is null and OpSys is NULL and Weight is null and Price is null;

-- Add Index column in laptopdata
ALTER TABLE laptopdata
add column `index` int AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE laptopdata
modify column `index` INT first;

-- Add Index column in laptop_backup
ALTER TABLE laptop_backup
add column `index` int AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE laptop_backup
modify column `index` INT first;

-- Remove GB from the data in Ram Column
select replace(Ram,'GB','') from laptopdata;
 
-- Update the data into Ram column of laptopdata,
update laptopdata l1
SET Ram = 
(select replace(Ram,'GB','') 
FROM laptop_backup l2
WHERE l2.index = l1.index); -- Note : now Ram is in GB

-- update weight column by removing kg
update laptopdata l1
set Weight =
(select replace(Weight,'kg','') 
FROM laptop_backup l2 where l2.index=l1.index); -- Note : Now weight is in kg

-- Round off the price value ( It will not change affect the analysis )
update laptopdata l1
set Price = (select round(Price) from laptop_backup l2 
where l2.index=l1.index);

-- Price column is int type so, change it's type
alter table laptopdata modify column Price int;

-- cleaning of OpSys column
select distinct(opsys) from laptopdata;

-- Let make 3 category
-- mac
-- window
-- linux
-- no os
-- android,chrome(others)

select OpSys,
case 
	when OpSys like '%mac%' then 'macos'
    when OpSys like 'Windows%' then 'windows'
    when OpSys like '%linux%' then 'linux'
    when OpSys like 'No OS' then 'N/A'
    else 'other'
end as 'os_brand'
from laptopdata;

-- update the os_brand value in OpSys
update laptopdata
set OpSys = case 
	when OpSys like '%mac%' then 'macos'
    when OpSys like 'Windows%' then 'windows'
    when OpSys like '%linux%' then 'linux'
    when OpSys like 'No OS' then 'N/A'
    else 'other'
end;

-- In GPU column there are two pieces of information 1st - About company 2nd - model
-- we have to separate these two and have to make 2 columns and delete the current column

alter table laptopdata 
add column gpu_brand VARCHAR(255) after Gpu,
add column gpu_name VARCHAR(255) after gpu_brand;

update laptopdata l1
set gpu_brand =
(select substring_index(gpu,' ',1) from laptop_backup l2
where l2.index=l1.index);

-- backup created in laptop_backcup2
create table laptop_backup2 like laptopdata;
insert into laptop_backup2 
select * from laptopdata;

update laptopdata l1
set gpu_name =
(select replace(Gpu,gpu_brand,'') from laptop_backup2 l2
where l2.index=l1.index);

-- In Cpu column there are three pieces of information 1st - About company 2nd - model 3rd - speed
-- we have to separate these two and have to make 2 columns and delete the current column

alter table laptopdata
add column cpu_brand varchar(255) after Cpu,
add column cpu_version varchar(255) after cpu_brand,
add column cpu_speed double(10,2) after cpu_version;


update laptopdata l1
set cpu_brand =
(select substring_index(Cpu,' ',1) from laptop_backup2 l2
where l2.index=l1.index);

-- take backup of cpu_brand column in laptop_backup2
alter table laptop_backup2
add column cpu_brand varchar(255) after Cpu;

update laptop_backup2 l1
set cpu_brand =
(select cpu_brand from laptopdata l2
where l2.index=l1.index);

-- update cpu_version 
update laptopdata l1
set cpu_version =
(select replace(replace(Cpu,substring_index(Cpu,' ',-1),''),substring_index(Cpu,' ',1),'') 
from laptop_backup2 l2
where l2.index=l1.index);

-- update cpu_speed
-- Use of Cast Function
select cast(replace(substring_index(cpu,' ',-1),'GHz','') as decimal(10,2)) from laptopdata;

update laptopdata l1
set cpu_speed =
(select cast(replace(substring_index(Cpu,' ',-1),'GHz','') as decimal(10,2)) 
from laptop_backup2 l2
where l2.index=l1.index);

-- Working with ScreenResolution column
alter table laptopdata
add column touchscreen integer after ScreenResolution,
add column resolution varchar(255) after touchscreen,
add column resolution_width integer after resolution,
add column resolution_height integer after resolution_width;
            
SELECT substring_index(ScreenResolution,' ',-1),
substring_index(substring_index(ScreenResolution,' ',-1),'x',1),
substring_index(substring_index(ScreenResolution,' ',-1),'x',-1) 
from laptop_backup;

-- data added to resolution column
update laptopdata l1
set resolution =
(SELECT substring_index(ScreenResolution,' ',-1)
from laptop_backup l2
where l2.index=l1.index);

-- data added to resolution_weidth column
update laptopdata l1
set resolution_width =
(SELECT substring_index(substring_index(ScreenResolution,' ',-1),'x',1)
from laptop_backup l2
where l2.index=l1.index); -- numbers extracted is loaded to int column because of Mysql implicit type conversion, Otherwise we can do explicit type conversion by using CAST Function

-- data added to resolution_height column
update laptopdata l1
set resolution_height =
(SELECT substring_index(substring_index(ScreenResolution,' ',-1),'x',-1)
from laptop_backup l2
where l2.index=l1.index); 

-- data added to touchscreen column
update laptopdata
set touchscreen = ScreenResolution like '%Touchscreen%';

-- Working with Memory Column
-- Memory column has 3 pieces of information 1st - weather it contains only SSD or HDD or Both.
-- 2nd - Primary storage and 3rd Secondary Storage

ALTER TABLE laptopdata
ADD COLUMN memory_type VARCHAR(255) after Memory,
ADD COLUMN primary_storage integer after memory_type,
ADD COLUMN secondary_storage integer after primary_storage;

select memory,
case
	when Memory like '%SSD%' and Memory like '%HDD%' then 'HYBRID'
    when Memory like '%Flash Storage%' and Memory like '%HDD%' then 'HYBRID'
    when Memory like '%SSD%' and Memory like '%Hybrid%' then 'HYBRID'
	when Memory like '%SSD%' then 'SSD'
    when Memory like '%HDD%' then 'HDD'
    when Memory like '%Hybrid%' then 'HYBRID'
    when Memory like '%Flash Storage%' then 'FLASH STORAGE'
    else null
    end as memory_type
from laptopdata;

update laptopdata
set memory_type = case
	when Memory like '%SSD%' and Memory like '%HDD%' then 'HYBRID'
    when Memory like '%Flash Storage%' and Memory like '%HDD%' then 'HYBRID'
    when Memory like '%SSD%' and Memory like '%Hybrid%' then 'HYBRID'
	when Memory like '%SSD%' then 'SSD'
    when Memory like '%HDD%' then 'HDD'
    when Memory like '%Hybrid%' then 'HYBRID'
    when Memory like '%Flash Storage%' then 'FLASH STORAGE'
    else null
    end;
    
select Memory,
regexp_substr(substring_index(Memory,'+',1),'[0-9]+') AS primary_storage,
case
	when Memory like '%+%' then regexp_substr(substring_index(Memory,'+',-1),'[0-9]+')
    else 0
    end AS secondary_storage
from laptopdata;

update laptopdata
set primary_storage = regexp_substr(substring_index(Memory,'+',1),'[0-9]+'),
secondary_storage = case
	when Memory like '%+%' then regexp_substr(substring_index(Memory,'+',-1),'[0-9]+')
    else 0
    end;
    
-- Changed data in TB to GB
update laptopdata
set primary_storage = case
	when primary_storage <=2 then primary_storage*1024
    else primary_storage
    end;
    
update laptopdata
set secondary_storage = case
	when secondary_storage <=2 then secondary_storage*1024
    else secondary_storage
    end;


-- Cpu_version has different versions of core i5 or i7 we can simplify the information by keeping only core i5 or core i7
select Cpu_version,
case
	when Cpu_version like '%Core%'then substring_index(trim(Cpu_version),' ',2)
    else Cpu_version
    end
    from laptopdata;
    
update laptopdata
set Cpu_Version = substring_index(trim(Cpu_version),' ',2);

alter table laptopdata 
drop column ScreenResolution,
drop column Cpu,
drop column Memory,
drop column Gpu;

-- Unnamed column has no meaning or use to our analysis
-- Gpu name column has lots of different words so, on-hot encoding will create lots of columns and number. So, has no meaning to keep it.
alter table laptopdata
drop column `Unnamed: 0`,
drop column gpu_name;


-- Data Cleaning done and dusted
select * from laptopdata;