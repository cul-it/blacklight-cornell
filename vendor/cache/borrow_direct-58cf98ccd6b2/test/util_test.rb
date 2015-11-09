require 'test_helper'

describe "BorrowDirect Util" do

  describe "#hash_key_path" do
    it "looks up one level" do
      hash = {:foo => 1}

      assert_equal 1, BorrowDirect::Util.hash_key_path(hash, :foo)
      assert_nil BorrowDirect::Util.hash_key_path(hash, :bar)
    end

    it "looks up multi-level" do
      hash = {
        :one => {
          :two => {
            :three => "value"
          }
        }
      }

      assert_equal "value", BorrowDirect::Util.hash_key_path(hash, :one, :two, :three)
      assert_nil BorrowDirect::Util.hash_key_path(hash, :notfound)
      assert_nil BorrowDirect::Util.hash_key_path(hash, :one, :two, :notfound)
      assert_nil BorrowDirect::Util.hash_key_path(hash, :one, :notfound, :notfound)
      assert_nil BorrowDirect::Util.hash_key_path(hash, :notfound, :two, :notfound)
      assert_nil BorrowDirect::Util.hash_key_path(hash, :notfound, :two, :notfound, :notfound)
    end

  end

end