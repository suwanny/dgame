# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Enable threaded mode
# config.threadsafe!

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Use a different cache store in production
config.cache_store = :mem_cache_store, '10.254.171.192:11211'

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# 10.254.171.192:11211, 174.129.230.52:11211
# 
# memcached 
memcache_options = {
    :c_threshold => 10_000,
    :compression => true,
    :debug => false,
    :namespace => 'dgame',
    :readonly => false,
    :urlencode => false
}

CACHE = MemCache.new memcache_options
CACHE.servers = '10.254.171.192:11211'
