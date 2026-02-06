# frozen_string_literal: true

require "abstract_unit"

module ActionDispatch
  module Journey
    module GTG
      class TestBuilder < ActiveSupport::TestCase
        def test_following_states_multi
          table = tt ["a|a"]
          buf = [0, nil]
          assert_equal 1, table.move(buf, 0, 2, "a", "a", 0, true) / 2
        end

        def test_following_states_multi_regexp
          table = tt [":a|b"]
          buf = [0, nil]
          assert_equal 1, table.move(buf, 0, 2, "fooo", "fooo", 0, true) / 2

          buf = [0, nil]
          assert_equal 2, table.move(buf, 0, 2, "b", "b", 0, true) / 2
        end

        def test_multi_path
          table = tt ["/:a/d", "/b/c"]

          buf = Array.new(32)
          buf[0] = 0
          buf[1] = nil
          roff = 0
          rlen = 2

          [
            [1, "/"],
            [2, "b"],
            [2, "/"],
            [1, "c"],
          ].each { |(exp, sym)|
            wlen = table.move(buf, roff, rlen, sym, sym, 0, sym != "/")
            assert_equal exp, wlen / 2
            roff += rlen
            rlen = wlen
          }
        end

        def test_match_data_ambiguous
          table = tt %w{
            /articles(.:format)
            /articles/new(.:format)
            /articles/:id/edit(.:format)
            /articles/:id(.:format)
          }

          sim = Simulator.new table

          memos = sim.memos "/articles/new"
          assert_equal 2, memos.length
        end

        ##
        # Identical Routes may have different restrictions.
        def test_match_same_paths
          table = tt %w{
            /articles/new(.:format)
            /articles/new(.:format)
          }

          sim = Simulator.new table

          memos = sim.memos "/articles/new"
          assert_equal 2, memos.length
        end

        def test_catchall
          table = tt %w{
            /
            /*unmatched_route
          }

          sim = Simulator.new table

          # matches just the /*unmatched_route
          memos = sim.memos "/test"
          assert_equal 1, memos.length

          # matches just the /
          memos = sim.memos "/"
          assert_equal 1, memos.length
        end

        private
          def ast(strings)
            parser = Journey::Parser.new
            asts   = strings.map { |string|
              memo = Object.new
              ast  = parser.parse string
              ast.each { |n| n.memo = memo }
              ast
            }
            Nodes::Or.new asts
          end

          def tt(strings)
            Builder.new(ast(strings)).transition_table
          end
      end
    end
  end
end
