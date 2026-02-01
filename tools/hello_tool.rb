# frozen_string_literal: true

Rubyrana.tool("hello", description: "Greet a user", schema: {
  type: "object",
  properties: {
    name: { type: "string" }
  },
  required: ["name"]
}) do |name:|
  "Hello, #{name}!"
end
