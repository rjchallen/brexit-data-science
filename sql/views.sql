USE brexit_data_science;

DROP TABLE IF EXISTS yougov_poll;

CREATE TABLE yougov_poll AS
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
v6.label as social_grade
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

CREATE TABLE area_demographics AS
SELECT g.area_code, g.area, IF(g.sex=1,'Male','Female') as gender, g.age_cat, SUM(g.population) as population, SUM(g.population)/t.total*100 as percent_area_population
FROM 
	( 
		SELECT p.`lad2014_code` as area_code,
			p.`lad2014_name` as area,
			p.`country`,
			p.`sex`,
			p.`age`,
			IF(p.age < 25, '18-25', IF(p.age<40, '26-40', IF(p.age<65, '41-65', '66+'))) as age_cat, 
			IF(p.`population_2015`=0,p.`population_2014`,p.`population_2015`) as population
		FROM `brexit_data_science`.`raw_population_series` p
		WHERE p.age>16 
	) g,
	(
		SELECT q.`lad2014_code` as area_code, SUM(q.population_2015) as total
		FROM `brexit_data_science`.`raw_population_series` q
		GROUP BY q.`lad2014_code`
	) t
WHERE g.area_code = t.area_code
GROUP BY
	g.area_code, g.sex, g.age_cat
;

DROP TABLE IF EXISTS area_region_map;

CREATE TABLE area_region_map AS
SELECT DISTINCT
	m.local_authority_code as area_code,
	m.local_authority_name as area,
	r.*
FROM 
	raw_region_mapping r,
	raw_oac_region_area_mapping m
where r.region_code=m.region_country_code
;

DROP TABLE IF EXISTS regional_demographics;

CREATE TABLE regional_demographics AS
SELECT 
	d.gender, d.age_cat, SUM(d.population) as population, m.yougov_region, m.yougov_region_name, SUM(d.population)/t.total*100 as percent_population_region
FROM 
	area_demographics d, 
	area_region_map m,
	( 
		SELECT x.yougov_region, SUM(y.population) as total FROM 
		area_demographics y, 
		area_region_map x
		WHERE
		x.area_code=y.area_code
		GROUP BY
		x.yougov_region
	) t
WHERE
m.area_code=d.area_code
AND
t.yougov_region = m.yougov_region
GROUP BY
m.yougov_region, d.age_cat, d.gender
;
