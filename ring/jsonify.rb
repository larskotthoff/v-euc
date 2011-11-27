#!/usr/bin/env ruby

require 'json'
require 'date'

eu12 = ["Austria", "Belgium", "Finland", "France", "Germany", "Greece", "Ireland", "Italy", "Luxembourg", "Netherlands", "Portugal", "Spain"]

firstdate = Date.strptime("01/04/2006", "%d/%m/%Y")

def med(vs)
    if vs.length.odd?
        (vs[vs.length/2] + vs[(vs.length/2)+1]).to_f/2
    else
        vs[vs.length/2]
    end
end

def interpolate(date, hash)
    ks = hash.keys.sort
    diffs = ks.collect { |d| date - d }
    idxs = []
    diffs.each_with_index { |d,i|
        if d == 0
            idxs = [i]
            break
        elsif d < 0
            idxs = [i-1, i]
            break
        end
    }
    if idxs.length == 0
        return nil
    elsif idxs.length == 1
        return hash[ks[idxs[0]]]
    else
        h = {}
        hash[ks[idxs[0]]].each { |c|
            vbefore = hash[ks[idxs[0]]][c]
            vafter = hash[ks[idxs[1]]][c]
            div = if diffs[idxs[0]].abs > diffs[idxs[1]].abs
                      1.5
                  else
                      3
                  end
            if vbefore.nil? or vafter.nil?
                return nil
            end
            h[c] = (vbefore + vafter)/div
        }
        return h
    end
end

def aggbyfield(field, lines)
    h = {}
    lines.each { |l|
        d = l.split(/,/)[field]
        if h.has_key?(d)
            h[d] << l
        else
            h[d] = [l]
        end
    }
    return h
end

def cv(s)
    if s.nil? or s.empty? then
        nil
    else
        sp = s.strip.gsub(/\"/, "")
        if sp.empty? or sp =~ /^:$/
            nil
        else
            sp.gsub(/\s+/, "").to_f
        end
    end
end

data = {}

debt = {}

debtcsv = IO.readlines("debt.csv")[1..-1]
debth = aggbyfield(0, debtcsv)
debth.each { |d,lines|
    datestr = (3 * d[-2..-2].to_i).to_s + "/" + d[1..4]
    date = Date.strptime(datestr, "%m/%Y")
    debt[date] = {} unless debt.has_key?(date)
    lines.each { |l|
        country = eu12.find { |c| l.split(/,/)[1] =~ Regexp.new(c) }
        debt[date][country] = cv(l.split(/,/)[5])
    }
}

deficit = {}
deficitcsv = IO.readlines("deficit.csv")[5..-1]

deforder = [0, 1, 4, 11, 2, 3, 5, 6, 7, 8, 9, 10]
deficitcsv.each { |l|
    d = l.split(/,/)[0]
    datestr = (3 * d[-1..-1].to_i).to_s + "/" + d[0..3]
    date = Date.strptime(datestr, "%m/%Y")
    if date >= firstdate
        deficit[date] = {} unless deficit.has_key?(date)
        deforder.each_with_index { |i,j|
            deficit[date][eu12[i]] = cv(l.split(/,/)[j+1])
        }
    end
}

gdpgrowth = {}

gdpgcsv = IO.readlines("gdp-change.csv")[1..-1]
gdpgh = aggbyfield(0, gdpgcsv)
gdpgh.each { |d,lines|
    datestr = (3 * d[-2..-2].to_i).to_s + "/" + d[1..4]
    date = Date.strptime(datestr, "%m/%Y")
    gdpgrowth[date] = {} unless gdpgrowth.has_key?(date)
    lines.each { |l|
        country = eu12.find { |c| l.split(/,/)[1] =~ Regexp.new(c) }
        gdpgrowth[date][country] = cv(l.split(/,/)[5])
    }
}

inflation = {}
inflationcsv = IO.readlines("inflation.csv")[5..-1]

iorder = [0, 1, 4, 11, 2, 3, 5, 6, 7, 8, 9, 10]
inflationcsv.each { |l|
    d = l.split(/,/)[0]
    datestr = d[4..-1] + "/" + d[0..3]
    date = Date.strptime(datestr, "%b/%Y")
    if date >= firstdate
        inflation[date] = {} unless inflation.has_key?(date)
        iorder.each_with_index { |i,j|
            inflation[date][eu12[i]] = cv(l.split(/,/)[j+1])
        }
    end
}

interest = {}
interestcsv = IO.readlines("interest.csv")[5..-1]

inorder = [0, 1, -1, 4, 11, 2, 3, 5, 6, 7, 8, -1, 9, 10, -1, -1]
interestcsv.each { |l|
    d = l.split(/,/)[0]
    datestr = d[4..-1] + "/" + d[0..3]
    date = Date.strptime(datestr, "%b/%Y")
    if date >= firstdate
        interest[date] = {} unless interest.has_key?(date)
        inorder.each_with_index { |i,j|
            interest[date][eu12[i]] = cv(l.split(/,/)[j+1]) unless i == -1
        }
    end
}

unemployment = {}
unemploymentcsv = IO.readlines("unemployment.csv")[5..-1]

uorder = [0, 1, 4, 11, 2, 3, 5, 6, 7, 8, 9, 10]
unemploymentcsv.each { |l|
    d = l.split(/,/)[0]
    datestr = d[4..-1] + "/" + d[0..3]
    date = Date.strptime(datestr, "%b/%Y")
    if date >= firstdate
        unemployment[date] = {} unless unemployment.has_key?(date)
        uorder.each_with_index { |i,j|
            unemployment[date][eu12[i]] = cv(l.split(/,/)[j+1])
        }
    end
}

investment = {}

investmentcsv = IO.readlines("gdp-investment-oecd.csv")[1..-1]
investmenth = aggbyfield(-3, investmentcsv)
investmenth.each { |d,lines|
    datestr = (3 * d[2..2].to_i).to_s + "/" + d[-5..-2]
    date = Date.strptime(datestr, "%m/%Y")
    investment[date] = {} unless investment.has_key?(date)
    gdp = {}
    inv = {}
    lines.each { |l|
        country = eu12.find { |c| l.split(/,/)[-4] =~ Regexp.new(c) }
        if l.split(/,/)[0] =~ /capital formation/
            inv[country] = cv(l.split(/,/)[-2])
        else
            gdp[country] = cv(l.split(/,/)[-2])
        end
    }
    eu12.each { |c|
        investment[date][c] = if inv[c].nil? or gdp[c].nil?
                                  nil
                              else
                                  (inv[c] / gdp[c]) * 100
                              end
    }
}

pdebt = {}

pdebtcsv = IO.readlines("external-debt.csv")[1..-1]
pddates = ["2006Q1", "2006Q2", "2006Q3", "2006Q4", "2007Q1", "2007Q2", "2007Q3", "2007Q4", "2008Q1", "2008Q2", "2008Q3", "2008Q4", "2009Q1", "2009Q2", "2009Q3", "2009Q4", "2010Q1", "2010Q2", "2010Q3", "2010Q4", "2011Q1", "2011Q2", "2011Q3", "2011Q4"]
pdebtcsv.each { |l|
    country = eu12.find { |c| l.split(/,/)[0] =~ Regexp.new(c) }
    pddates.each_with_index { |d,i|
        datestr = (3 * d[-1..-1].to_i).to_s + "/" + d[0..3]
        date = Date.strptime(datestr, "%m/%Y")
        pdebt[date] = {} unless pdebt.has_key?(date)
        pdebt[date][country] = cv(l.split(/,/)[i+4])
    }
}

gdpdollar = {}
gdpdollarcsv = IO.readlines("gdp-imf.csv")[1..-4]
gdates = ["2006", "2007", "2008", "2009", "2010", "2011"]
gdpdollarcsv.each { |l|
    splits = l.split(/\t/)
    if splits[1] =~ /Gross domestic product/
        country = eu12.find { |c| splits[0] =~ Regexp.new(c) }
        gdates.each_with_index { |d,i|
            date = Date.strptime(d, "%Y")
            gdpdollar[date] = {} unless gdpdollar.has_key?(date)
            gdpdollar[date][country] = cv(splits[i+4]) * 1000000000
        }
    end
}
pdebt.each { |d,cs|
    cs.each { |c,v|
        gdpdollardate = Date.strptime(d.year.to_s, "%Y")
        pdebt[d][c] = if v.nil? or gdpdollar[gdpdollardate][c].nil?
                          nil
                      else
                          (v / gdpdollar[gdpdollardate][c]) * 100
                      end
    }
}

#data["debt"] = debt
#data["deficit"] = deficit
#data["gdpgrowth"] = gdpgrowth
#data["inflation"] = inflation
#data["interest"] = interest
#data["unemployment"] = unemployment
#data["investment"] = investment
#data["privatedebt"] = pdebt

# normalise and predict

interest.keys.sort.each { |k|
    tmp = {}
    ihash = interpolate(k, debt)
    next if ihash.nil? or ihash.values.any? { |x| x.nil? }
    vs = ihash.values.sort
    tmp["debt"] = ihash
    tmp["debt"]["min"] = vs.min
    tmp["debt"]["max"] = vs.max
    tmp["debt"]["median"] = med(vs)

    ihash = interpolate(k, deficit)
    next if ihash.nil? or ihash.values.any? { |x| x.nil? }
    vs = ihash.values.sort
    tmp["deficit"] = ihash
    tmp["deficit"]["min"] = vs.min
    tmp["deficit"]["max"] = vs.max
    tmp["deficit"]["median"] = med(vs)

    ihash = interpolate(k, gdpgrowth)
    next if ihash.nil? or ihash.values.any? { |x| x.nil? }
    vs = ihash.values.sort
    tmp["gdpgrowth"] = ihash
    tmp["gdpgrowth"]["min"] = vs.min
    tmp["gdpgrowth"]["max"] = vs.max
    tmp["gdpgrowth"]["median"] = med(vs)

    vs = inflation[k].values.sort
    next if vs.any? { |x| x.nil? }
    tmp["inflation"] = inflation[k]
    tmp["inflation"]["min"] = vs.min
    tmp["inflation"]["max"] = vs.max
    tmp["inflation"]["median"] = med(vs)

    vs = interest[k].values.sort
    next if vs.any? { |x| x.nil? }
    tmp["interest"] = interest[k]
    tmp["interest"]["min"] = vs.min
    tmp["interest"]["max"] = vs.max
    tmp["interest"]["median"] = med(vs)

    vs = unemployment[k].values.sort
    next if vs.any? { |x| x.nil? }
    tmp["unemployment"] = unemployment[k]
    tmp["unemployment"]["min"] = vs.min
    tmp["unemployment"]["max"] = vs.max
    tmp["unemployment"]["median"] = med(vs)

    ihash = interpolate(k, investment)
    next if ihash.nil? or ihash.values.any? { |x| x.nil? }
    vs = ihash.values.sort
    tmp["investment"] = ihash
    tmp["investment"]["min"] = vs.min
    tmp["investment"]["max"] = vs.max
    tmp["investment"]["median"] = med(vs)

    ihash = interpolate(k, pdebt)
    next if ihash.nil? or ihash.values.any? { |x| x.nil? }
    vs = ihash.values.sort
    tmp["privatedebt"] = ihash
    tmp["privatedebt"]["min"] = vs.min
    tmp["privatedebt"]["max"] = vs.max
    tmp["privatedebt"]["median"] = med(vs)

    data[k] = tmp
}

jsondata = data.keys.sort.collect { |d|
    [d.year.to_s + "/" + d.month.to_s, data[d]]
}

puts jsondata.to_json
#puts JSON.pretty_generate(jsondata)
