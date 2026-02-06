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
          buf = Array.new(16)
          buf[0] = 0
          buf[1] = nil
          roff = 0
          rlen = 2

          pos = 0
          eos = string.bytesize

          while pos < eos
            start_index = pos
            pos += 1

            if (token = STATIC_TOKENS[string.getbyte(start_index)])
              wlen = tt.move(buf, roff, rlen, string, token, start_index, false)
            else
              while pos < eos && STATIC_TOKENS[string.getbyte(pos)].nil?
                pos += 1
              end

              token = string.byteslice(start_index, pos - start_index)
              wlen = tt.move(buf, roff, rlen, string, token, start_index, true)
            end

            # Advance read head to the written region
            roff += rlen
            rlen = wlen
          end

          acceptance_states = []
          rend = roff + rlen
          i = roff
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
