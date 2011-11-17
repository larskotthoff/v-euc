#!/usr/bin/env ruby

require 'json'

years = (2001..2010).to_a
countries = ["Germany", "Ireland", "Greece", "Spain", "France", "Portugal", "United Kingdom", "Italy"]

a = IO.readlines(ARGV[0])[1..-1]
dd = IO.readlines(ARGV[1])[1..-1]

data = {}

def cv(v)
    if v == ":" then
        return -1
    else
        return v.to_f
    end
end

years.each { |y|
    ay = a.find_all { |ad| ad.split(/,/)[0][1..-2].to_i == y }
    ddy = dd.find_all { |ddd| ddd.split(/,/)[0][1..-2].to_i == y }
    h = {}
    countries.each { |c|
        ayc = ay.find_all { |ayd| ayd.split(/,/)[1][1..-2] =~ Regexp.new(c) }
        ddyc = ddy.find_all { |ddyd| ddyd.split(/,/)[1][1..-2] =~ Regexp.new(c) }

        #aycd = cv(ayc.find { |d| d.split(/,/)[4][1..-2] =~ /Net lending/ }.split(/,/)[-2][1..-2])
        #ddycd = cv(ddyc.find { |d| d.split(/,/)[4][1..-2] =~ /Net lending/ }.split(/,/)[-2][1..-2])
        #if aycd != ddycd
        #    puts y.to_s + " " + c + " " + aycd.to_s + " " + ddycd.to_s
        #end

        hh = {}
        hh["interest"] = cv(ayc.find { |d| d.split(/\",\"/)[4] =~ /Interest/ }.split(/\",\"/)[-2])
        hh["deficit"] = cv(ayc.find { |d| d.split(/,/)[4][1..-2] =~ /Net lending/ }.split(/,/)[-2][1..-2])
        hh["debt"] = cv(ddyc.find { |d| d.split(/,/)[4][1..-2] =~ /^Government consolidated gross debt$/ }.split(/,/)[-2][1..-2])
        hh["shorts"] = cv(ddyc.find { |d| d.split(/,/)[4][1..-2] =~ /Short term securities/ }.split(/,/)[-2][1..-2])
        hh["longs"] = cv(ddyc.find { |d| d.split(/,/)[4][1..-2] =~ /Long-term securities/ }.split(/,/)[-2][1..-2])
        hh["shortl"] = cv(ddyc.find { |d| d.split(/,/)[4][1..-2] =~ /Short-term loans/ }.split(/,/)[-2][1..-2])
        hh["longl"] = cv(ddyc.find { |d| d.split(/,/)[4][1..-2] =~ / Long-term loans/ }.split(/,/)[-2][1..-2])
        h[c] = hh
    }
    data[y] = h
}

#puts data.to_json
#puts JSON.pretty_generate(data)

first = true
data.each { |y,v|
    v.each { |c,vv|
        if first
            puts (["year", "country"] + vv.collect { |n,vvv| n }).join(",")
            first = false
        end
        puts ([y.to_s, c] + vv.collect { |n,vvv| vvv.to_s }).join(",")
    }
}
