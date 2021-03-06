library(DBI)
pg <- dbConnect(RPostgreSQL::PostgreSQL())

dbGetQuery(pg, "
    CREATE SCHEMA IF NOT EXISTS taq;

    DROP TABLE IF EXISTS taq.mast;
    CREATE TABLE taq.mast
    (
      symbol text,
      name text,
      cusip text,
      fdate date,
      shrout double precision
    )")

dbDisconnect(pg)

sas_code <- "
    libname pwd '.';

    options nosource nonotes;

    proc sql;
        CREATE TABLE pwd.mast AS
        SELECT DISTINCT symbol, name, cusip, fdate, shrout
        FROM taq.mast;
    quit;"

#

# Use PostgreSQL's COPY function to get data into the database
cmd = paste0("echo \"", sas_code, "\" | ",
            "ssh -C $WRDS_ID@wrds-cloud.wharton.upenn.edu 'qsas -stdio -noterminal' 2>/dev/null ")

system(cmd)
system("psql -c 'CREATE SCHEMA IF NOT EXISTS home'")

system("./wrds_update.pl home.mast --fix-cr")

system("psql -c 'DROP TABLE IF EXISTS taq.mast'")
system("psql -c 'ALTER TABLE home.mast SET SCHEMA taq'")
system("psql -c 'DROP SCHEMA IF EXISTS home'")
