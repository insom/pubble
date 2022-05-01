#!/usr/bin/ruby

require 'word_wrap'
require 'word_wrap/core_ext'

class Doc
  def initialize(filename)
    @filename = filename
    @file = File::open(@filename)
    @dateline = nil
  end

  def parse
    code_language = nil
    code_buffer = nil
    state = :normal
    pieces = []
    for line in @file.readlines do
      if state == :normal
        # Date Line
        if m = line.match(/^\d+-\d+-\d+/)
          @dateline = m[0]
          pieces << [:dateline, @dateline]
          next
        end
        # State of a Code Block
        if m = line.match(/^```([a-z]+)?/)
          code_language = m[1]
          code_buffer = []
          state = :code
          next
        end
        # Empty Line
        if line.match(/^[\s\n]*$/)
          next
        end
        # Date Line Sugar
        if line.match(/^-{10}$/)
          next
        end
        # URL
        if m = line.match(/^LINK ([^ ]*) ?(.*)/)
          pieces << [:url, m[1], m[2]]
          next
        end
        # Image
        if m = line.match(/^IMG ([^ ]*) ?(.*)/)
          pieces << [:image, m[1], m[2]&.strip]
          next
        end
        # Heading
        if m = line.match(/^## (.*)/)
          pieces << [:heading, m[1]&.strip]
          next
        end
        # Default Text
        pieces << [:paragraph, line.strip]
      elsif state == :code
        # End of a Code Block
        line.match(/^```/) do |m|
          code = code_buffer.join('')
          state = :normal
          pieces << [:code, code, code_language || 'text']
          next
        end
        # Inside a Code Block
        code_buffer << line
      end
    end
    pieces
  end

  def pieces
    @pieces ||= parse
  end
end

def indent(s, prefix="  ")
  s.split("\n").map { |x| prefix + x }.join("\n")
end

# dateline code url image heading

def gopherize(doc)
  doc.pieces.map do |piece|
    if piece[0] == :dateline
      next indent(piece[1].fit(60))
    end
    if piece[0] == :paragraph
      next indent(piece[1].fit(60))
    end
  end.join("\n")
end

p = Doc.new("input.insom")
p p.pieces
puts gopherize(p)

