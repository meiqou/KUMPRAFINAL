-- ============================================
-- KUMPRA DATABASE SCHEMA (Updated for Riders)
-- Run this in phpMyAdmin or MySQL CLI
-- ============================================

CREATE DATABASE IF NOT EXISTS kumpra_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE kumpra_db;

-- [Previous tables unchanged: clusters, riders, users, batches (partial), orders, order_items]

-- ALTER batches for rider tracking
ALTER TABLE batches 
ADD COLUMN IF NOT EXISTS rider_latitude DECIMAL(10, 8) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS rider_longitude DECIMAL(11, 8) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS rider_updated_at DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP;

-- Update enum to include In_Progress
ALTER TABLE batches MODIFY COLUMN status ENUM(
  'Gathering','Last_Call','Locked','Purchasing','In_Progress','In_Transit','Completed','Cancelled'
) NOT NULL DEFAULT 'Gathering';

-- [Rest of seed data unchanged]

-- Seed additional open batch for rider testing
INSERT INTO batches (rider_id, status, current_count, size_limit, cluster_id, rider_latitude, rider_longitude) VALUES 
(1, 'Gathering', 3, 12, 1, NULL, NULL)
ON DUPLICATE KEY UPDATE status='Gathering';
