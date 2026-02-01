# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class PersistenceFileStoreTest < Minitest::Test
  def test_file_store_roundtrip
    Dir.mktmpdir do |dir|
      store = Rubyrana::Persistence::FileStore.new(directory: dir)
      messages = [{ "role" => "user", "content" => "hi" }]

      store.save("session-1", messages)
      loaded = store.load("session-1")

      assert_equal messages, loaded
    end
  end
end
