USE brexit_data_science;

DROP TABLE IF EXISTS yougov_poll;

CREATE TABLE `yougov_poll` (
  `id` int(11) PRIMARY KEY,
  `age` int(11) DEFAULT NULL,
  `age_cat` varchar(5) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `gender` varchar(75) DEFAULT NULL,
  `q1` varchar(5) DEFAULT NULL,
  `q1_label` varchar(75) DEFAULT NULL,
  `q2` varchar(5) DEFAULT NULL,
  `q2_label` varchar(75) DEFAULT NULL,
  `pastvote_euref` varchar(5) DEFAULT NULL,
  `pastvote_euref_label` varchar(75) DEFAULT NULL,
  `vote2015r` varchar(5) DEFAULT NULL,
  `vote2015r_label` varchar(75) DEFAULT NULL,
  `govregion` varchar(5) DEFAULT NULL,
  `govregion_label` varchar(75) DEFAULT NULL,
  `social_grade` varchar(75) DEFAULT NULL,
  `yougov_weight` FLOAT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


INSERT INTO yougov_poll
SELECT p.id, p.age,
IF(p.age < 26, '18-25', IF(p.age<41, '26-40', IF(p.age<66, '41-65', '66+'))) as age_cat, 
v7.label as gender,
p.q1, 
v1.label as q1_label,
p.q2, 
v2.label as q2_label,
p.pastvote_euref,
v3.label as pastvote_euref_label,
p.vote2015r,
v4.label as vote2015r_label,
p.govregion,
v5.label as govregion_label,
v6.label as social_grade,
p.w8 as yougov_weight
FROM 
brexit_data_science.raw_yougov_poll p
LEFT JOIN brexit_data_science.raw_yougov_poll_values v1 ON (p.q1 = v1.response and v1.question = 'Q1')
LEFT JOIN brexit_data_science.raw_yougov_poll_values v2 ON (p.q2 = v2.response and v2.question = 'Q2')
LEFT JOIN brexit_data_science.raw_yougov_poll_values v3 ON (p.pastvote_euref = v3.response and v3.question = 'pastvote_EURef')
LEFT JOIN brexit_data_science.raw_yougov_poll_values v4 ON (p.vote2015r = v4.response and v4.question = 'Vote2015R')
LEFT JOIN brexit_data_science.raw_yougov_poll_values v5 ON (p.govregion = v5.response and v5.question = 'govregion')
LEFT JOIN brexit_data_science.raw_yougov_poll_values v6 ON (p.social_grade = v6.response and v6.question = 'social_grade')
LEFT JOIN brexit_data_science.raw_yougov_poll_values v7 ON (p.gender = v7.response and v7.question = 'gender')
;

DROP TABLE IF EXISTS pre_polls;

CREATE TABLE pre_polls AS
SELECT polls.*, b.method, if(f.sample_size>0, f.sample_size, NULL) as sample_size FROM (
	SELECT DISTINCT t1.poll_date,t1.company,t1.`leave`,t1.remain,IF(t1.dont_know>0,t1.dont_know,NULL) as dont_know FROM (
		SELECT poll_date,company,`leave`,remain,dont_know FROM brexit_data_science.raw_pre_poll_bbc
			UNION
		SELECT poll_date,company,`leave`,remain,dont_know FROM brexit_data_science.raw_pre_poll_ft) t1
	) polls 
LEFT JOIN raw_pre_poll_bbc b on (polls.poll_date = b.poll_date and polls.company = b.company)
LEFT JOIN raw_pre_poll_ft f on (polls.poll_date = f.poll_date and polls.company = f.company)
ORDER BY poll_date DESC
;

DROP TABLE IF EXISTS area_demographics;

CREATE TABLE `area_demographics` (
  `area_code` varchar(10) DEFAULT NULL,
  `area` varchar(40) DEFAULT NULL,
  `gender` varchar(6) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `age_cat` varchar(5) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `population` decimal(41,0) DEFAULT NULL,
  `percent_area_population` FLOAT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


INSERT INTO area_demographics
SELECT g.area_code, g.area, IF(g.sex=1,'Male','Female') as gender, g.age_cat, SUM(g.population) as population, SUM(g.population)/t.total*100 as percent_area_population
FROM 
	( 
		SELECT p.`lad2014_code` as area_code,
			p.`lad2014_name` as area,
			p.`country`,
			p.`sex`,
			p.`age`,
			IF(p.age < 25, '18-25', IF(p.age<40, '26-40', IF(p.age<65, '41-65', '66+'))) as age_cat, 
			IF(p.population_2015=0,p.population_2014,p.population_2015) as population
		FROM `brexit_data_science`.`raw_population_series` p
		WHERE p.age>16 
	) g,
	(
		SELECT q.lad2014_code as area_code, SUM(IF(q.population_2015=0,q.population_2014,q.population_2015)) as total
		FROM raw_population_series q
		GROUP BY q.lad2014_code
	) t
WHERE g.area_code = t.area_code
GROUP BY
	g.area_code, g.sex, g.age_cat
;

DROP TABLE IF EXISTS area_region_map;

CREATE TABLE `area_region_map` (
  `code` varchar(10) PRIMARY KEY,
  `name` varchar(75) DEFAULT NULL,
`type` varchar(40) DEFAULT NULL,
  `region_code` varchar(10) DEFAULT NULL,
  `region_name` varchar(75) DEFAULT NULL,
  `yougov_region` varchar(5) DEFAULT NULL,
  `yougov_region_name` varchar(75) DEFAULT NULL

) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Referendum result areas
# same as Census aeras apart from NI
INSERT INTO area_region_map
SELECT DISTINCT
	rr.area_code,
	rr.area,
	'area code',
	r.*
FROM
	raw_referendum_result rr,
	raw_region_mapping r
WHERE
	rr.region_code=r.region_code;

# Census level areas in NI
INSERT INTO area_region_map
SELECT DISTINCT
	p.lad2014_code,
	p.lad2014_name,
	'local authority (NI)',
	r.*
FROM 
	raw_population_series p,
	raw_region_mapping r
where p.country='N'
and r.region_code='N92000002'
;

# Election results
INSERT INTO area_region_map
SELECT DISTINCT
	constituency_id,
	constituency,
	'parliamentary constituency',
	r.*
FROM 
	raw_election_result p,
	raw_region_mapping r
where p.region_id=r.region_code
;

DROP TABLE IF EXISTS regional_demographics;

CREATE TABLE `regional_demographics` (
  `gender` varchar(6) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `age_cat` varchar(5) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `population` INT DEFAULT NULL,
  `yougov_region` varchar(5) DEFAULT NULL,
  `yougov_region_name` varchar(40) DEFAULT NULL,
  `percent_population_region` FLOAT DEFAULT NULL,
`percent_population_uk` FLOAT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO regional_demographics
SELECT 
	d.gender, 
	d.age_cat, 
	SUM(d.population) as population, 
	m.yougov_region, 
	m.yougov_region_name, 
	SUM(d.population)/t.total*100 as percent_population_region,
	SUM(d.population)/uk.population*100 as percent_population_uk
FROM 
	area_demographics d, 
	area_region_map m,
	( 
		SELECT x.yougov_region, SUM(y.population) as total FROM 
		area_demographics y, 
		area_region_map x
		WHERE
		x.`code`=y.area_code
		GROUP BY
		x.yougov_region
	) t,
	(
		SELECT SUM(IF(p.population_2015=0,p.population_2014,p.population_2015)) as population
		FROM `brexit_data_science`.`raw_population_series` p
		WHERE p.age>16 
	) uk
WHERE
m.`code`=d.area_code
AND
t.yougov_region = m.yougov_region
GROUP BY
m.yougov_region, d.age_cat, d.gender
;

DROP TABLE IF EXISTS area_summary;

CREATE TABLE area_summary
SELECT 
	r.area_code, 
	r.area, 
	h.area_population, 
	h.avg_age_in_area,
	POWER(SUM(POWER((g.age-h.avg_age_in_area),2)*g.age_population)/h.area_population,0.5) as std_dev_age_in_area,
	h.percent_males,
	h.area_population/t.uk_total*100 as percent_of_uk_total,
	r.electorate,
	r.valid_votes,
	r.remain,
	r.`leave`,
	r.electorate-r.valid_votes as did_not_vote,
	r.remain/r.electorate*100 as percent_remain,
	r.`leave`/r.electorate*100 as percent_leave,
	(r.electorate-r.valid_votes)/r.electorate*100 as percent_did_not_vote
FROM 
	raw_referendum_result r LEFT JOIN
	( 
		SELECT p.`lad2014_code` as area_code,
			p.`lad2014_name` as area,
			p.`country`,
			p.`age`,
			p.`sex`,
			IF(p.`population_2015`=0,p.`population_2014`,p.`population_2015`) as age_population
		FROM `brexit_data_science`.`raw_population_series` p
		WHERE p.age>16 
	) g ON g.area_code = r.area_code LEFT JOIN
	( 
		SELECT q.lad2014_code as area_code,
			SUM(IF(q.population_2015=0,q.population_2014,q.population_2015)) as area_population,
			SUM(IF(q.population_2015=0,q.population_2014,q.population_2015)*q.age)/SUM(IF(q.population_2015=0,q.population_2014,q.population_2015)) as avg_age_in_area,
			SUM(IF(q.sex=1,
				IF(q.population_2015=0,q.population_2014,q.population_2015)
				,0)
			)/SUM(IF(q.population_2015=0,q.population_2014,q.population_2015))*100 as percent_males
		FROM raw_population_series q
		WHERE q.age>16 
		GROUP BY
			area_code
	) h ON g.area_code = h.area_code,
	(
		SELECT SUM(IF(p.`population_2015`=0,p.`population_2014`,p.`population_2015`)) as uk_total
		FROM `brexit_data_science`.`raw_population_series` p
	) t
GROUP BY
	g.area_code
;

DROP TABLE IF EXISTS regional_summary;

CREATE TABLE regional_summary
SELECT 
	g.yougov_region,
	g.yougov_region_name,
	h.region_population as size, 
	h.avg_age_in_region,
	POWER(SUM(POWER((g.age-h.avg_age_in_region),2)*g.age_population)/h.region_population,0.5) as std_dev_age_in_region,
	h.percent_males,
	h.region_population/t.uk_total*100 as percent_of_total,
	r.electorate,
	r.valid_votes,
	r.remain,
	r.`leave`,
	r.electorate-r.valid_votes as did_not_vote,
	r.remain/r.electorate*100 as percent_remain,
	r.`leave`/r.electorate*100 as percent_leave,
	(r.electorate-r.valid_votes)/r.electorate*100 as percent_did_not_vote,
	el.con_votes,
	el.lab_votes,
	el.ukip_votes,
	el.ld_votes,
#	el.snp_votes,
	el.green_votes,
	el.other_votes
FROM 
	( 
		SELECT 
			ar.yougov_region,
			ar.yougov_region_name,
			p.country,
			p.age,
			p.sex,
			IF(p.population_2015=0,p.population_2014,p.population_2015) as age_population
		FROM 
			raw_population_series p, 
			area_region_map ar
		WHERE p.age>16 and p.lad2014_code=ar.code
	) g,
	( 
		SELECT 
			ar.yougov_region,
			SUM(IF(q.population_2015=0,q.population_2014,q.population_2015)) as region_population,
			SUM(IF(q.population_2015=0,q.population_2014,q.population_2015)*q.age)/SUM(IF(q.population_2015=0,q.population_2014,q.population_2015)) as avg_age_in_region,
			SUM(
				IF(q.sex=1,
					IF(q.population_2015=0,q.population_2014,q.population_2015)
					,0
				)
			)/SUM(IF(q.population_2015=0,q.population_2014,q.population_2015))*100 as percent_males
		FROM 
			raw_population_series q, 
			area_region_map ar
		WHERE 
			q.age>16 and q.lad2014_code=ar.`code`
		GROUP BY
			ar.yougov_region
	) h,
	(
		SELECT SUM(IF(p.`population_2015`=0,p.`population_2014`,p.`population_2015`)) as uk_total
		FROM `brexit_data_science`.`raw_population_series` p
		WHERE 
			p.age>16
	) t,
	(	SELECT 
			ar.yougov_region,
			SUM(rr.electorate) as electorate,
			SUM(rr.valid_votes) as valid_votes,
			SUM(rr.remain) as remain,
			SUM(rr.`leave`) as `leave`
		FROM
			raw_referendum_result rr,
			area_region_map ar
		WHERE rr.area_code = ar.`code`
		GROUP BY ar.yougov_region
	) r,
	(
		SELECT
			ar.yougov_region,
			SUM(IF(el.party_abbreviation='Con',votes,0))/sum(votes)*100 as con_votes,
			SUM(IF(el.party_abbreviation='Lab',votes,0))/sum(votes)*100 as lab_votes,
			SUM(IF(el.party_abbreviation='UKIP',votes,0))/sum(votes)*100 as ukip_votes,
			SUM(IF(el.party_abbreviation='LD',votes,0))/sum(votes)*100 as ld_votes,
			# SUM(IF(el.party_abbreviation='SNP',votes,0))/sum(votes)*100 as snp_votes,
			SUM(IF(el.party_abbreviation='Green',votes,0))/sum(votes)*100 as green_votes,
			SUM(IF(el.party_abbreviation NOT IN ('Con','Lab','UKIP','LD', /*'SNP',*/ 'Green'),votes,0))/sum(votes)*100 as other_votes
		FROM
			raw_election_result el,
			area_region_map ar
		WHERE
			el.constituency_id = ar.code and el.party_abbreviation <> ""
		GROUP BY ar.yougov_region
	) el
	# The areas_codes do not map 1:1 to consitutuencies. This will always result in some inconsistencies and double counting, versus general election stats.
	# Hence the normalisation to percentages. (e.g. Exeter area includes Exeter and East Devon constituencies hence looks to be conservative but is in fact labour.)
WHERE
	g.yougov_region = h.yougov_region AND
	g.yougov_region = r.yougov_region AND
	g.yougov_region = el.yougov_region
GROUP BY
	g.yougov_region
;

DROP TABLE IF EXISTS sample_summary;

CREATE TABLE sample_summary AS
SELECT 
	p.`govregion` as yougov_region,
    p.`govregion_label` as yougov_region_name,    
	COUNT(*) as size,
	AVG(p.`age`) as avg_age_in_region,
    STDDEV(p.`age`) as std_dev_age_in_region,
	SUM(IF(p.`gender`='Male',1,0))/COUNT(*)*100 as percent_males,
	COUNT(*) / t.total*100 as percent_of_total,
	COUNT(*) as electorate,
	COUNT(*)-SUM(IF(p.`pastvote_euref`=3,1,0)) as valid_votes,
    SUM(IF(p.`pastvote_euref`=1,1,0)) as remain,
	SUM(IF(p.`pastvote_euref`=2,1,0)) as `leave`,
	SUM(IF(p.`pastvote_euref`=3,1,0)) as didnt_vote,
	SUM(IF(p.`pastvote_euref`=1,1,0))/(COUNT(*)-SUM(IF(p.`pastvote_euref`=4,1,0)))*100 as percent_remain, # 4 - represents a cant remember, these people voted but wont tell which way. They are excluded for the bias analysis.
	SUM(IF(p.`pastvote_euref`=2,1,0))/(COUNT(*)-SUM(IF(p.`pastvote_euref`=4,1,0)))*100 as percent_leave,
	SUM(IF(p.`pastvote_euref`=3,1,0))/(COUNT(*)-SUM(IF(p.`pastvote_euref`=4,1,0)))*100 as percent_didnt_vote,
	SUM(IF(p.vote2015r=1,1,0))/SUM(IF(p.vote2015r in (1,2,3,4,5,6),1,0))*100 as con_votes,
	SUM(IF(p.vote2015r=2,1,0))/SUM(IF(p.vote2015r in (1,2,3,4,5,6),1,0))*100 as lab_votes,
	SUM(IF(p.vote2015r=4,1,0))/SUM(IF(p.vote2015r in (1,2,3,4,5,6),1,0))*100 as ukip_votes,
	SUM(IF(p.vote2015r=3,1,0))/SUM(IF(p.vote2015r in (1,2,3,4,5,6),1,0))*100 as ld_votes,
    SUM(IF(p.vote2015r=5,1,0))/SUM(IF(p.vote2015r in (1,2,3,4,5,6),1,0))*100 as green_votes,
	SUM(IF(p.vote2015r=6,1,0))/SUM(IF(p.vote2015r in (1,2,3,4,5,6),1,0))*100 as other_votes,
	100-SUM(IF(p.vote2015r=7,1,0))/COUNT(*)*100 as turnout_est
    # `yougov_poll`.`vote2015r`,
    # `yougov_poll`.`vote2015r_label`,
FROM `brexit_data_science`.`yougov_poll` p,
	( SELECT COUNT(*) as total FROM  `yougov_poll` ) t
GROUP BY govregion;

DROP TABLE IF exists change_2015_2016;
CREATE TABLE change_2015_2016
SELECT 
b.party_abbreviation,
SUM(e.votes) as votes_2015,
SUM(b.votes) as votes_2016,
SUM(b.votes)/SUM(e.votes) as change_ratio
FROM brexit_data_science.2016_by_elections b, raw_election_result e
where b.constituency_id = e.constituency_id
and b.party_abbreviation = e.party_abbreviation
GROUP BY b.party_abbreviation
;

DROP TABLE IF EXISTS pred_gen_election_2016;

CREATE TABLE pred_gen_election_2016 as
SELECT 
r.candidate,
r.constituency,
r.votes as votes_2015,
IF(c.change_ratio IS NULL, r.votes, r.votes*c.change_ratio) as pred_votes_2016,
r.party_abbreviation
FROM 
raw_election_result r LEFT OUTER JOIN brexit_data_science.change_2015_2016 c
ON c.party_abbreviation = r.party_abbreviation
;

DROP TABLE IF EXISTS pred_winners_2016;
CREATE TABLE pred_winners_2016
SELECT
a.*
FROM 
pred_gen_election_2016 a LEFT OUTER JOIN
pred_gen_election_2016 b
ON
a.constituency = b.constituency
and 
a.pred_votes_2016 < b.pred_votes_2016
WHERE b.pred_votes_2016 is null;


DROP TABLE IF EXISTS winners_2015;
CREATE TABLE winners_2015
SELECT
a.*
FROM 
pred_gen_election_2016 a LEFT OUTER JOIN
pred_gen_election_2016 b
ON
a.constituency = b.constituency
and 
a.votes_2015 < b.votes_2015
WHERE b.votes_2015 is null;



DROP TABLE IF EXISTS predicted_2016_seats;
CREATE TABLE predicted_2016_seats as
SELECT
w2016.party_abbreviation,
seats_2015,
seats_2016
FROM 
(
SELECT party_abbreviation,
COUNT(*) as seats_2016
FROM
pred_winners_2016
GROUP BY 
party_abbreviation
) w2016
LEFT OUTER JOIN
(
SELECT party_abbreviation,
COUNT(*) as seats_2015
FROM
winners_2015
GROUP BY 
party_abbreviation
) w2015
ON w2016.party_abbreviation=w2015.party_abbreviation
order by seats_2016 desc;


DROP TABLE IF EXISTS brexit_candidates_predicted_to_lose;
CREATE TABLE brexit_candidates_predicted_to_lose AS
select 
a.constituency,
a.candidate as incumbent,
a.party_abbreviation as existing_party,
b.party_abbreviation as predicted_party,
b.pred_votes_2016-a.pred_votes_2016 as predicted_margin,
c.figure_to_use as estimated_leave_vote,
(1-c.figure_to_use)*IF(a.party_abbreviation in ("Con","Lab"),1,0)*IF(b.party_abbreviation in ("Con","Lab"),0,1)*IF((b.pred_votes_2016-a.pred_votes_2016)>5000,1,0.75) as ordering
from 
winners_2015 a, pred_winners_2016 b, estimated_referendum_result_by_consituency c
where a.constituency = b.constituency
and b.constituency = c.constituency
and a.party_abbreviation <> b.party_abbreviation
order by ordering desc;

