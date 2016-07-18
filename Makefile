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

reports = caseload casefilingratio clearancerate civilanddomestic criminal \
	juvenile dispositionscircuit dispositionscounty agepending timelapse \
	felonydispositions

base_pdf_name = _Statistical_Summary.pdf

years = 2007 2009 2010 2011 2012 2013 2014
pdfs = $(patsubst %,%$(base_pdf_name),$(years))

caseloads = $(patsubst %,%_caseload.csv,$(years))

source_file = $(word 1,$(subst _, ,$*))$(base_pdf_name)
pages = `pdfgrep -p "$($(word 2,$(subst _, ,$*)))" $(source_file) | sed 's/:.*//g' | paste -d, -s`

tabula = java -jar ./tabula-java/target/tabula-0.9.0-jar-with-dependencies.jar 

all : $(caseloads) | $(pdfs)

%.csv : 
	$(tabula) -i -g -p $(pages) $(source_file) > $@



%_Statistical_Summary.pdf :
	wget -O $@ http://www.illinoiscourts.gov/SupremeCourt/AnnualReport/$*/StatsSumm/$*_Statistical_Summary.pdf


