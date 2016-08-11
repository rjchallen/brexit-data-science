
# Should be empty
SELECT 
		ar.*, rr.*
		FROM
			raw_referendum_result rr LEFT JOIN
			area_region_map ar
		ON rr.area_code = ar.code
WHERE ar.code IS null
;

# Should be empty
SELECT 
		ar.*, rr.*
		FROM
			raw_population_series rr LEFT JOIN
			area_region_map ar
		ON rr.lad2014_code = ar.code

WHERE ar.code IS null
;

# Should be one row - summary of total votes
SELECT 
		ar.*, rr.*
		FROM
			raw_election_result rr LEFT JOIN
			area_region_map ar
		ON rr.constituency_id = ar.code
WHERE ar.code IS null
;