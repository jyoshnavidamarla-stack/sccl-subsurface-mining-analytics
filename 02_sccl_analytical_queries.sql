USE sccl_mining_db;

-- QUERY 1: Drilling Core Recovery Quality Control (QC) Audit
SELECT 
    mb.block_name,
    bh.borehole_id,
    bh.drilling_method,
    bg.from_depth_m,
    bg.to_depth_m,
    bg.lithology,
    bg.thickness_m,
    bg.recovery_m,
    ROUND((bg.recovery_m / bg.thickness_m) * 100, 2) AS core_recovery_pct,
    CASE 
        WHEN bg.lithology LIKE '%Coal%' AND (bg.recovery_m / bg.thickness_m) * 100 >= 85 
            THEN 'PASS (Coal >=85%)'
        WHEN bg.lithology NOT LIKE '%Coal%' AND (bg.recovery_m / bg.thickness_m) * 100 >= 70 
            THEN 'PASS (Non-Coal >=70%)'
        ELSE 'FAIL - Core Loss Alert'
    END AS sccl_drilling_qc_status
FROM borehole_geotech bg
JOIN boreholes bh ON bg.borehole_id = bh.borehole_id
JOIN mining_blocks mb ON bh.block_id = mb.block_id
ORDER BY core_recovery_pct ASC;

-- QUERY 2: Geotechnical Roof & Strata Stability Profiling (Deere's RQD Scale)
SELECT 
    mb.block_name,
    mb.mining_type,
    bg.borehole_id,
    bg.from_depth_m,
    bg.to_depth_m,
    bg.lithology,
    bg.compressive_strength_mpa,
    bg.youngs_modulus_gpa,
    bg.rqd,
    CASE 
        WHEN bg.rqd IS NULL THEN 'Not Logged'
        WHEN bg.rqd < 25 THEN 'Very Poor (0-25%)'
        WHEN bg.rqd BETWEEN 25 AND 50 THEN 'Poor (25-50%)'
        WHEN bg.rqd BETWEEN 51 AND 75 THEN 'Fair (50-75%)'
        WHEN bg.rqd BETWEEN 76 AND 90 THEN 'Good (75-90%)'
        ELSE 'Very Good (90-100%)'
    END AS deere_rqd_class,
    CASE 
        WHEN bg.rqd < 50 AND mb.mining_type = 'Underground' 
            THEN 'High Priority: Heavy Roof Bolting / Support Needed'
        WHEN bg.rqd < 50 AND mb.mining_type IN ('Opencast', 'Exploration') 
            THEN 'Monitor Bench Slope Stability'
        ELSE 'Standard Support'
    END AS engineering_action
FROM borehole_geotech bg
JOIN boreholes bh ON bg.borehole_id = bh.borehole_id
JOIN mining_blocks mb ON bh.block_id = mb.block_id
ORDER BY bg.borehole_id, bg.from_depth_m;

-- QUERY 3: Automated Coal Quality Classification & GCV Grade Verification
SELECT 
    cqa.sample_id,
    mb.block_name,
    mb.mining_type,
    cqa.seam_name,
    cqa.moisture_pct,
    cqa.ash_pct,
    ROUND(cqa.moisture_pct + cqa.ash_pct, 2) AS ash_plus_moisture_pct,
    ROUND(100 - (cqa.moisture_pct + cqa.ash_pct + cqa.volatile_matter_pct), 2) AS calculated_fixed_carbon_pct,
    CASE 
        WHEN (cqa.moisture_pct + cqa.ash_pct) < 40 THEN 'Coal (<40%)'
        WHEN (cqa.moisture_pct + cqa.ash_pct) BETWEEN 40 AND 55 THEN 'Shaly Coal (40-55%)'
        WHEN (cqa.moisture_pct + cqa.ash_pct) BETWEEN 55 AND 65 THEN 'Carbonaceous Shale Low (55-65%)'
        WHEN (cqa.moisture_pct + cqa.ash_pct) BETWEEN 65 AND 75 THEN 'Carbonaceous Shale High (65-75%)'
        ELSE 'Shale (>75%)'
    END AS sample_litho_class,
    cqa.gcv_kcal_kg,
    cqa.assigned_grade,
    CASE 
        WHEN cqa.gcv_kcal_kg > 7000 THEN 'G1'
        WHEN cqa.gcv_kcal_kg BETWEEN 6701 AND 7000 THEN 'G2'
        WHEN cqa.gcv_kcal_kg BETWEEN 6401 AND 6700 THEN 'G3'
        WHEN cqa.gcv_kcal_kg BETWEEN 6101 AND 6400 THEN 'G4'
        WHEN cqa.gcv_kcal_kg BETWEEN 5801 AND 6100 THEN 'G5'
        WHEN cqa.gcv_kcal_kg BETWEEN 5501 AND 5800 THEN 'G6'
        WHEN cqa.gcv_kcal_kg BETWEEN 5201 AND 5500 THEN 'G7'
        WHEN cqa.gcv_kcal_kg BETWEEN 4901 AND 5200 THEN 'G8'
        WHEN cqa.gcv_kcal_kg BETWEEN 4601 AND 4900 THEN 'G9'
        WHEN cqa.gcv_kcal_kg BETWEEN 4301 AND 4600 THEN 'G10'
        WHEN cqa.gcv_kcal_kg BETWEEN 4001 AND 4300 THEN 'G11'
        WHEN cqa.gcv_kcal_kg BETWEEN 3701 AND 4000 THEN 'G12'
        WHEN cqa.gcv_kcal_kg BETWEEN 3401 AND 3700 THEN 'G13'
        WHEN cqa.gcv_kcal_kg BETWEEN 3101 AND 3400 THEN 'G14'
        WHEN cqa.gcv_kcal_kg BETWEEN 2801 AND 3100 THEN 'G15'
        WHEN cqa.gcv_kcal_kg BETWEEN 2501 AND 2800 THEN 'G16'
        ELSE 'G17'
    END AS verified_gcv_grade,
    RANK() OVER (ORDER BY cqa.gcv_kcal_kg DESC) AS company_wide_quality_rank
FROM coal_quality_assays cqa
JOIN mining_blocks mb ON cqa.block_id = mb.block_id;

-- QUERY 4: Block-Level Reserve Recoverability & Quality KPI Summary (CTE + Joins)
WITH block_quality_agg AS (
    SELECT 
        block_id,
        COUNT(sample_id) AS total_samples,
        ROUND(AVG(gcv_kcal_kg), 0) AS avg_gcv_kcal_kg,
        ROUND(AVG(ash_pct), 2) AS avg_ash_pct
    FROM coal_quality_assays
    GROUP BY block_id
),
block_geotech_agg AS (
    SELECT 
        bh.block_id,
        COUNT(DISTINCT bh.borehole_id) AS boreholes_drilled,
        ROUND(AVG(bg.rqd), 1) AS avg_rqd_pct,
        ROUND(AVG(bg.compressive_strength_mpa), 2) AS avg_ucs_mpa
    FROM boreholes bh
    LEFT JOIN borehole_geotech bg ON bh.borehole_id = bg.borehole_id
    GROUP BY bh.block_id
)
SELECT 
    mb.block_id,
    mb.block_name,
    mb.mining_type,
    mb.proved_reserves_mt,
    mb.extractable_reserves_mt,
    ROUND((mb.extractable_reserves_mt / mb.proved_reserves_mt) * 100, 2) AS reserve_recovery_efficiency_pct,
    COALESCE(bga.boreholes_drilled, 0) AS boreholes_drilled,
    bga.avg_rqd_pct,
    bga.avg_ucs_mpa,
    bqa.avg_gcv_kcal_kg,
    bqa.avg_ash_pct
FROM mining_blocks mb
LEFT JOIN block_geotech_agg bga ON mb.block_id = bga.block_id
LEFT JOIN block_quality_agg bqa ON mb.block_id = bqa.block_id
ORDER BY mb.extractable_reserves_mt DESC;

