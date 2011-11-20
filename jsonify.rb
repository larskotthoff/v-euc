#!/usr/bin/env ruby

require 'json'
require 'date'

def cv(s)
    if s.empty? then
        "NA"
    else
        s.to_f
    end
end

data = {}

defcsv = IO.readlines(ARGV[0])[5..-1]
deforder = ["Germany", "Spain", "France", "United Kingdom", "Greece", "Ireland", "Italy", "Portugal"]
defdates = ["01/04/2011", "01/01/2011",
            "01/10/2010", "01/07/2010", "01/04/2010", "01/01/2010",
            "01/10/2009", "01/07/2009", "01/04/2009", "01/01/2009",
            "01/10/2008", "01/07/2008", "01/04/2008", "01/01/2008",
            "01/10/2007", "01/07/2007", "01/04/2007", "01/01/2007"]
deficit = {}
deforder.each_with_index { |c,i|
    chash = {}
    defdates.each_with_index { |d,j|
        chash[d] = cv(defcsv[j].split(/,/)[i+1].gsub(/\"/, ""))
    }
    deficit[c] = chash
}
data["deficit"] = deficit

ratcsv = IO.readlines(ARGV[1])[4..-1]
ratings = {}
deforder.each { |c|
    chash = {}
    cdata = ratcsv.find_all { |d| d.split(/,/)[0].gsub(/\"/, "") == c }.sort { |a,b|
            Date.strptime(a.split(/,/)[1], "%d %b %Y") <=>
            Date.strptime(b.split(/,/)[1], "%d %b %Y")
        }
    item = cdata.find { |d| d.split(/,/)[1].split(/ /)[2].to_i >= 2007 }
    idx = if item.nil? then
                cdata.length
            else
                cdata.index(item)
            end
    cdata[(idx-1)..-1].each { |l|
        date = Date.strptime(l.split(/,/)[1], "%d %b %Y")
        chash[date.strftime("%d/%m/%Y")] = l.split(/,/)[2].gsub(/\"/, "")
    }
    ratings[c] = chash
}
data["ratings"] = ratings

interestorder = ["Germany", "Spain", "France", "Greece", "Ireland", "Italy", "Portugal"]
interest = {}
interestcsv = IO.readlines(ARGV[2])[5..-1]
interestorder.each_with_index { |c,i|
    chash = {}
    interestcsv[0..57].each { |l|
        date = Date.strptime(l.split(/,/)[0].gsub(/\"/, ""), "%Y%b")
        chash[date.strftime("%d/%m/%Y")] = cv(l.split(/,/)[i+1].gsub(/\"/, ""))
    }
    interest[c] = chash
}
interestcsv = IO.readlines(ARGV[3])[5..-1]
chash = {}
interestcsv[0..57].each { |l|
    date = Date.strptime(l.split(/,/)[0].gsub(/\"/, ""), "%Y%b")
    chash[date.strftime("%d/%m/%Y")] = cv(l.split(/,/)[1].gsub(/\"/, ""))
}
interest["United Kingdom"] = chash
data["interest"] = interest

puts data.to_json
#puts JSON.pretty_generate(data)
