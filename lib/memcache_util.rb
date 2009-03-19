##
# A utility wrapper around the MemCache client to simplify cache access.  All
# methods silently ignore MemCache errors.

module Cache

  ##
  # Returns the object at +key+ from the cache if successful, or nil if either
  # the object is not in the cache or if there was an error attermpting to
  # access the cache.
  #
  # If there is a cache miss and a block is given the result of the block will
  # be stored in the cache with optional +expiry+.

  def self.get(key, expiry = 0)
    start_time = Time.now
    result = CACHE.get key
    elapsed = Time.now - start_time
#    ActiveRecord::Base.logger.debug('MemCache Get (%0.6f)  %s' % [elapsed, key])
    if result.nil? and block_given? then
      value = yield
      put key, value, expiry
    end
    return result
  rescue MemCache::MemCacheError => err
    ActiveRecord::Base.logger.debug "MemCache Error: #{err.message}"
  end

  ##
  # Places +value+ in the cache at +key+, with an optional +expiry+ time in
  # seconds.

  def self.put(key, value, expiry = 0)
    start_time = Time.now
    CACHE.set key, value, expiry
    elapsed = Time.now - start_time
#    ActiveRecord::Base.logger.debug('MemCache Set (%0.6f)  %s' % [elapsed, key])
  rescue MemCache::MemCacheError => err
    ActiveRecord::Base.logger.debug "MemCache Error: #{err.message}"
  end

  ##
  # Deletes +key+ from the cache in +delay+ seconds.

  def self.delete(key, delay = nil)
    start_time = Time.now
    CACHE.delete key, delay
    elapsed = Time.now - start_time
#    ActiveRecord::Base.logger.debug('MemCache Delete (%0.6f)  %s' %  [elapsed, key])
  rescue MemCache::MemCacheError => err
    ActiveRecord::Base.logger.debug "MemCache Error: #{err.message}"
  end

  ##
  # Resets all connections to MemCache servers.

  def self.reset
    CACHE.reset
    ActiveRecord::Base.logger.debug 'MemCache Connections Reset'
  end

  def self.flush_all
    CACHE.flush_all             
    ActiveRecord::Base.logger.debug 'MemCache Flush All'
  end
end
