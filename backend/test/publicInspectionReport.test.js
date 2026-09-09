const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function controller({ reviewError = null, findingsError = false } = {}) {
  const filters = [];
  const db = { from(table) {
    let fields;
    const chain = {
      select(value) { fields = value; return chain; },
      eq(key, value) { filters.push([table, key, value]); return chain; },
      neq() { return chain; }, gte() { return chain; }, order() { return chain; },
      single() { return Promise.resolve({ data: { id: 'b', name: 'Example', category: 'Cafe' } }); },
      then(resolve, reject) {
        const result = table === 'reviews'
          ? { data: fields === 'total_score' ? [{ total_score: 4 }] : [], error: reviewError }
          : { data: [] };
        return Promise.resolve(result).then(resolve, reject);
      },
    };
    return chain;
  }};
  const exports = {};
  vm.runInNewContext(fs.readFileSync(require.resolve('../src/controllers/businessController'), 'utf8'), {
    exports, console, Date,
    require(path) {
      if (path.endsWith('/supabase')) return db;
      if (path.endsWith('/constants')) return { PLAN_DETAILS: {} };
      if (path.endsWith('/errorMessages')) return { createErrorResponse: (code) => ({ code }) };
      if (path.endsWith('/findingService')) return {
        listFindings: async () => {
          if (findingsError) throw Error('unavailable');
          return [{ id: 'f', title: 'Wait time', status: 'open' }];
        },
        improvementRate: () => null, buildTimeline: () => [],
      };
      return {};
    },
  });
  return { handler: exports.getTrustAnalysis, filters };
}

async function invoke(options) {
  const { handler, filters } = controller(options);
  let response; let error;
  await handler({ params: { id: 'b' } }, {
    json(value) { response = value; }, status() { return this; },
  }, (value) => { error = value; });
  return { response, error, filters };
}

test('public report returns findings without authenticated owner and uses published reviews', async () => {
  const { response, error, filters } = await invoke();
  assert.equal(error, undefined);
  assert.equal(response.data.findingsAvailable, true);
  assert.equal(response.data.findings[0].status, 'open');
  assert.equal(response.data.averageScore, 4);
  assert.equal(response.data.totalReviews, 1);
  assert.equal(filters.some(([, key]) => key === 'owner_id'), false);
  assert.equal(filters.filter(([table, key, value]) => table === 'reviews' && key === 'status' && value === 'published').length, 2);
});

test('failed review query propagates an error instead of a zero-score success', async () => {
  const problem = Error('database unavailable');
  const { response, error } = await invoke({ reviewError: problem });
  assert.equal(response, undefined);
  assert.equal(error, problem);
});

test('missing findings storage is explicitly unavailable, not confirmed empty', async () => {
  const { response } = await invoke({ findingsError: true });
  assert.equal(response.data.findingsAvailable, false);
  assert.equal(response.data.improvement, null);
  assert.equal(response.data.totalReviews, 1);
});
