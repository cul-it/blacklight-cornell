# Opt out of MultiJSON in the `json-schema` gem (pulled in transitively by the `mcp` gem).
# Without this, every request that validates a tool input results is:
# "[DEPRECATION NOTICE] json-schema support for MultiJSON is deprecated …"
require "json-schema"
JSON::Validator.use_multi_json = false
