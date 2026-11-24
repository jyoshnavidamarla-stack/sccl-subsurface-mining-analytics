DROP DATABASE IF EXISTS sccl_mining_db;
CREATE DATABASE sccl_mining_db;
USE sccl_mining_db;

CREATE TABLE mining_blocks (
    block_id VARCHAR(15) PRIMARY KEY,
    block_name VARCHAR(100) NOT NULL,
    basin_area_sqkm DECIMAL(6,2),
    mining_type ENUM('Underground', 'Opencast', 'Exploration') NOT NULL,
    proved_reserves_mt DECIMAL(10,2) DEFAULT 0.00,
    extractable_reserves_mt DECIMAL(10,2) DEFAULT 0.00
);

CREATE TABLE boreholes (
    borehole_id VARCHAR(20) PRIMARY KEY,
    block_id VARCHAR(15) NOT NULL,
    drilling_method ENUM('Conventional Rotary', 'Hydrostatic Rotary', 'Wireline') NOT NULL,
    drilling_type ENUM('Coring', 'Non-Coring') NOT NULL,
    total_drilled_depth_m DECIMAL(6,2) NOT NULL,
    CONSTRAINT fk_bh_block FOREIGN KEY (block_id) REFERENCES mining_blocks(block_id)
);

-- 3. Borehole Geotech Logs (Now linked to 'boreholes')
CREATE TABLE borehole_geotech (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    borehole_id VARCHAR(20) NOT NULL,
    from_depth_m DECIMAL(6,2) NOT NULL,
    to_depth_m DECIMAL(6,2) NOT NULL,
    thickness_m DECIMAL(5,2) GENERATED ALWAYS AS (to_depth_m - from_depth_m) STORED,
    lithology VARCHAR(60) NOT NULL,
    recovery_m DECIMAL(5,2) NOT NULL,
    compressive_strength_mpa DECIMAL(6,2),
    youngs_modulus_gpa DECIMAL(6,2),
    rqd INT CHECK (rqd BETWEEN 0 AND 100),
    seam_correlation VARCHAR(20),
    CONSTRAINT fk_geotech_bh FOREIGN KEY (borehole_id) REFERENCES boreholes(borehole_id)
);

CREATE TABLE coal_quality_assays (
    sample_id VARCHAR(20) PRIMARY KEY,
    block_id VARCHAR(15) NOT NULL,
    seam_name VARCHAR(30) NOT NULL,
    moisture_pct DECIMAL(5,2) NOT NULL,
    ash_pct DECIMAL(5,2) NOT NULL,
    volatile_matter_pct DECIMAL(5,2),
    gcv_kcal_kg INT NOT NULL,
    specific_gravity DECIMAL(4,2),
    assigned_grade VARCHAR(5),
    CONSTRAINT fk_block FOREIGN KEY (block_id) REFERENCES mining_blocks(block_id)
);


INSERT INTO mining_blocks
(block_id, block_name, basin_area_sqkm, mining_type, proved_reserves_mt, extractable_reserves_mt)
VALUES
('KGM-PVK5', 'Padmavathi Khani (PVK-5) Incline', 6.51, 'Underground', 145.50, 98.20),
('MNG-PKOC4', 'Manuguru PKOC-IV Mine', 7.35, 'Opencast', 210.80, 165.40),
('KGM-BH01', 'Kothagudem Exploration Block 01', 12.40, 'Exploration', 180.00, 112.50),
('YLD-KING', 'Yellandu King Seam Sector', 8.20, 'Underground', 95.40, 62.10);


INSERT INTO boreholes 
(borehole_id, block_id, drilling_method, drilling_type, total_drilled_depth_m) 
VALUES
('BH-001', 'KGM-BH01', 'Conventional Rotary', 'Coring', 43.00),
('MNG-1163', 'MNG-PKOC4', 'Conventional Rotary', 'Coring', 68.50),
('PVK-BH12', 'KGM-PVK5', 'Wireline', 'Coring', 120.00),
('MNG-1164', 'MNG-PKOC4', 'Hydrostatic Rotary', 'Non-Coring', 75.00);

INSERT INTO borehole_geotech 
(borehole_id, from_depth_m, to_depth_m, lithology, recovery_m, compressive_strength_mpa, youngs_modulus_gpa, rqd, seam_correlation) 
VALUES
('BH-001', 10.00, 11.00, 'Sandstone (Overburden)', 0.96, NULL, NULL, 21, NULL),
('BH-001', 11.00, 13.00, 'Coarse Sandstone', 1.88, 6.77, 2.26, 47, NULL),
('BH-001', 13.00, 13.66, 'Weathered Sandstone', 0.00, NULL, NULL, 21, NULL),
('BH-001', 14.38, 16.00, 'Coal (TST Seam)', 1.44, 7.75, 2.45, 21, 'TST'),
('BH-001', 16.00, 17.01, 'Grey Sandstone', 0.61, 10.49, 2.94, 43, NULL),
('BH-001', 17.01, 19.00, 'Sandstone with Shale', 1.20, 9.12, 2.65, 46, NULL),
('BH-001', 19.00, 19.40, 'Fine Sandstone (Roof)', 0.38, 14.22, 3.63, 95, NULL),
('BH-001', 19.50, 21.35, 'Sandstone Roof', 1.78, 14.61, 3.73, 44, NULL),
('BH-001', 28.20, 30.40, 'Coal (TSB Seam)', 0.75, NULL, NULL, NULL, 'TSB'),
('BH-001', 31.00, 33.04, 'Floor Sandstone', 1.70, 16.48, 4.12, 44, NULL),
('BH-001', 36.00, 37.27, 'Compact Sandstone', 1.18, 15.49, 3.92, 39, NULL),
('BH-001', 37.27, 37.54, 'Sandstone Band', 0.25, 12.55, 3.33, 93, NULL),
('BH-001', 40.84, 42.00, 'Deep Sandstone', 1.01, 18.83, 4.51, 68, NULL),
('BH-001', 42.00, 43.00, 'Deep Sandstone', 0.99, 12.45, 3.33, 75, NULL),
('MNG-1163', 45.00, 59.00, 'Coal (1 Seam)', 12.60, 8.63, 2.55, 62, '1 Seam'),
('MNG-1163', 60.00, 68.50, 'Coal (Thick Seam)', 7.80, 10.98, 3.10, 78, 'Thick Seam');

INSERT INTO coal_quality_assays
(sample_id, block_id, seam_name, moisture_pct, ash_pct, volatile_matter_pct, gcv_kcal_kg, specific_gravity, assigned_grade) 
VALUES
('SMP-001', 'KGM-PVK5', 'King Seam (Bottom)', 5.80, 18.40, 29.50, 5650, 1.50, 'G6'),
('SMP-002', 'KGM-PVK5', 'King Seam (Top)', 6.20, 21.10, 28.10, 5320, 1.53, 'G7'),
('SMP-003', 'KGM-PVK5', 'Queen Seam', 7.40, 29.80, 25.40, 4450, 1.61, 'G10'),
('SMP-004', 'MNG-PKOC4', 'Thick Seam (Middle)', 6.50, 24.20, 27.00, 4980, 1.56, 'G8'),
('SMP-005', 'MNG-PKOC4', '1 Seam (14m)', 8.90, 38.50, 21.80, 2950, 1.81, 'G15'),
('SMP-006', 'MNG-PKOC4', 'H1-H4 Top Layer', 9.50, 42.10, 19.60, 2650, 1.84, 'G16'),
('SMP-007', 'YLD-KING', 'King Seam (Main)', 5.40, 16.90, 30.20, 5920, 1.47, 'G5'),
('SMP-008', 'KGM-BH01', 'TSB Seam', 8.10, 34.60, 23.50, 3550, 1.73, 'G13'),
('SMP-009', 'KGM-BH01', 'TST Seam', 10.20, 48.50, 17.80, 2320, 1.87, 'G17');

USE sccl_mining_db;

SELECT 'mining_blocks' AS table_name, COUNT(*) AS row_count FROM mining_blocks
UNION ALL
SELECT 'boreholes', COUNT(*) FROM boreholes
UNION ALL
SELECT 'borehole_geotech', COUNT(*) FROM borehole_geotech
UNION ALL
SELECT 'coal_quality_assays', COUNT(*) FROM coal_quality_assays;