/**
 * PostgreSQL advisory lock for distributed job safety
 * Uses pg_try_advisory_lock which is non-blocking
 * No Redis needed - leverages existing Supabase/PostgreSQL connection
 */

const supabase = require('../config/supabase');

/**
 * Try to acquire a PostgreSQL advisory lock (non-blocking)
 * @param {number} lockId - Unique lock identifier
 * @returns {Promise<boolean>} true if lock acquired
 */
async function acquireLock(lockId) {
  try {
    const { data, error } = await supabase.rpc('pg_try_advisory_lock', { lock_id: lockId });
    if (error) {
      console.warn(`[Lock] Failed to acquire lock ${lockId}:`, error.message);
      return false;
    }
    return data === true;
  } catch (err) {
    console.warn(`[Lock] Error acquiring lock ${lockId}:`, err.message);
    return false;
  }
}

/**
 * Release a PostgreSQL advisory lock
 * @param {number} lockId - Unique lock identifier
 */
async function releaseLock(lockId) {
  try {
    await supabase.rpc('pg_advisory_unlock', { lock_id: lockId });
  } catch (err) {
    console.warn(`[Lock] Error releasing lock ${lockId}:`, err.message);
  }
}

// Lock IDs for different scheduler jobs
const LOCK_IDS = {
  AUTO_PUBLISH: 100001,
  SETTLEMENT: 100002,
  MISSION_EXPIRY: 100003,
  COLLUSION_SCAN: 100004,
  RANKING_REBUILD: 100005,
  NOTIFICATION_CLEANUP: 100006,
  DETECTION_TEST_EXPIRY: 100007,
  SUBSCRIPTION_RENEWAL: 100008,
};

/**
 * Wraps a scheduler job with a distributed lock
 * Ensures only one instance of the job runs across multiple server instances
 * @param {number} lockId - Lock ID from LOCK_IDS
 * @param {Function} jobFn - The async job function to wrap
 * @returns {Function} Wrapped function that acquires lock before running
 */
function withLock(lockId, jobFn) {
  return async function lockedJob() {
    const acquired = await acquireLock(lockId);
    if (!acquired) {
      console.log(`[Scheduler] Job ${lockId} skipped - another instance is running`);
      return;
    }
    try {
      return await jobFn();
    } finally {
      await releaseLock(lockId);
    }
  };
}

module.exports = { acquireLock, releaseLock, withLock, LOCK_IDS };
