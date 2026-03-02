import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://jnkzbfqrwkgfiyxvwrug.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impua3piZnFyd2tnZml5eHZ3cnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0NDQ0NDgsImV4cCI6MjA4NDAyMDQ0OH0.20qAetWuXPOeA_fcflj_wdx_-mwKlHIszVvgEwa8sZo'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
