const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error(
    '\n[FATAL] Missing required environment variables: SUPABASE_URL and/or SUPABASE_SERVICE_KEY.\n' +
    'Copy .env.example to .env and fill in your Supabase credentials.\n' +
    'Get them from: https://supabase.com/dashboard/project/YOUR_PROJECT/settings/api\n'
  );
  process.exit(1);
}

if (supabaseServiceKey.length < 100) {
  console.error(
    '\n[FATAL] SUPABASE_SERVICE_KEY appears to be a placeholder.\n' +
    'Please set the actual service_role key from your Supabase dashboard.\n'
  );
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

module.exports = supabase;
