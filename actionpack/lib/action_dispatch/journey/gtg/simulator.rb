# frozen_string_literal: true

# :markup: markdown

module ActionDispatch
  module Journey # :nodoc:
    module GTG # :nodoc:
      class MatchData # :nodoc:
        attr_reader :memos

        def initialize(memos)
          @memos = memos
        end
      end

      # A flat array of (state, start) pairs with read and write heads.
      # Writing appends past the read region; {#advance} flips the
      # written region into the read region with no copying.
      # A flat array of (state, start) pairs with read and write heads.
      # Writing appends past the read region; {#advance} flips the
      # written region into the read region with no copying.
      class StateQueue # :nodoc:
        attr_reader :buf, :roff, :rlen

        def initialize
          @buf = Array.new(16)
          @buf[0] = 0
          @buf[1] = nil
          @roff = 0
          @rlen = 2
          @wpos = 2
        end

        def empty?
          @rlen == 0
        end

        def count
          @rlen / 2
        end

        def push(state, start)
          @buf[@wpos] = state
          @buf[@wpos + 1] = start
          @wpos += 2
        end

        def advance
          @roff += @rlen
          @rlen = @wpos - @roff
        end
      end

      class Simulator # :nodoc:
        STATIC_TOKENS = Array.new(64)
        STATIC_TOKENS[".".ord] = "."
        STATIC_TOKENS["/".ord] = "/"
        STATIC_TOKENS["?".ord] = "?"
        STATIC_TOKENS.freeze

        attr_reader :tt

        def initialize(transition_table)
          @tt = transition_table
        end

        def memos(string)
          states = StateQueue.new

          pos = 0
          eos = string.bytesize

          while pos < eos
            start_index = pos
            pos += 1

            if (token = STATIC_TOKENS[string.getbyte(start_index)])
              tt.move(states, string, token, start_index, false)
            else
              while pos < eos && STATIC_TOKENS[string.getbyte(pos)].nil?
                pos += 1
              end

              token = string.byteslice(start_index, pos - start_index)
              tt.move(states, string, token, start_index, true)
            end
          end

          acceptance_states = []
          buf = states.buf
          i = states.roff
          rend = i + states.rlen
          while i < rend
            if buf[i + 1].nil?
              s = buf[i]
              if tt.accepting?(s)
                acceptance_states.concat(tt.memo(s))
              end
            end
            i += 2
          end

          acceptance_states.empty? ? yield : acceptance_states
        end
      end
    end
  end
end
