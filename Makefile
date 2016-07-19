PG_DB = il_cj

caseload = CASELOAD SUMMARIES
casefilingratio = CASE FILING RATIO
clearancerate = CLEARANCE RATES
civilanddomestic = CIVIL AND DOMESTIC RELATIONS
criminal = CRIMINAL AND QUASI
juvenile = JUVENILE CASELOAD STATISTICS
dispositionscircuit = LAW CASE DISPOSITIONS BY CIRCUIT
dispositionscounty = LAW CASE DISPOSITIONS BY COUNTY
agepending = AGE OF PENDING CASES
timelapse = TIME LAPSE
felonydispositions = FELONY DISPOSITIONS

felonydispositions_flag = -r

base_pdf_name = _Statistical_Summary.pdf

years = 2001 2002 2003 2004 2005 2006 2007 2009 2010 2011 2013 2014
pdfs = $(patsubst %,%$(base_pdf_name),$(years))

csvs = $(patsubst %,%_%.csv,$(years))

source_file = $(word 1,$(subst _, ,$*))$(base_pdf_name)
pages = `pdfgrep -p "$($(word 2,$(subst _, ,$*)))" $(source_file) | sed 's/:.*//g' | paste -d, -s`

tabula = java -jar ./tabula-java/target/tabula-0.9.0-jar-with-dependencies.jar

raw_casefilingratio_defs = county_count TEXT, population_estimate TEXT, cases_filed TEXT, judges TEXT
raw_casefilingratio_cols = 1,2,3,4,5


all : raw_caseload raw_casefilingratio

pdf : $(pdfs)

raw_% : $(csvs)
	psql -d $(PG_DB) -c "\d $@" > /dev/null 2>&1 || \
	(psql -d $(PG_DB) -c 'CREATE TABLE $@ (area TEXT, $($@_defs), year INT)' && \
	 for year in $(years); \
	    do csvcut -c $($@_cols) "$$year"_$*.csv | \
               sed "s/$$/,$$year/" | \
               psql -d $(PG_DB) -c 'COPY $@ FROM STDIN WITH CSV HEADER' ; \
	 done)

%.csv : | $(pdfs)
	$(tabula) $($(word 2,$(subst _, ,$*))_flag) --silent -g -p $(pages) $(source_file) | tail -n+3 > $@

%_Statistical_Summary.pdf :
	wget -O $@ http://www.illinoiscourts.gov/SupremeCourt/AnnualReport/$*/StatsSumm/$*_Statistical_Summary.pdf

2001_Statistical_Summary.pdf :
	wget -O $@ http://www.illinoiscourts.gov/SupremeCourt/AnnualReport/2001/StatsSumm/pdf/full.pdf

2002_Statistical_Summary.pdf :
	wget -O $@ http://www.illinoiscourts.gov/SupremeCourt/AnnualReport/2002/StatsSumm/pdf/StatSumm_full.pdf

2003_Statistical_Summary.pdf :
	wget -O $@ http://www.illinoiscourts.gov/SupremeCourt/AnnualReport/2003/StatsSumm/pdf/statssumm_full.pdf

2004_Statistical_Summary.pdf :
	wget -O $@ http://www.illinoiscourts.gov/SupremeCourt/AnnualReport/2004/StatsSumm/pdf/2004StatsSumm.pdf

2005_Statistical_Summary.pdf :
	wget -O $@ http://www.illinoiscourts.gov/SupremeCourt/AnnualReport/2005/StatsSum/pdf/2005StatsSumm.pdf

2006_Statistical_Summary.pdf :
	wget -O $@ http://www.illinoiscourts.gov/SupremeCourt/AnnualReport/2006/Stat/2006%20Statistical%20Summary.pdf


raw_felonydispositions_defs = county TEXT, defendants TEXT, convictions TEXT, guilty_plea TEXT, bench_conviction TEXT, jury_conviction TEXT, not_guilty_bench TEXT, not_guilty_jury TEXT, remaining TEXT, death TEXT, state_imprisonment TEXT, probation TEXT, other TEXT, total TEXT
raw_felonydispositions_cols = 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16


felonydispositions : raw_felonydispositions
	psql -d $(PG_DB) -c "CREATE TABLE $@ AS \
	    SELECT DISTINCT county, \
                            REPLACE(defendants, ',','')::INT as defendants, \
                            REPLACE(guilty_plea, ',','')::INT as guilty_plea, \
                            REPLACE(bench_conviction, ',','')::INT as bench_conviction, \
                            REPLACE(jury_conviction, ',','')::INT as jury_conviction, \
                            REPLACE(not_guilty_bench, ',','')::INT as bench_acquittal, \
                            REPLACE(not_guilty_jury, ',','')::INT as jury_acquittal, \
                            REPLACE(remaining, ',','')::INT as remaining, \
                            REPLACE(death, ',','')::INT as death, \
                            REPLACE(state_imprisonment, ',','')::INT as prison, \
                            REPLACE(probation, ',','')::INT as probation, \
                            REPLACE(other, ',','')::INT as other_sentence, \
                            year::INT \
            FROM $< where defendants ~ '^[0-9,]+$$' AND county !~ '.*TOTAL'"
