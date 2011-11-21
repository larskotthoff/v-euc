#!/usr/bin/env ruby

require 'json'
require 'date'

def cv(s)
    if s.empty? then
        nil
    else
        s.to_f
    end
end

def dsort(a, b)
    Date.strptime(a[0], "%d/%m/%Y") <=> Date.strptime(b[0], "%d/%m/%Y")
end

data = {}

defcsv = IO.readlines(ARGV[0])[5..-1]
deforder = ["Germany", "Spain", "France", "United Kingdom", "Greece", "Ireland", "Italy", "Portugal"]
defdates = ["01/07/2011", "01/04/2011", "01/01/2011",
            "01/10/2010", "01/07/2010", "01/04/2010", "01/01/2010",
            "01/10/2009", "01/07/2009", "01/04/2009", "01/01/2009",
            "01/10/2008", "01/07/2008", "01/04/2008", "01/01/2008",
            "01/10/2007", "01/07/2007", "01/04/2007", "01/01/2007"]
deficit = {}
deforder.each_with_index { |c,i|
    chash = {}
    defdates.each_with_index { |d,j|
        tmp = cv(defcsv[j].split(/,/)[i+1].gsub(/\"/, ""))
        chash[d] = tmp if tmp
    }
    deficit[c] = chash.sort { |a,b| dsort(a,b) }
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
    ratings[c] = chash.sort { |a,b| dsort(a,b) }
}
data["ratings"] = ratings

interestorder = ["Germany", "Spain", "France", "Greece", "Ireland", "Italy", "Portugal"]
interest = {}
interestcsv = IO.readlines(ARGV[2])[5..-1]
interestorder.each_with_index { |c,i|
    chash = {}
    interestcsv[0..57].each { |l|
        date = Date.strptime(l.split(/,/)[0].gsub(/\"/, ""), "%Y%b")
        tmp = cv(l.split(/,/)[i+1].gsub(/\"/, ""))
        chash[date.strftime("%d/%m/%Y")] = tmp if tmp
    }
    interest[c] = chash.sort { |a,b| dsort(a,b) }
}
interestcsv = IO.readlines(ARGV[3])[5..-1]
chash = {}
interestcsv[0..57].each { |l|
    date = Date.strptime(l.split(/,/)[0].gsub(/\"/, ""), "%Y%b")
    tmp = cv(l.split(/,/)[1].gsub(/\"/, ""))
    chash[date.strftime("%d/%m/%Y")] = tmp if tmp
}
interest["United Kingdom"] = chash.sort { |a,b| dsort(a,b) }
data["interest"] = interest

puts data.to_json
#puts JSON.pretty_generate(data)
