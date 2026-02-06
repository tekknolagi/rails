# frozen_string_literal: true

require "abstract_unit"

module ActionDispatch
  module Journey
    module GTG
      class TestBuilder < ActiveSupport::TestCase
        def test_following_states_multi
          table = tt ["a|a"]
          states = GTG::StateQueue.new
          table.move(states, "a", "a", 0, true)
          assert_equal 1, states.count
        end

        def test_following_states_multi_regexp
          table = tt [":a|b"]
          states = GTG::StateQueue.new
          table.move(states, "fooo", "fooo", 0, true)
          assert_equal 1, states.count

          states = GTG::StateQueue.new
          table.move(states, "b", "b", 0, true)
          assert_equal 2, states.count
        end

        def test_multi_path
          table = tt ["/:a/d", "/b/c"]

          states = GTG::StateQueue.new

          [
            [1, "/"],
            [2, "b"],
            [2, "/"],
            [1, "c"],
          ].each { |(exp, sym)|
            table.move(states, sym, sym, 0, sym != "/")
            assert_equal exp, states.count
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
