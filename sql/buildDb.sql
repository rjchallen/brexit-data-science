# run in data directory.
# requires load local infile permissions

CREATE SCHEMA IF NOT EXISTS brexit_data_science;
USE brexit_data_science;

CREATE TABLE IF NOT EXISTS raw_population_series (
    lad2014_code VARCHAR(10),
    lad2014_name VARCHAR(40),
    country CHAR,
    sex INT,
    age INT,
    population_2001 INT,
    population_2002 INT,
    population_2003 INT,
    population_2004 INT,
    population_2005 INT,
    population_2006 INT,
    population_2007 INT,
    population_2008 INT,
    population_2009 INT,
    population_2010 INT,
    population_2011 INT,
    population_2012 INT,
    population_2013 INT,
    population_2014 INT,
    population_2015 INT
)  ENGINE innodb;

LOAD DATA LOCAL INFILE '2015-population-estimates.csv' INTO TABLE raw_population_series
FIELDS TERMINATED BY ','  OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES;


# uk election data
CREATE TABLE IF NOT EXISTS raw_election_result (
	constituency VARCHAR(40),
	votes INT,
	share FLOAT,
	swing FLOAT,
	constituency_id VARCHAR(10),
	region_id VARCHAR(10),
	county VARCHAR(40),
	region VARCHAR(40),
	country VARCHAR(40),
	constituency_type VARCHAR(40),
	party_name VARCHAR(40),
	party_abbreviation VARCHAR(10)
)  ENGINE innodb;

LOAD DATA LOCAL INFILE '2015-election-result.csv' INTO TABLE raw_election_result
FIELDS TERMINATED BY ','  OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
	@Forename,@Surname,@Description,@Constituency,@PANO,@Votes,@Share,@Change,@tmp1,@Incumbent,@tmp2,@ConstituencyID,@RegionID,@County,@Region,@Country,@ConstituencyType,@PartyName,@PartyAbbreviation
)
SET 
constituency=@Constituency,
votes=@Votes,
share=@Share,
swing=@Change,
constituency_id=@ConstituencyID,
region_id=@RegionID,
county=@County,
region=@Region,
country=@Country,
constituency_type=@ConstituencyType,
party_name=@PartyName,
party_abbreviation=@PartyAbbreviation
;

# uk election data
CREATE TABLE IF NOT EXISTS raw_referendum_result (
	id VARCHAR(10),
	region_code VARCHAR(10),
	region VARCHAR(40),
	area_code VARCHAR(10),
	area VARCHAR(40),
	electorate INT,
	expected_ballots INT,
	verified_ballot_papers INT,
	pct_turnout FLOAT,
	votes_cast INT,
	valid_votes INT,
	remain INT,
	`leave` INT,
	rejected_Ballots INT,
	no_official_mark INT,
	voting_for_both_answers INT,
	writing_or_mark INT,
	unmarked_or_void INT,
	pct_remain FLOAT,
	pct_leave FLOAT,
	pct_rejected FLOAT
) ENGINE innodb;

LOAD DATA LOCAL INFILE 'EU-referendum-result-data.csv' INTO TABLE raw_referendum_result
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
;

CREATE TABLE IF NOT EXISTS raw_pre_poll_bbc (
	poll_date DATE,
	`leave` FLOAT,
	remain FLOAT,
	dont_know FLOAT,
	company VARCHAR(10),
	method VARCHAR(10)
) ENGINE innodb;

LOAD DATA LOCAL INFILE 'prePollResultsBBC.tsv' INTO TABLE raw_pre_poll_bbc
FIELDS TERMINATED BY '\t' 
IGNORE 1 LINES
(@col1, `leave`, remain, dont_know, company, method) 
SET poll_date=str_to_date(@col1, '%d %b %Y')
;

CREATE TABLE IF NOT EXISTS raw_pre_poll_ft (
	poll_date DATE,
	`leave` FLOAT,
	remain FLOAT,
	dont_know FLOAT,
	company VARCHAR(10),
	sample_size INT
) ENGINE innodb;

LOAD DATA LOCAL INFILE 'prePollResultsFT.tsv' INTO TABLE raw_pre_poll_ft
FIELDS TERMINATED BY '\t' 
IGNORE 1 LINES
(remain, `leave`, dont_know, @col1, company, @col2) 
SET 
poll_date=str_to_date(@col1, '%b %d, %Y'),
sample_size=CAST(REPLACE(@col2,',','') AS UNSIGNED)
;

CREATE TABLE IF NOT EXISTS raw_oac_region_area_mapping (
	output_area_code VARCHAR(10),
	local_authority_code VARCHAR(10),
	local_authority_name VARCHAR(40),
	region_country_code VARCHAR(10),
	region_country_name VARCHAR(40),
	supergroup_code VARCHAR(10),
	supergroup_name VARCHAR(40),
	group_code VARCHAR(10),	
	group_name VARCHAR(40),
	subgroup_code VARCHAR(10),
	subgroup_name VARCHAR(40),
	INDEX (local_authority_code),
	INDEX (region_country_code)
) ENGINE innodb;

LOAD DATA LOCAL INFILE '2011-oac-clusters-and-names.csv' INTO TABLE raw_oac_region_area_mapping
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
	output_area_code,
	local_authority_code,
	local_authority_name,
	region_country_code,
	region_country_name,
	supergroup_code,
	supergroup_name,
	group_code,	
	group_name,
	subgroup_code,
	subgroup_name,
	@dummy
)
;

CREATE TABLE IF NOT EXISTS raw_wards_to_lad_mapping (
	WD14CD VARCHAR(10),
	WD14NM VARCHAR(75),
	PCON14CD VARCHAR(10),
	PCON14NM VARCHAR(75),
	LAD14CD VARCHAR(10),
	LAD14NM VARCHAR(75),
	OBJECTID VARCHAR(10),
	INDEX (LAD14CD),
	INDEX (PCON14CD)
) ENGINE innodb;

LOAD DATA LOCAL INFILE '2014-wards-to-lad-lookup.csv' INTO TABLE raw_wards_to_lad_mapping
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES;	

CREATE TABLE IF NOT EXISTS raw_region_mapping (
	region_code VARCHAR(10),
	region VARCHAR(40),
	yougov_region VARCHAR(5),
	yougov_region_name VARCHAR(40)
) ENGINE innodb;

LOAD DATA LOCAL INFILE 'regionMapping.tsv' INTO TABLE raw_region_mapping
FIELDS TERMINATED BY '\t' 
IGNORE 1 LINES
;

CREATE TABLE IF NOT EXISTS raw_yougov_poll (
	id INT,
	age INT,
	gender VARCHAR(5),
	pastvote_euref VARCHAR(5),
	vote2015r VARCHAR(5),
	social_grade VARCHAR(5),
	govregion VARCHAR(5),
	w8 FLOAT,
	q1 VARCHAR(5),
	q2 VARCHAR(5)
) ENGINE innodb;

LOAD DATA LOCAL INFILE 'poll/160721.csv' INTO TABLE raw_yougov_poll
FIELDS TERMINATED BY ',' 
IGNORE 1 LINES
(
	id,age,gender,pastvote_euref,vote2015r,social_grade,govregion,w8,@starttime,@endtime,@disposition,q1,q2
);

CREATE TABLE IF NOT EXISTS raw_yougov_poll_values (
	question VARCHAR(20),
	response VARCHAR(5),
	label VARCHAR(75),
	UNIQUE INDEX yougov_question_response (question, response)
) ENGINE innodb;

LOAD DATA LOCAL INFILE 'poll/160721_VariableValues.csv' INTO TABLE raw_yougov_poll_values
FIELDS TERMINATED BY ',' 
IGNORE 1 LINES
;
