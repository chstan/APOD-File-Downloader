require 'open-uri'
require 'net/http'
require 'digest/sha1'
$precursor = "http://"
$base = 'apod.nasa.gov'
$mid = '/apod/'

def downloadSingleFile filename, title, http
  begin
    remoteImage = http.get("#{$mid}#{filename}")
    open("Pictures/#{title}", "wb") { |f| 
      f.write(remoteImage.body)
    }
    return true
  rescue
    return false
  end
end

def downloadFiles indexPath
  index = open(indexPath, 'r').readlines
  Net::HTTP.start("#{$base}") { |http|
    http.read_timeout = 1000
    index.each do |currentUrlUnsafe|
      currentUrl = currentUrlUnsafe.scan(/.*\.jpg/)[0]
      title = currentUrl.scan(/[^\/]*\.jpg/)
      if File.exists?("Pictures/#{title}")
        puts "Found file: Pictures/#{title}. Not downloading."
      else
        while(!File.exists?("Pictures/#{title}"))
          downloadSingleFile currentUrl, title, http
        end
        puts "Could not find file: Pictures/#{title}. Downloaded."
      end
    end
  }
end

def updateIndex filePath
  out = open(filePath, 'r+')
  apod = open('http://apod.nasa.gov/apod/archivepix.html', 'r')
  oldLines = out.readlines
  
  apod.read.scan(/ap[0-9]{6}.html/).each do |line|
    page = open("#{$precursor}#{$base}#{$mid}#{line}", 'r')
    page.read.scan(/href="image.*\.jpg/).each do |imgsource|
      imgsource.scan(/image.*\.jpg/).each do |img|
        title = img.scan(/[^\/]*\.jpg/)
        if oldLines.any? {|s| s.scan(img) }
          puts "Collected all new images"
          return
        end
        puts "Finding URI: #{img}"
        out.puts(img)
      end
    end
  end
end

updateIndex('imageIndex.txt')
downloadFiles('imageIndex.txt')