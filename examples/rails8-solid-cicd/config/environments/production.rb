# Rails 8 production environment configuration for k3s deployment.
# Copy relevant settings into your Rails app's config/environments/production.rb.
# 
# SOLID QUEUE: Two deployment options
#
# OPTION 1: Puma Plugin (Single Container) — Beginner-friendly
#   Add to config/puma.rb: plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
#   Set SOLID_QUEUE_IN_PUMA=true in environment variables
#   Web server + background jobs run in one process
#   Good for: Getting started, low job volume, simplicity
#
# OPTION 2: Separate Worker Deployment (Production Scale)
#   Do NOT set SOLID_QUEUE_IN_PUMA (or set to false)
#   Deploy a separate worker container with: bin/rails solid_queue:start
#   Scale web and worker pods independently
#   Good for: High job volume, independent scaling, resource isolation

Rails.application.configure do
  # --- Standard Rails 8 Production Settings ---
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.force_ssl = true
  config.assume_ssl = true

  # --- Solid Trifecta ---

  # 1. Solid Cache (replaces Redis for caching)
  config.cache_store = :solid_cache_store
  # Stores data in the 'solid_cache_entries' table in PostgreSQL
  # Run in your app: bin/rails solid_cache:install

  # 2. Solid Queue (replaces Redis/Sidekiq for background jobs)
  # Configuration is the same for both deployment options
  # Stores jobs in 'solid_queue_*' tables in PostgreSQL
  # Run in your app: bin/rails solid_queue:install
  # 
  # For Option 1 (Puma plugin), add to config/puma.rb:
  #   plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
  #
  # For Option 2 (separate workers), the worker container runs:
  #   bin/rails solid_queue:start

  # 3. Search (pg_search gem)
  # Add gem 'pg_search' to Gemfile, run migrations, use pg_search_scope in models
  # For vector search, ensure pgvector extension is enabled on PostgreSQL

  # --- Asset Serving ---
  config.assets.compile = false
  config.active_storage.variant_processor = :vips

  # --- Logging ---
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]

  # --- Health Check ---
  # Rails 8 provides /up endpoint by default for load balancer health checks
  # Traefik and k8s probes should hit: http://app:3000/up
end
