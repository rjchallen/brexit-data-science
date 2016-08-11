USE brexit_data_science;

DROP FUNCTION IF EXISTS percent;

CREATE FUNCTION percent(sample INTEGER, size INTEGER)
RETURNS FLOAT DETERMINISTIC
RETURN sample/size*100;

DROP FUNCTION IF EXISTS confidence;

CREATE FUNCTION confidence(sample INTEGER, size INTEGER)
RETURNS FLOAT DETERMINISTIC
RETURN 1.96*(POW((sample/size)*(1-sample/size)/size,0.5)+0.5/size)*100;

DROP TABLE IF EXISTS gender_weighting;

CREATE TABLE gender_weighting AS
SELECT 
	d.gender,
	SUM(d.population) as population_size,
	SUM(d.percent_population_uk) as percent_population_uk,
	s.sample_size,
	s.percent_sample, 
	s.confidence,
	SUM(d.percent_population_uk)/s.percent_sample as weight,
	if(ABS(SUM(d.percent_population_uk)-s.percent_sample)>s.confidence,1,0) as risk_of_bias_at_95_ci 
	FROM 
	brexit_data_science.regional_demographics d,
	(
		SELECT 
			p.gender,
			COUNT(*) as sample_size,
			percent(COUNT(*),sample.total) as percent_sample,
			confidence(COUNT(*),sample.total) as confidence
		FROM yougov_poll p,
			(	
				SELECT COUNT(*) as total from yougov_poll
			) sample
		GROUP BY p.gender
	) s
WHERE
	d.gender = s.gender
GROUP BY
	d.gender
;

DROP TABLE IF EXISTS age_cat_weighting;

CREATE TABLE age_cat_weighting AS
SELECT 
	d.age_cat,
	SUM(d.population) as population_size,
	SUM(d.percent_population_uk) as percent_population_uk,
	s.sample_size,
	s.percent_sample, 
	s.confidence, 
	SUM(d.percent_population_uk)/s.percent_sample as weight,
	if(ABS(SUM(d.percent_population_uk)-s.percent_sample)>s.confidence,1,0) as risk_of_bias_at_95_ci
	FROM 
	brexit_data_science.regional_demographics d,
	(
		SELECT 
			p.age_cat,
			COUNT(*) as sample_size,
			percent(COUNT(*),sample.total) as percent_sample,
			confidence(COUNT(*),sample.total) as confidence
		FROM yougov_poll p,
			(	
				SELECT COUNT(*) as total from yougov_poll
			) sample
		GROUP BY p.age_cat
	) s
WHERE
	d.age_cat = s.age_cat
GROUP BY
	d.age_cat
;

DROP TABLE IF EXISTS region_weighting;

CREATE TABLE region_weighting AS
SELECT 
	d.yougov_region,
	SUM(d.population) as population_size,
	SUM(d.percent_population_uk) as percent_population_uk,
	s.sample_size,
	s.percent_sample, 
	s.confidence,
	SUM(d.percent_population_uk)/s.percent_sample as weight,
	if(ABS(SUM(d.percent_population_uk)-s.percent_sample)>s.confidence,1,0) as risk_of_bias_at_95_ci 
	FROM 
	brexit_data_science.regional_demographics d,
	(
		SELECT 
			p.govregion,
			COUNT(*) as sample_size,
			percent(COUNT(*),sample.total) as percent_sample,
			confidence(COUNT(*),sample.total) as confidence
		FROM yougov_poll p,
			(	
				SELECT COUNT(*) as total from yougov_poll
			) sample
		GROUP BY p.govregion
	) s
WHERE
	d.yougov_region = s.govregion
GROUP BY
	d.yougov_region
;

DROP TABLE IF EXISTS demographic_weighting;

CREATE TABLE demographic_weighting AS
SELECT 
	d.yougov_region,
	d.yougov_region_name,
	d.gender,
	d.age_cat,
	d.population,
	d.percent_population_uk,
	s.sample_size,
	s.percent_sample, 
	s.confidence, 
	d.percent_population_uk/s.percent_sample as weight,
	if(ABS(d.percent_population_uk-s.percent_sample)>s.confidence,1,0) as risk_of_bias_at_95_ci
	FROM 
	brexit_data_science.regional_demographics d,
	(
		SELECT 
			p.gender, p.age_cat, p.govregion,
			COUNT(*) as sample_size,
			percent(COUNT(*),sample.total) as percent_sample,
			confidence(COUNT(*),sample.total) as confidence
		FROM yougov_poll p,
			(	
				SELECT COUNT(*) as total from yougov_poll
			) sample
		GROUP BY p.gender, p.age_cat, p.govregion
	) s
WHERE
	d.gender = s.gender AND
	d.age_cat = s. age_cat AND
	d.yougov_region = s.govregion
;

DROP TABLE IF EXISTS combined_weighting;

CREATE TABLE combined_weighting AS 
SELECT 
	tmp.yougov_region,
	tmp.yougov_region_name,
	tmp.gender,
	tmp.age_cat,
	tmp.sample_size,
	IF(ABS((tmp.percent_population_uk-tmp.ind_var_population_percent)/tmp.percent_population_uk)<0.1, tmp.ind_var_weight, tmp.weight) as weight
FROM
(
	SELECT 
		d.*,
		r.percent_population_uk/100 * a.percent_population_uk/100 * g.percent_population_uk/100 * 100 as ind_var_population_percent,
		# r.confidence + a.confidence + g.confidence as ind_var_confidence, - not sure how this could be done
		r.weight * a.weight * g.weight as ind_var_weight
	FROM 
		demographic_weighting d,
		region_weighting r,
		age_cat_weighting a,
		gender_weighting g
	WHERE
		d.yougov_region = r.yougov_region AND
		d.age_cat = a.age_cat AND
		d.gender = g.gender
) tmp
;

DROP TABLE IF EXISTS political_weighting;

CREATE TABLE political_weighting AS
SELECT 
	obs.vote2015r,
	obs.vote2015r_label,
	pred.percent_of_uk_vote*0.661 as percent_of_electorate,
	obs.percent_of_sample_vote as percent_of_sample,
	obs.confidence_sample_vote,
	if(ABS(pred.percent_of_uk_vote*0.661-obs.percent_of_sample_vote)>obs.confidence_sample_vote,1,0) as risk_of_bias_at_95_ci,
	pred.percent_of_uk_vote*0.661/obs.percent_of_sample_vote as incremental_weighting
From
(SELECT
			el.vote2015r,
			SUM(el.votes) as votes,
			SUM(el.votes)/votes.total*100 as percent_of_uk_vote
		FROM
			( SELECT 
				IF (el.party_abbreviation='Con',1,
					IF (el.party_abbreviation='Lab',2,
						IF (el.party_abbreviation='LD',3,
							IF (el.party_abbreviation='UKIP',4,
								IF (el.party_abbreviation='Green',5,
									6))))) as vote2015r,
				el.votes,
				el.constituency_id
				FROM raw_election_result el 
				WHERE el.party_abbreviation <> ""
			) el,
			( SELECT SUM(votes) as total FROM raw_election_result WHERE party_abbreviation <> "" ) votes
		GROUP BY el.vote2015r
) pred,
(
SELECT 
	y.vote2015r,
	y.vote2015r_label,
	COUNT(*) as sample_votes,
	SUM(w.weight) as weighted_votes,
	percent(SUM(w.weight),total.votes) as percent_of_sample_vote,
	confidence(SUM(w.weight),total.votes) as confidence_sample_vote
FROM
	yougov_poll y,
	combined_weighting w,
	( 
		SELECT SUM(w.weight) as votes FROM yougov_poll p, combined_weighting w
			WHERE 
				p.age_cat = w.age_cat AND
				p.gender = w.gender AND
				p.govregion = w.yougov_region
	) total
WHERE 
	y.age_cat = w.age_cat AND
	y.gender = w.gender AND
	y.govregion = w.yougov_region
GROUP BY
	y.vote2015r
) obs
WHERE 
	obs.vote2015r = pred.vote2015r
UNION # bit of a hack here to account for mising turnout data - UK wide 2015 turnout was 66.1% this is reflected in the percentages above which are modified by voter turnout.
SELECT
	7 as vote2015r,
	'Did not vote' as vote2015r_label,
	100-66.1 as percent_of_uk_vote,
	percent(SUM(IF(p.vote2015r=7,1,0)),COUNT(*)) as percent_of_sample_vote,
	confidence(SUM(IF(p.vote2015r=7,1,0)),COUNT(*)) as confidence_sample_vote,
	if(ABS(100-66.1-percent(SUM(IF(p.vote2015r=7,1,0)),COUNT(*)))>confidence(SUM(IF(p.vote2015r=7,1,0)),COUNT(*)),1,0) as risk_of_bias_at_95_ci,
	(100-66.1)/percent(SUM(IF(p.vote2015r=7,1,0)),COUNT(*)) as incremental_weighting
FROM yougov_poll p;

DROP TABLE IF EXISTS weighted_yougov_poll;

CREATE TABLE weighted_yougov_poll AS 
SELECT y.*, c.weight as demographic_weight, c.weight*i.incremental_weighting as combined_weight
FROM
	yougov_poll y LEFT JOIN
	combined_weighting c ON (
		y.age_cat = c.age_cat AND
		y.govregion = c.yougov_region AND
		y.gender = c.gender)
	LEFT JOIN political_weighting i ON (
y.vote2015r = i.vote2015r
)
;




/*
Regional variation of above. Produces quite extreme weights 
SELECT 
	pred.yougov_region,
	obs.govregion_label as yougov_region_label,
	obs.vote2015r,
	obs.vote2015r_label,
	pred.percent_of_uk_vote/obs.percent_of_sample_vote as incremental_weighting
From
(SELECT
			ar.yougov_region,
			el.vote2015r,
			SUM(el.votes) as votes,
			SUM(el.votes)/votes.total*100 as percent_of_uk_vote
		FROM
			( SELECT 
				IF (el.party_abbreviation='Con',1,
					IF (el.party_abbreviation='Lab',2,
						IF (el.party_abbreviation='LD',3,
							IF (el.party_abbreviation='UKIP',4,
								IF (el.party_abbreviation='Green',5,
									6))))) as vote2015r,
				el.votes,
				el.constituency_id
				FROM raw_election_result el 
				WHERE el.party_abbreviation <> ""
			) el,
			area_region_map ar,
			( SELECT SUM(votes) as total FROM raw_election_result WHERE party_abbreviation <> "" ) votes
		WHERE
			el.constituency_id = ar.code
		GROUP BY ar.yougov_region, el.vote2015r
) pred,
(
SELECT 
	y.govregion,
	y.govregion_label,
	y.vote2015r,
	y.vote2015r_label,
	COUNT(*) as sample_votes,
	SUM(w.weight) as weighted_votes,
	SUM(w.weight)/total.votes*100 as percent_of_sample_vote
FROM
	yougov_poll y,
	combined_weighting w,
	( 
		SELECT SUM(IF(p.vote2015r in (1,2,3,4,5,6),w.weight,0)) as votes FROM yougov_poll p, combined_weighting w
			WHERE 
				p.age_cat = w.age_cat AND
				p.gender = w.gender AND
				p.govregion = w.yougov_region
	) total
WHERE 
	y.age_cat = w.age_cat AND
	y.gender = w.gender AND
	y.govregion = w.yougov_region
GROUP BY
	y.govregion,
	y.vote2015r
) obs
WHERE 
	obs.govregion = pred.yougov_region AND
	obs.vote2015r = pred.vote2015r
*/

