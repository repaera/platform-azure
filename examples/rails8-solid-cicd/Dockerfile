# syntax = docker/dockerfile:1

# Multi-stage build optimized for Rails 8 with Solid Trifecta.
# Uses single-container deployment with Puma plugin for Solid Queue.
# (Beginner-friendly: web server + background jobs in one process)

# --- Build stage ---
FROM ruby:3.3-slim AS builder

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    libyaml-dev \
    pkg-config \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /rails

# Copy gems first for better layer caching
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Precompile assets (Propshaft + Tailwind/Importmap)
# SECRET_KEY_BASE=dummy needed for asset compilation
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rails assets:precompile

# Clean up build artifacts
RUN rm -rf node_modules tmp/cache vendor/bundle/ruby/*/cache

# --- Production stage ---
FROM ruby:3.3-slim AS production

# Install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    libpq5 \
    libyaml-0-2 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /rails

# Create non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd --system --uid 1000 --gid rails rails

# Copy built application from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /rails /rails

# Create required directories
RUN mkdir -p tmp/pids log storage && \
    chown -R rails:rails /rails

USER rails

# Health check endpoint (used by Traefik and k8s probes)
# Rails 8 provides /up by default
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/up || exit 1

EXPOSE 3000

# Default: start Puma web server
# 
# OPTION 1: Single container (beginner-friendly)
#   Set SOLID_QUEUE_IN_PUMA=true in your environment
#   Add to config/puma.rb: plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
#   Web server + background jobs run in one process
#
# OPTION 2: Separate workers (production scale)
#   Leave SOLID_QUEUE_IN_PUMA unset or false
#   Deploy a separate worker Deployment with command: bin/rails solid_queue:start
#   Scale web and workers independently
#
# ENV SOLID_QUEUE_IN_PUMA=true
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
