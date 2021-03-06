# geocoding service:
Geocoder::Configuration.lookup = :google

# to use an API key:
Geocoder::Configuration.api_key = ENV['GOOGLE_MAPS_API_KEY'] ? ENV['GOOGLE_MAPS_API_KEY'] : ''

# geocoding service request timeout, in seconds (default 3):
Geocoder::Configuration.timeout = 20

# use HTTPS for geocoding service connections:
Geocoder::Configuration.use_https = false

# language to use (for search queries and reverse geocoding):
Geocoder::Configuration.language = :en

# caching (see below for details)
#Geocoder::Configuration.cache = Redis.new
#Geocoder::Configuration.cache_prefix = "..."
