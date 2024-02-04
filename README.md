# Backups
All backed up

Take/create the database from your pet project

Implement all kinds of repository models (Full, Incremental, Differential, Reverse Delta, CDP)

Compare their parameters: size, ability to roll back at specific time point, speed of roll back, cost
## Testing steps:
* Day 1: insert 100000 record using [data.sql](scripts%2Fdata.sql)
* Day 2: insert 1000 records sequentially using [insert_users1.sql](scripts%2Finsert_users1.sql)
* Day 3: insert another 1000 records sequentially [insert_users2.sql](scripts%2Finsert_users2.sql)
* Drop and create empty database
* Restore to Day 3 state

## Full Backup

#### Backup
Day 1
```shell
docker exec -i backups-mysqldb-1 mysqldump -u root --password=admin mydb > dumpfilename.sql
```
Day 2
```shell
docker exec -i backups-mysqldb-1 mysqldump -u root --password=admin mydb > dumpfilename2.sql
```
Day 3
```shell
docker exec -i backups-mysqldb-1 mysqldump -u root --password=admin mydb > dumpfilename3.sql
```

### Restore

```shell
time docker exec -i backups-mysqldb-1 mysql -u root --password=admin mydb < dumpfilename3.sql
```
### Results

* size = dump1 + dump2 + dump3 = 3.16MB + 3.19MB + 3.22MB = 9.54 MB
* speed of roll back to Day 3  = 0m2.456s

## Incremental
Day 1 
```shell
docker exec -i backups-mysqldb-1 mysqldump -u root --password=admin --flush-logs mydb > dumpfilename.sql
```
Day 2
```shell
docker exec backups-mysqldb-1 mysqladmin -u root --password=admin flush-logs
docker exec backups-mysqldb-1 mkdir "/var/lib/mysql/backups"
docker exec backups-mysqldb-1 cp /var/lib/mysql/bin-log.000004 /var/lib/mysql/backups/day_2.000004
```
Day 3
```shell
docker exec backups-mysqldb-1 mysqladmin -u root --password=admin flush-logs
docker exec backups-mysqldb-1 cp /var/lib/mysql/bin-log.000005 /var/lib/mysql/backups/day_3.000005
```

### Restore

```shell
time docker exec -i backups-mysqldb-1 mysql -u root --password=admin mydb < dumpfilename.sql
time docker exec -i backups-mysqldb-1 sh -c "mysqlbinlog /var/lib/mysql/backups/day_2.000004 /var/lib/mysql/backups/day_3.000005 | mysql -uroot --password=admin mydb"
```

### Results

* size = dump1 + bin_log_1 + bin_log_2 = 3.16MB + 309KB + 309 KB = 3.78MB
* speed roll back to day 3 =  1.678s + 10.966s = 

## Differential
Day 1
```shell
docker exec -i backups-mysqldb-1 mysqldump -u root --password=admin --flush-logs mydb > ./dumps/dumpfilename.sql
```
Day 2
```shell
docker exec backups-mysqldb-1 mkdir "/var/lib/mysql/backups"
docker exec backups-mysqldb-1 cp /var/lib/mysql/bin-log.000004 /var/lib/mysql/backups/day_2.000004
```

Day 3
```shell
docker exec backups-mysqldb-1 cp /var/lib/mysql/bin-log.000004 /var/lib/mysql/backups/day_3.000004
```

### Restore

```shell
time docker exec -i backups-mysqldb-1 mysql -u root --password=admin mydb < dumpfilename.sql
time docker exec -i backups-mysqldb-1 sh -c "mysqlbinlog /var/lib/mysql/backups/day_3.000004 | mysql -uroot --password=admin mydb"
```

### Results
* size = dump+bin_log_1+bin_log_2 = 3.16MB + 309 KB + 618 KB = 4.1 MB
* speed roll back to day 3 = 1.799s + 11.132s = 12.93s

## Reverse Delta

Example of implementation for my case:
* Day 0
   * Create dump
* Day 1
  * Create new dump
  * Create reverse delta script 1 [reverse_delta_script_1.sql](scripts%2Freverse_delta_script_1.sql)
  * Remove previous dump
* Day 2
  * Create new dump
  * Create reverse delta script 2 [reverse_delta_script_2.sql](scripts%2Freverse_delta_script_2.sql)
  * Copy reverse delta script 1
  * Remove previous dump

#### Restore
* to day 2 - restore from dump
* to day 1 - restore from dump and run reverse delta file 2


### Results
* size = dump + reverse_delta_script_1 + reverse_delta_script_2 = 3.22MB + 0.05KB + 0.05KB = 3.23MB
* speed roll back to day 3 = 2.456s

## Results
| type          | size    | speed of roll back | ability to roll back at specific time point | cost                      |
|---------------|---------|--------------------|---------------------------------------------|---------------------------|
| Full          | 9.54 MB | 2.456 s            | to time when dump created                   | based on size the highest |
| Incremental   | 3.78 MB | 12,64 s            | to time when bin-log copied                 | the smallest              |
| Differential  | 4.1 MB  | 12.93 s            | to time when bin-log copied                 | medium                    |
| Reverse Delta | 3.23 MB | 2.456 s            | to time when reverse delta script created   | the smallest              |