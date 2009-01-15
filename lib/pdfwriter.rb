#!/usr/bin/ruby
#require 'fakeentries'
$font_times = [ 250.0, 333.0, 408.0, 500.0, 500.0, 833.0, 778.0, 333.0, 333.0, 333.0, 500.0, 564.0, 250.0, 333.0, 250.0, 278.0, 500.0, 500.0, 500.0, 500.0, 500.0, 500.0, 500.0, 500.0, 500.0, 500.0, 278.0, 278.0, 564.0, 564.0, 564.0, 444.0, 921.0, 722.0, 667.0, 667.0, 722.0, 611.0, 556.0, 722.0, 722.0, 333.0, 389.0, 722.0, 611.0, 889.0, 722.0, 722.0, 556.0, 722.0, 667.0, 556.0, 611.0, 722.0, 722.0, 944.0, 722.0, 722.0, 611.0, 333.0, 278.0, 333.0, 469.0, 500.0, 333.0, 444.0, 500.0, 444.0, 500.0, 444.0, 333.0, 500.0, 500.0, 278.0, 278.0, 500.0, 278.0, 778.0, 500.0, 500.0, 500.0, 500.0, 333.0, 389.0, 278.0, 500.0, 500.0, 722.0, 500.0, 500.0, 444.0, 480.0, 200.0, 480.0, 541.0, 0]

class PdfWriter
  def initialize(out = $stdout, title='', units = :mm)
    @title = title
    @pts = 1
    @pts = 2.83465 if units == :mm
    @pts = 1 if units == :points
    @pts = 72 if units == :inch
    @out = out
    @pagetree = 1
    @objnum = 2 
    @filepos = 0
    @pageobj = Array.new
    @objlist = Array.new
    @status = :notstarted
  end

  def writeStart
    raise 'Start already written' unless @status==:notstarted
    write "%PDF-1.3\n"
    writeResources
    @status = :started
  end

  def newPage
    writeStart if @status==:notstarted
    endPage if @status==:inpage
    raise 'Can\'t start page here' unless @status==:started
    startStream
    @status = :inpage
  end

  def endPage
    raise 'Can\'t end a page we are not in' unless @status==:inpage
    @status = :instream
    endStream
    writePage(@cur_stream)
  end
  
  def startStream
    raise 'Need to close previous stream' if @status==:instream
    raise 'Need to start first' unless @status==:started
    @status = :instream
    @cur_stream = writeDictionary([ ["/Length", "#{@objnum+1} 0 R"] ],
                                   nil, true)
    write "\nstream\n"
    @stream_start = @filepos
    return @cur_stream
  end

  def endStream
    raise 'Can\'t end stream - not in one' unless @status==:instream
    @status = :started
    stream_len = @filepos - @stream_start
    write "endstream\nendobj\n"
    @objlist << [@filepos, @objnum]
    write "#{@objnum} 0 obj\n#{stream_len}\nendobj\n"
    @objnum += 1
    return @cur_stream
  end

  def writePage(stream=@cur_stream, *streams)
    raise 'Can\'t write page while in stream' if @status!=:started
    streams = Array.new if streams==nil
    streams << stream
    str = atomorlist(streams)
    obj = writeDictionary [
      ["/Type", "/Page"],
      ["/Parent", "#{@pagetree} 0 R"],
      ["/Resources", "#{@pageresources} 0 R"],
      ["/Contents", str], 
      ["/MediaBox", "[0 0 595.27 841.89]"] ] #Fixme what should this be
    @pageobj << obj
  end

  def writeLine(x1, y1, x2, y2)
    raise 'Need to do newPage or startStream first'\
        unless @status==:instream || @status==:inpage
    write "#{x1*@pts} #{y1*@pts} m\n#{x2*@pts} #{y2*@pts} l\nS\n"
  end

  def writeText(x, y, text, options = Hash.new)
    raise 'Need to do newPage or startStream first'\
        unless @status==:instream || @status==:inpage
    font = options[:bold] ? 'F-tnrb' : 'F-tnr'
    fontsize=options[:fontsize] ? options[:fontsize] : 12
    text.gsub!(/\(/, '\\\\050')
    text.gsub!(/\)/, '\\\\051')
    write "BT\n/#{font} #{fontsize} Tf\n#{x*@pts} #{y*@pts} Td\n(#{text}) Tj\nET\n"
  end

  def writeTxtLine(y, items, options = Hash.new)
    raise 'Need to do newPage or startStream first'\
        unless @status==:instream || @status==:inpage
    fontsize=options[:fontsize] ? options[:fontsize] : 12
    items.each do |item|
      # Right justify
      x = item[1]
      x = x - textLength(item[0])* fontsize/(@pts*1000) if item.size==3 && item[2]
      writeText(x, y, item[0], options)
    end
  end
  
  def textLength(str)
    len = 0
    str.each_byte {|c| 
      l = $font_times[c-32]
      l = $font_times[77-32] if !l
      len += l
    }
    return len
  end

  def writeTxtBox(y, xl, xr, str)
    raise 'Need to do newPage or startStream first'\
        unless @status==:instream || @status==:inpage
    xspace = @pts*(xr-xl) / 10 * 1000
    lines = Array.new
    line = ""
    len = 0
    str.split.each do |word|
      word += " "
      wlen = textLength(word)
      if (len+wlen > xspace && (len!=0 || wlen < xspace)) then
        lines << line
        len = wlen
        line = word
      else
        len += wlen
        line += word
      end
    end
    lines << line
    lines.each do |line|
      writeText(xl, y, line)
      y-=5
    end
  end

  def writeEnd
    endPage if @status == :inpage
    raise 'Need to do close streams first' unless @status==:started
    writePages
    writeCatalog
    writeTrailer
    @status = :finished
  end

private

  def write(str)
    @filepos += str.size
    @out.write(str)
  end

  def writeResources
    font1 = writeDictionary [
      ["/Type", "/Font"],
      ["/Subtype", "/Type1"],
      ["/BaseFont", "/Helvetica"] ]
      
    font2 = writeDictionary [
      ["/Type", "/Font"],
      ["/Subtype", "/Type1"],
      ["/BaseFont", "/Helvetica"] ]
      
    @pageresources = writeDictionary [
      ["/Font", "<</F-tnr #{font1} 0 R /F-tnrb #{font2} 0 R>>"] ]
  end

  def writePages
    kids = atomorlist(@pageobj)
    writeDictionary([ ["/Type", "/Pages"],
                       ["/Count", @pageobj.size.to_s],
                       ["/Kids", kids] ], @pagetree)
  end

  def atomorlist(al)
    if al.size>1 then
      ret= "[ "
      al.each do |obj|
        ret += "#{obj} 0 R\n"
      end
      ret += "]"
    else
      ret = "[#{al[0]} 0 R]"
    end
    return ret
  end

  def writeCatalog
    @catalog = writeDictionary [ ["/Type", "/Catalog"],
                                  ["/Pages", "#{@pagetree} 0 R"] ]
    @info = writeDictionary [ ["/Creator", "(Ruby PDFWriter)"],
                               ["/Producer", "(pdfTex-0.13x)"],
                               ["/CreationDate", "(D:20041218104800)"],
                               ["/Title",  "(#{@title})"] ] 
  end

  def writeTrailer
    xrefpos = @filepos
    write "xref\n"
    write "0 #{1 + @objlist.size}\n"
    write "0000000000 65535 f \n"
    slist = @objlist.sort { |a,b| a[1]<=>b[1] }
    slist.each do |obj|
      write "#{"%010d" % obj[0]} 00000 n \n"
    end
    write "trailer\n<<\n"
    write "/Size #{1 + @objlist.size}\n"
    write "/Root #{@catalog} 0 R\n"
    write "/Info #{@info} 0 R>>\n"
    write "startxref\n#{xrefpos}\n%%EOF\n"
  end

  def writeDictionary(entries, objnum=nil, stream=nil)
    if !objnum then
      objnum = @objnum
      @objnum += 1
    end
    @objlist << [@filepos, objnum]
    write "#{objnum} 0 obj << \n"
    entries.each do |entry|
      write "#{entry[0]} #{entry[1]}\n"
    end
    write ">>"
    write " endobj\n" if !stream
    return objnum
  end
end

