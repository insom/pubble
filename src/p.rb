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

  def dateline
    pieces
    @dateline
  end

  def <=>(other)
    other.dateline <=> dateline
  end
end

def indent(s, prefix="   ")
  s.split("\n").map { |x| prefix + x }.join("\n")
end

# dateline paragraph code url image heading

def gopherize(doc)
  res = doc.pieces.map do |piece|
    if piece[0] == :dateline
      next indent(piece[1].fit(60)) + "\n   ----------"
    end
    if piece[0] == :paragraph
      next indent(piece[1].fit(60))
    end
    if piece[0] == :code
      next indent(piece[1], '|   ')
    end
    if piece[0] == :url
      res = indent(piece[1], '=> ')
      res += "\n" + indent(piece[2].fit(60), ' > ') unless piece[2].nil?
      next res
    end
    if piece[0] == :image
      res = indent(piece[1], '=> ')
      res += "\n" + indent(piece[2].fit(60), ' > ') unless piece[2].nil?
      next res
    end
    if piece[0] == :heading
      next indent(piece[1].fit(60), '## ')
    end
  end.join("\n\n")
  return "\n" + res + "\n\n"
end

def geminize(doc)
  res = doc.pieces.map do |piece|
    if piece[0] == :dateline
      next indent(piece[1], '# ')
    end
    if piece[0] == :paragraph
      next piece[1]
    end
    if piece[0] == :code
      next "```#{ piece[2] }\n#{ piece[1] }```"
    end
    if piece[0] == :url
      res = indent(piece[1], '=> ')
      res += " " + piece[2]  unless piece[2].nil?
      next res
    end
    if piece[0] == :image
      res = indent(piece[1], '=> ')
      res += " " + piece[2]  unless piece[2].nil?
      next res
    end
    if piece[0] == :heading
      next indent(piece[1], '## ')
    end
  end.join("\n\n")
  return res
end

def gemini_index(ps)
  begin
    header = File::open("header.gmi").read
  rescue
    header = ""
  end
  header + ps.map(&:dateline).map do |dl|
    "=> #{ dl }.gmi #{ dl }"
  end.join("\n") + "\n"
end

def gopher_index(ps)
  begin
    header = File::open("header.gophermap").read
  rescue
    header = ""
  end
  header + ps.map(&:dateline).map do |dl|
    "0#{ dl }\t#{ dl }"
  end.join("\n") + "\n"
end

# main, kindof

projects = []

Dir::glob(File::expand_path("~/projects/*")) do |fn|
  projects << Doc.new(fn)
end

projects.sort!

projects.map do |p|
  File::open(File::expand_path("~/public_gemini/#{ p.dateline }.gmi"), "w").write(geminize(p))
end
File::open(File::expand_path("~/public_gemini/index.gmi"), "w").write(gemini_index(projects))

projects.map do |p|
  File::open(File::expand_path("~/public_gopher/#{ p.dateline }"), "w").write(gopherize(p))
end
File::open(File::expand_path("~/public_gopher/gophermap"), "w").write(gopher_index(projects))

File::open(File::expand_path("~/.project"), "w").write(gopherize(projects[0]))
