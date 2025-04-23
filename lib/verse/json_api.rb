# frozen_string_literal: true

require "verse/core"
require "verse/http"

require_relative "json_api/version"

require_relative "json_api/renderer"
require_relative "json_api/deserializer"
require_relative "json_api/util"

require_relative "json_api/exposition_dsl"

require_relative "json_api/service"

Verse::Exposition::Base.extend(Verse::JsonApi::ExpositionDsl)
